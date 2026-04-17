"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import base64
import os
import struct
import threading
import time
from typing import Dict

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

from app.core.exceptions import EncryptionError


class EncryptionService:
    """
    Servicio de cifrado autenticado AES-256-GCM con HKDF por proposito.
    - Cada proposito (purpose) deriva su propia clave via HKDF.
    - El nonce de 12 bytes combina aleatoriedad + contador monotono + timestamp
      para garantizar unicidad sin depender unicamente de os.urandom.
    """

    def __init__(self, master_key: bytes) -> None:
        if len(master_key) != 32:
            raise ValueError("La clave maestra debe ser de 32 bytes (256 bits).")
        self._master_key = master_key
        # Contador monotono con semilla aleatoria para evitar colisiones al reiniciar
        self._counter = int.from_bytes(os.urandom(4), "big")
        self._lock = threading.Lock()
        self._derived_keys: Dict[str, AESGCM] = {}

    # ------------------------------------------------------------------
    # Key derivation
    # ------------------------------------------------------------------

    def _derive_key(self, purpose: str) -> AESGCM:
        """Deriva una clave AES-256 unica para el proposito dado (cached)."""
        if purpose not in self._derived_keys:
            hkdf = HKDF(
                algorithm=hashes.SHA256(),
                length=32,
                salt=None,
                info=purpose.encode("utf-8"),
                backend=default_backend(),
            )
            key = hkdf.derive(self._master_key)
            self._derived_keys[purpose] = AESGCM(key)
        return self._derived_keys[purpose]

    # ------------------------------------------------------------------
    # Nonce generation
    # ------------------------------------------------------------------

    def _generate_nonce(self) -> bytes:
        """
        Genera un nonce de 12 bytes:
          bytes 0-3  : aleatorio
          bytes 4-7  : contador monotono (little-endian)
          bytes 8-11 : timestamp UNIX de 32 bits
        La combinacion garantiza unicidad incluso bajo concurrencia alta.
        """
        with self._lock:
            self._counter += 1
            count = self._counter
        prefix = os.urandom(4)
        counter_bytes = struct.pack(">I", count & 0xFFFFFFFF)
        ts_bytes = struct.pack(">I", int(time.time()) & 0xFFFFFFFF)
        return prefix + counter_bytes + ts_bytes

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def encrypt(
        self, data: str, purpose: str = "general", associated_data: str = ""
    ) -> str:
        """
        Cifra data y devuelve base64(nonce[12] + ciphertext+tag).
        associated_data proporciona autenticacion adicional (AAD) sin cifrar.
        """
        try:
            aesgcm = self._derive_key(purpose)
            nonce = self._generate_nonce()
            ciphertext = aesgcm.encrypt(
                nonce,
                data.encode("utf-8"),
                associated_data.encode("utf-8"),
            )
            return base64.b64encode(nonce + ciphertext).decode("ascii")
        except EncryptionError:
            raise
        except Exception as exc:
            raise EncryptionError(
                f"Encryption failed: {type(exc).__name__}"
            ) from None

    def decrypt(
        self, encrypted_data: str, purpose: str = "general", associated_data: str = ""
    ) -> str:
        """Descifra y verifica autenticidad. Lanza EncryptionError ante cualquier fallo."""
        try:
            # El padding "==" es inocuo si ya tiene padding correcto
            raw = base64.b64decode(encrypted_data + "==")
        except Exception:
            raise EncryptionError("Decryption failed — invalid base64 encoding") from None

        if len(raw) < 12:
            raise EncryptionError("Payload too short — minimum 12 bytes required")

        nonce = raw[:12]
        ciphertext = raw[12:]
        try:
            aesgcm = self._derive_key(purpose)
            decrypted = aesgcm.decrypt(
                nonce,
                ciphertext,
                associated_data.encode("utf-8"),
            )
            return decrypted.decode("utf-8")
        except EncryptionError:
            raise
        except Exception:
            raise EncryptionError(
                "Decryption failed — invalid data or wrong key"
            ) from None

    @staticmethod
    def generate_master_key() -> str:
        """Genera una master key de 32 bytes y la devuelve como hex string (64 chars)."""
        return AESGCM.generate_key(bit_length=256).hex()
