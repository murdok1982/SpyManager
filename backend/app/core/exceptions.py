"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""


class IMCError(Exception):
    """Excepcion base para todos los errores del IMC."""

    def __init__(self, message: str, code: str = "IMC_ERROR") -> None:
        self.message = message
        self.code = code
        super().__init__(message)


class SecurityError(IMCError):
    def __init__(self, msg: str) -> None:
        super().__init__(msg, "SECURITY_VIOLATION")


class PKIError(IMCError):
    def __init__(self, msg: str) -> None:
        super().__init__(msg, "PKI_ERROR")


class EncryptionError(IMCError):
    def __init__(self, msg: str) -> None:
        super().__init__(msg, "ENCRYPTION_ERROR")


class ABACDeniedError(IMCError):
    def __init__(self, user_id: str, resource: str, action: str) -> None:
        super().__init__(
            f"Access denied: {user_id}->{action}:{resource}",
            "ABAC_DENIED",
        )
        self.user_id = user_id
        self.resource = resource
        self.action = action


class AuditIntegrityError(IMCError):
    def __init__(self, entry_id: str) -> None:
        super().__init__(
            f"Audit chain broken at entry {entry_id}",
            "AUDIT_INTEGRITY",
        )
        self.entry_id = entry_id


class DatabaseError(IMCError):
    def __init__(self, msg: str) -> None:
        super().__init__(msg, "DB_ERROR")


class EntityNotFoundError(IMCError):
    def __init__(self, entity_type: str, entity_id: str) -> None:
        super().__init__(
            f"{entity_type} not found: {entity_id}",
            "NOT_FOUND",
        )


class RateLimitError(IMCError):
    def __init__(self, msg: str = "Rate limit exceeded") -> None:
        super().__init__(msg, "RATE_LIMIT")


class ValidationError(IMCError):
    def __init__(self, msg: str) -> None:
        super().__init__(msg, "VALIDATION_ERROR")
