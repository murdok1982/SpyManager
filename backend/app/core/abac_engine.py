"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from abc import ABC, abstractmethod
from enum import IntEnum
from pydantic import BaseModel
from typing import List
import structlog

from app.core.exceptions import ABACDeniedError

logger = structlog.get_logger(__name__)


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


class Policy(ABC):
    """Interfaz base para todas las politicas ABAC."""

    @abstractmethod
    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        ...


class ActiveUserPolicy(Policy):
    """El usuario debe estar activo."""

    name = "active_user"

    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        return user.is_active


class ClassificationPolicy(Policy):
    """El nivel de clasificacion del usuario debe ser >= al del recurso."""

    name = "classification"

    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        return user.classification_level >= resource.classification_level


class CaseAssignmentPolicy(Policy):
    """El usuario debe estar asignado al caso (salvo DIRECTOR/ADMIN)."""

    name = "case_assignment"

    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        if user.role in ("DIRECTOR", "ADMIN"):
            return True
        return resource.case_id in user.assigned_cases


class DeletePolicy(Policy):
    """Solo el propietario o un ADMIN puede eliminar."""

    name = "delete"

    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        if action != "delete":
            return True  # politica no aplica
        return user.user_id == resource.owner_id or user.role == "ADMIN"


class ExportPolicy(Policy):
    """Solo clasificacion >= SECRET puede exportar."""

    name = "export"

    def evaluate(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> bool:
        if action != "export":
            return True  # politica no aplica
        return user.classification_level >= ClassificationLevel.SECRET


class AccessContext:
    """Contexto de acceso para evaluacion ABAC (compatibilidad con tests)."""

    def __init__(self, user, resource, action: str) -> None:
        self.user = user
        self.resource = resource
        self.action = action


class ABACEngine:
    """
    Motor de Control de Acceso basado en Atributos (ABAC).
    Implementa el principio de "necesidad de saber" y compartimentacion estricta
    mediante una cadena de politicas evaluables individualmente.
    """

    def __init__(self, policies: List[Policy] | None = None) -> None:
        if policies is None:
            self._policies: List[Policy] = [
                ActiveUserPolicy(),
                ClassificationPolicy(),
                CaseAssignmentPolicy(),
                DeletePolicy(),
                ExportPolicy(),
            ]
        else:
            self._policies = policies

    def evaluate(
        self,
        user_or_ctx,
        resource=None,
        action: str = "",
    ) -> bool:
        """Evalua todas las politicas. Retorna True solo si todas aprueban."""
        # Support AccessContext for test compatibility
        if isinstance(user_or_ctx, AccessContext):
            ctx = user_or_ctx
            user = ctx.user
            resource = ctx.resource
            action = ctx.action
        else:
            user = user_or_ctx

        for policy in self._policies:
            if not policy.evaluate(user, resource, action):
                logger.warning(
                    "abac_denied",
                    policy=policy.name,
                    user_id=getattr(user, "user_id", str(user)),
                    resource_id=getattr(resource, "resource_id", str(resource)),
                    action=action,
                )
                return False
        return True

    def enforce(
        self,
        user: UserAttributes,
        resource: ResourceAttributes,
        action: str,
    ) -> None:
        """Como evaluate() pero lanza ABACDeniedError en lugar de retornar False."""
        if not self.evaluate(user, resource, action):
            raise ABACDeniedError(user.user_id, resource.resource_id, action)
