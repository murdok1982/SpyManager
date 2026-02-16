"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import datetime
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.x509.oid import NameOID
import os
import json

class PKIManager:
    """
    Gestiona la Infraestructura de Clave Pública (PKI) interna para el IMC.
    Usa Ed25519 para mayor seguridad y eficiencia en entornos Edge/Wearable.
    """
    
    def __init__(self, cert_dir: str = "certs"):
        self.cert_dir = cert_dir
        os.makedirs(cert_dir, exist_ok=True)
        self.ca_key_path = os.path.join(cert_dir, "ca_key.pem")
        self.ca_cert_path = os.path.join(cert_dir, "ca_cert.pem")
        self.revoked_certs_path = os.path.join(cert_dir, "revoked_certs.json")
        self._init_revocation_list()

    def _init_revocation_list(self):
        if not os.path.exists(self.revoked_certs_path):
            with open(self.revoked_certs_path, "w") as f:
                json.dump([], f)

    def revoke_certificate(self, entity_id: str):
        """Revoca permanentemente el acceso de una entidad."""
        with open(self.revoked_certs_path, "r") as f:
            revoked = json.load(f)
        if entity_id not in revoked:
            revoked.append(entity_id)
            with open(self.revoked_certs_path, "w") as f:
                json.dump(revoked, f)

    def is_revoked(self, entity_id: str) -> bool:
        """Comprueba si una entidad ha sido revocada."""
        with open(self.revoked_certs_path, "r") as f:
            revoked = json.load(f)
        return entity_id in revoked

    def generate_ca(self):
        """Genera una CA raíz soberana si no existe."""
        if os.path.exists(self.ca_key_path) and os.path.exists(self.ca_cert_path):
            return

        private_key = ed25519.Ed25519PrivateKey.generate()
        
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "ES"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IMC-Sovereign"),
            x509.NameAttribute(NameOID.COMMON_NAME, "IMC Root CA"),
        ])

        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.datetime.now(datetime.timezone.utc)
        ).not_valid_after(
            datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=3650)
        ).add_extension(
            x509.BasicConstraints(ca=True, path_length=None), critical=True,
        ).sign(private_key, hashes.SHA256())

        with open(self.ca_key_path, "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))

        with open(self.ca_cert_path, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))

    def issue_certificate(self, common_name: str, entity_id: str):
        """Emite un certificado firmado por la CA para un usuario o dispositivo."""
        with open(self.ca_key_path, "rb") as f:
            ca_private_key = serialization.load_pem_private_key(f.read(), password=None)
        
        with open(self.ca_cert_path, "rb") as f:
            ca_cert = x509.load_pem_x509_certificate(f.read())

        entity_key = ed25519.Ed25519PrivateKey.generate()
        
        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "ES"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IMC-Sovereign"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
            x509.NameAttribute(NameOID.USER_ID, entity_id),
        ])

        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            ca_cert.subject
        ).public_key(
            entity_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.datetime.now(datetime.timezone.utc)
        ).not_valid_after(
            datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=365)
        ).sign(ca_private_key, hashes.SHA256())

        key_bytes = entity_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        cert_bytes = cert.public_bytes(serialization.Encoding.PEM)
        
        return key_bytes, cert_bytes
