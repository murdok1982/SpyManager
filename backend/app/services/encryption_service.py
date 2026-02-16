"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import os
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class EncryptionService:
    """
    Servicio de cifrado authenticated (AES-256-GCM).
    Proporciona confidencialidad e integridad para los paquetes de inteligencia.
    """
    
    def __init__(self, master_key: bytes):
        if len(master_key) != 32:
            raise ValueError("La clave maestra debe ser de 32 bytes (256 bits).")
        self.aesgcm = AESGCM(master_key)

    def encrypt(self, data: str, associated_data: str = "") -> str:
        """Cifra datos y devuelve un string en base64 (nonce + ciphertext + tag)."""
        nonce = os.urandom(12)
        ciphertext = self.aesgcm.encrypt(nonce, data.encode(), associated_data.encode())
        return base64.b64encode(nonce + ciphertext).decode()

    def decrypt(self, encrypted_data: str, associated_data: str = "") -> str:
        """Descifra datos cifrados en base64."""
        data = base64.b64decode(encrypted_data)
        nonce = data[:12]
        ciphertext = data[12:]
        decrypted_data = self.aesgcm.decrypt(nonce, ciphertext, associated_data.encode())
        return decrypted_data.decode()

    @staticmethod
    def generate_key() -> bytes:
        return AESGCM.generate_key(bit_length=256)
