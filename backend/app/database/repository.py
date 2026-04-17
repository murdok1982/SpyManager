"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from typing import Optional

import structlog
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.abac_engine import ABACEngine, ResourceAttributes, UserAttributes
from app.core.exceptions import ABACDeniedError
from app.database.models import AccessLog, IntelPackage
from app.services.audit_service import AuditService
from app.services.encryption_service import EncryptionService

logger = structlog.get_logger(__name__)


class IntelRepository:
    """
    Repositorio Seguro para IntelPackages.
    Encapsula la logica de ABAC, Cifrado y Auditoria.
    """

    def __init__(
        self,
        db: AsyncSession,
        encryption: EncryptionService,
        audit: AuditService,
        abac: Optional[ABACEngine] = None,
    ) -> None:
        self.db = db
        self.encryption = encryption
        self.audit = audit
        self.abac = abac or ABACEngine()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    async def _get_last_audit_hash(self) -> str:
        """Obtiene el ultimo hash de la cadena de auditoria con SELECT FOR UPDATE."""
        stmt = (
            select(AccessLog.integrity_hash)
            .with_for_update()
            .order_by(AccessLog.id.desc())
            .limit(1)
        )
        result = await self.db.execute(stmt)
        last_hash = result.scalars().first()
        return last_hash or ("0" * 64)

    async def _append_audit_log(
        self,
        user_id: str,
        action: str,
        resource_id: str,
        reason_code: str,
        device_id: str,
    ) -> str:
        """Crea entrada de auditoria y persiste en DB. Retorna integrity_hash."""
        last_hash = await self._get_last_audit_hash()
        audit_result = self.audit.create_entry(
            user_id=user_id,
            action=action,
            resource_id=resource_id,
            reason_code=reason_code,
            device_id=device_id,
            previous_hash=last_hash,
        )
        access_log = AccessLog(
            user_id=user_id,
            action=action,
            resource_id=resource_id,
            reason_code=reason_code,
            device_id=device_id,
            integrity_hash=audit_result["integrity_hash"],
            previous_hash=last_hash,
        )
        self.db.add(access_log)
        return audit_result["integrity_hash"]

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def create_package(
        self, user: UserAttributes, package_data: dict
    ) -> IntelPackage:
        resource_attr = ResourceAttributes(
            resource_id="NEW",
            case_id=package_data["case_id"],
            classification_level=package_data["classification_level"],
            owner_id=user.user_id,
        )

        # ABAC enforcement — lanza ABACDeniedError si deniega
        self.abac.enforce(user, resource_attr, "create")

        encrypted_content = self.encryption.encrypt(
            package_data["content"],
            purpose="intel",
            associated_data=package_data["case_id"],
        )

        audit_hash = await self._append_audit_log(
            user_id=user.user_id,
            action="CREATE_INTEL",
            resource_id=package_data.get("id", "NEW"),
            reason_code="INTEL_INGESTION",
            device_id="AUTH_DEVICE",
        )

        new_package = IntelPackage(
            id=package_data["id"],
            case_id=package_data["case_id"],
            classification_level=package_data["classification_level"],
            source_profile_id=package_data["source_profile_id"],
            confidence_score=package_data["confidence_score"],
            content_encrypted=encrypted_content,
            created_by=user.user_id,
            access_log_reference=audit_hash,
        )
        self.db.add(new_package)
        # commit lo hace get_db() al salir del context manager
        return new_package

    async def get_package(
        self, user: UserAttributes, package_id: str
    ) -> Optional[dict]:
        # TOCTOU fix: filtrar directamente en la query con ownership check
        stmt = (
            select(IntelPackage)
            .where(IntelPackage.id == package_id)
            .where(
                or_(
                    IntelPackage.case_id.in_(user.assigned_cases),
                    user.role.in_(["DIRECTOR", "ADMIN"]),
                )
            )
        )
        result = await self.db.execute(stmt)
        package = result.scalars().first()

        if not package:
            # Registrar intento de acceso a recurso no autorizado o inexistente
            await self._append_audit_log(
                user_id=user.user_id,
                action="UNAUTHORIZED_READ",
                resource_id=package_id,
                reason_code="ABAC_FAILURE_OR_NOT_FOUND",
                device_id="UNKNOWN",
            )
            return None

        resource_attr = ResourceAttributes(
            resource_id=package.id,
            case_id=package.case_id,
            classification_level=package.classification_level,
            owner_id=package.created_by,
        )

        if not self.abac.evaluate(user, resource_attr, "read"):
            await self._append_audit_log(
                user_id=user.user_id,
                action="UNAUTHORIZED_READ",
                resource_id=package_id,
                reason_code="ABAC_CLASSIFICATION_DENIED",
                device_id="UNKNOWN",
            )
            raise ABACDeniedError(user.user_id, package_id, "read")

        decrypted_content = self.encryption.decrypt(
            package.content_encrypted,
            purpose="intel",
            associated_data=package.case_id,
        )

        await self._append_audit_log(
            user_id=user.user_id,
            action="READ_INTEL",
            resource_id=package_id,
            reason_code="ANALYSIS",
            device_id="AUTH_DEVICE",
        )

        return {
            "id": package.id,
            "content": decrypted_content,
            "classification": package.classification_level,
            "case_id": package.case_id,
        }
