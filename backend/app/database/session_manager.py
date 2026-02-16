"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from app.database.models import IntelPackage
from app.core.abac_engine import UserAttributes

class CaseScopedSession:
    """
    Wrapper de sesión que asegura que todas las consultas de inteligencia
    estén restringidas al compartimento autorizado del usuario.
    """
    
    def __init__(self, db: AsyncSession, user: UserAttributes):
        self.db = db
        self.user = user

    async def get_intel_by_case(self, case_id: str):
        """
        Consulta paquetes de inteligencia asegurando que el caso esté
        dentro de los permitidos para el usuario (Compartimentación).
        """
        # Verificación redundante de seguridad (mecanismo de defensa en profundidad)
        if case_id not in self.user.assigned_cases and self.user.role not in ["DIRECTOR", "ADMIN"]:
            return []

        stmt = select(IntelPackage).where(IntelPackage.case_id == case_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def secure_add(self, instance):
        """Añade un objeto verificando que su case_id sea válido para el usuario."""
        if hasattr(instance, "case_id"):
            if instance.case_id not in self.user.assigned_cases and self.user.role not in ["DIRECTOR", "ADMIN"]:
                raise PermissionError(f"Violación de compartimento: El usuario no tiene acceso al caso {instance.case_id}")
        
        self.db.add(instance)
        await self.db.commit()
