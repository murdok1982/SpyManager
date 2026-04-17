"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import json

import structlog

from app.core.exceptions import ValidationError
from app.services.encryption_service import EncryptionService

logger = structlog.get_logger(__name__)

_DECOY_TYPES = {"WEATHER_SYNC", "TELEMETRY_PING", "GENERIC"}


class ClandestineRepeater:
    """
    Servicio de Repetidor Clandestino.
    Permite el envio de informacion camuflada en trafico aparentemente banal
    y la retransmision de senales entre dispositivos autorizados.
    """

    def __init__(self, encryption: EncryptionService) -> None:
        self.encryption = encryption

    def obfuscate_event(
        self, event_data: dict, decoy_type: str = "WEATHER_SYNC"
    ) -> dict:
        """Camufla un evento real dentro de un paquete de senuelo."""
        if decoy_type not in _DECOY_TYPES:
            raise ValidationError(
                f"decoy_type debe ser uno de: {', '.join(sorted(_DECOY_TYPES))}"
            )

        try:
            event_str = json.dumps(event_data, separators=(",", ":"))
        except (TypeError, ValueError) as exc:
            raise ValidationError(f"event_data no es serializable: {exc}") from exc

        encrypted_payload = self.encryption.encrypt(
            event_str, purpose="clandestine", associated_data="CLANDESTINE"
        )

        if decoy_type == "WEATHER_SYNC":
            return {
                "t": 24.5,
                "h": 60,
                "p": 1013,
                "ext_data": encrypted_payload,
            }
        if decoy_type == "TELEMETRY_PING":
            return {
                "seq": 1,
                "rssi": -72,
                "bat": 87,
                "ext_data": encrypted_payload,
            }
        return {"data": encrypted_payload}

    def deobfuscate_event(self, obfuscated_data: dict) -> dict:
        """Extrae el evento real del paquete de senuelo."""
        if not isinstance(obfuscated_data, dict):
            raise ValidationError("Payload debe ser un objeto JSON")

        encrypted_payload = obfuscated_data.get("ext_data") or obfuscated_data.get("data")
        if not encrypted_payload:
            raise ValidationError("No se encontro payload oculto en el paquete")

        decrypted_str = self.encryption.decrypt(
            encrypted_payload, purpose="clandestine", associated_data="CLANDESTINE"
        )

        try:
            return json.loads(decrypted_str)
        except json.JSONDecodeError as exc:
            raise ValidationError(f"Payload descifrado no es JSON valido: {exc}") from exc

    def repeat_signal(self, encrypted_packet: str, target_node_id: str) -> dict:
        """
        Retransmite un paquete ya cifrado hacia otro nodo o hacia el Core.
        Permite saltos de senal en entornos con denegacion de servicios.
        El paquete no se descifra en el nodo repetidor (zero-knowledge relay).
        """
        if not encrypted_packet or not target_node_id:
            raise ValidationError("encrypted_packet y target_node_id son requeridos")

        logger.info("signal_repeated", destination=target_node_id)
        return {"status": "SIGNAL_REPEATED", "destination": target_node_id}
