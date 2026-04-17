"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import datetime
import hashlib
import json
from typing import List

from pydantic import BaseModel


class AuditEntry(BaseModel):
    user_id: str
    action: str
    resource_id: str
    timestamp: str
    reason_code: str
    device_id: str
    previous_hash: str

    def compute_hash(self) -> str:
        """Serializa canonicamente y computa SHA-256."""
        dumped = self.model_dump(mode="json")
        canonical = json.dumps(dumped, sort_keys=True, separators=(",", ":")).encode("utf-8")
        return hashlib.sha256(canonical).hexdigest()


class AuditService:
    """
    Servicio de Auditoria Inmutable.
    Cada entrada esta encadenada a la anterior mediante SHA-256.
    Los timestamps son siempre UTC con timezone explicita.
    El SELECT FOR UPDATE que garantiza atomicidad se gestiona en el repositorio
    que llama a create_entry dentro de una transaccion de DB.
    """

    def create_entry(
        self,
        user_id: str,
        action: str,
        resource_id: str,
        reason_code: str,
        device_id: str,
        previous_hash: str,
    ) -> dict:
        """
        Crea una nueva entrada de auditoria encadenada.
        previous_hash debe ser obtenido con SELECT FOR UPDATE antes de llamar
        a este metodo para evitar race conditions en entornos multi-worker.
        """
        entry = AuditEntry(
            user_id=user_id,
            action=action,
            resource_id=resource_id,
            # Timestamp UTC con timezone explicita (no naive datetime)
            timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            reason_code=reason_code,
            device_id=device_id,
            previous_hash=previous_hash,
        )
        entry_hash = entry.compute_hash()
        return {
            "entry": entry.model_dump(),
            "integrity_hash": entry_hash,
        }

    @staticmethod
    def verify_chain(entries: List[dict]) -> bool:
        """
        Verifica la integridad de una lista ordenada de entradas de auditoria.
        Retorna False si cualquier enlace esta roto o el hash no coincide.
        """
        current_hash = "0" * 64
        for data in entries:
            entry = AuditEntry(**data["entry"])
            if entry.previous_hash != current_hash:
                return False
            computed = entry.compute_hash()
            if computed != data["integrity_hash"]:
                return False
            current_hash = data["integrity_hash"]
        return True

    async def get_last_hash(self, db) -> str:
        """
        Obtiene el ultimo hash de la cadena desde la DB usando SELECT FOR UPDATE.
        Debe llamarse dentro de una transaccion activa.
        """
        from sqlalchemy import select
        from app.database.models import AccessLog

        stmt = (
            select(AccessLog.integrity_hash)
            .with_for_update()
            .order_by(AccessLog.id.desc())
            .limit(1)
        )
        result = await db.execute(stmt)
        last_hash = result.scalars().first()
        return last_hash or ("0" * 64)
