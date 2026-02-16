"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from enum import IntEnum
from pydantic import BaseModel
from typing import List, Optional

class ClassificationLevel(IntEnum):
    UNCLASSIFIED = 0
    RESTRICTED = 1
    CONFIDENTIAL = 2
    SECRET = 3
    TOP_SECRET = 4

class UserAttributes(BaseModel):
    user_id: str
    role: str
    classification_level: ClassificationLevel
    assigned_cases: List[str]
    is_active: bool = True

class ResourceAttributes(BaseModel):
    resource_id: str
    case_id: str
    classification_level: ClassificationLevel
    owner_id: str

class ABACEngine:
    """
    Motor de Control de Acceso basado en Atributos (ABAC).
    Implementa el principio de "necesidad de saber" y compartimentación estricta.
    """
    
    @staticmethod
    def evaluate(user: UserAttributes, resource: ResourceAttributes, action: str) -> bool:
        # 1. Verificar si el usuario está activo
        if not user.is_active:
            return False

        # 2. Regla de Oro: Clasificación
        # El usuario debe tener un nivel igual o superior al recurso
        if user.classification_level < resource.classification_level:
            return False

        # 3. Compartimentación (Necesidad de Saber)
        # El usuario debe estar asignado al caso del recurso
        # Excepción: Roles de supervisión global (ej. 'DIRECTOR', 'AUDITOR')
        if resource.case_id not in user.assigned_cases and user.role not in ["DIRECTOR", "ADMIN"]:
            return False

        # 4. Reglas específicas por acción
        if action == "delete":
            # Solo el dueño o un Administrador puede borrar
            return user.user_id == resource.owner_id or user.role == "ADMIN"

        if action == "export":
            # Solo niveles altos pueden exportar inteligencia
            return user.classification_level >= ClassificationLevel.SECRET

        return True
