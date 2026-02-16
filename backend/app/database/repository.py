"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.database.models import IntelPackage, AccessLog
from app.core.abac_engine import ABACEngine, UserAttributes, ResourceAttributes
from app.services.encryption_service import EncryptionService
from app.services.audit_service import AuditService
from typing import List, Optional

class IntelRepository:
    """
    Repositorio Seguro para IntelPackages.
    Encapsula la lógica de ABAC, Cifrado y Auditoría.
    """
    
    def __init__(self, db: AsyncSession, encryption: EncryptionService, audit: AuditService):
        self.db = db
        self.encryption = encryption
        self.audit = audit

    async def _get_last_audit_hash(self) -> str:
        """Obtiene el último hash de la cadena de auditoría desde la DB."""
        stmt = select(AccessLog.integrity_hash).order_by(AccessLog.id.desc()).limit(1)
        result = await self.db.execute(stmt)
        last_hash = result.scalars().first()
        return last_hash or ("0" * 64)

    async def create_package(self, user: UserAttributes, package_data: dict) -> Optional[IntelPackage]:
        # 1. Preparar atributos del recurso para evaluación
        resource_attr = ResourceAttributes(
            resource_id="NEW",
            case_id=package_data["case_id"],
            classification_level=package_data["classification_level"],
            owner_id=user.user_id
        )

        # 2. Evaluar política ABAC
        if not ABACEngine.evaluate(user, resource_attr, "create"):
            raise PermissionError("Operación no autorizada por política ABAC")

        # 3. Cifrar contenido sensible
        encrypted_content = self.encryption.encrypt(
            package_data["content"], 
            associated_data=package_data["case_id"]
        )

        # 4. Obtener último hash y crear registro de auditoría
        last_hash = await self._get_last_audit_hash()
        audit_result = self.audit.create_entry(
            user.user_id, "CREATE_INTEL", "NEW", "INTEL_INGESTION", "AUTH_DEVICE", last_hash
        )

        # 5. Guardar en base de datos
        new_package = IntelPackage(
            id=package_data["id"],
            case_id=package_data["case_id"],
            classification_level=package_data["classification_level"],
            source_profile_id=package_data["source_profile_id"],
            confidence_score=package_data["confidence_score"],
            content_encrypted=encrypted_content,
            created_by=user.user_id,
            access_log_reference=audit_result["integrity_hash"]
        )
        
        self.db.add(new_package)
        
        # Guardar log de acceso (Parte de la cadena inmutable)
        access_log = AccessLog(
            user_id=user.user_id,
            action="CREATE_INTEL",
            resource_id=package_data["id"],
            reason_code="INTEL_INGESTION",
            device_id="AUTH_DEVICE",
            integrity_hash=audit_result["integrity_hash"],
            previous_hash=last_hash
        )
        self.db.add(access_log)
        
        await self.db.commit()
        return new_package

    async def get_package(self, user: UserAttributes, package_id: str) -> Optional[dict]:
        stmt = select(IntelPackage).where(IntelPackage.id == package_id)
        result = await self.db.execute(stmt)
        package = result.scalars().first()
        
        if not package:
            return None

        # Evaluar ABAC para lectura
        resource_attr = ResourceAttributes(
            resource_id=package.id,
            case_id=package.case_id,
            classification_level=package.classification_level,
            owner_id=package.created_by
        )

        last_hash = await self._get_last_audit_hash()

        if not ABACEngine.evaluate(user, resource_attr, "read"):
            # Registrar intento fallido en la cadena
            audit_result = self.audit.create_entry(
                user.user_id, "UNAUTHORIZED_READ", package_id, "ABAC_FAILURE", "UNKNOWN", last_hash
            )
            access_log = AccessLog(
                user_id=user.user_id,
                action="UNAUTHORIZED_READ",
                resource_id=package_id,
                reason_code="ABAC_FAILURE",
                device_id="UNKNOWN",
                integrity_hash=audit_result["integrity_hash"],
                previous_hash=last_hash
            )
            self.db.add(access_log)
            await self.db.commit()
            raise PermissionError("Acceso denegado: Nivel de clasificación insuficiente o fuera de compartimento")

        # Descifrar contenido
        decrypted_content = self.encryption.decrypt(
            package.content_encrypted, 
            associated_data=package.case_id
        )

        # Registrar acceso exitoso en la cadena
        audit_result = self.audit.create_entry(
            user.user_id, "READ_INTEL", package_id, "ANALYSIS", "AUTH_DEVICE", last_hash
        )
        access_log = AccessLog(
            user_id=user.user_id,
            action="READ_INTEL",
            resource_id=package_id,
            reason_code="ANALYSIS",
            device_id="AUTH_DEVICE",
            integrity_hash=audit_result["integrity_hash"],
            previous_hash=last_hash
        )
        self.db.add(access_log)
        await self.db.commit()

        return {
            "id": package.id,
            "content": decrypted_content,
            "classification": package.classification_level,
            "case_id": package.case_id
        }
