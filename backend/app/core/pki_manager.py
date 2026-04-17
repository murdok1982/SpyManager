"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import datetime
import hashlib
import hmac
import json
import os
import threading
from typing import Optional

import structlog
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.x509.oid import NameOID

from app.core.exceptions import PKIError

logger = structlog.get_logger(__name__)


class PKIManager:
    """
    Gestiona la Infraestructura de Clave Publica (PKI) interna para el IMC.
    Usa Ed25519 para mayor seguridad y eficiencia en entornos Edge/Wearable.
    La lista de revocacion esta firmada con HMAC para garantizar su integridad.
    """

    def __init__(self, cert_dir: str = "certs", master_key: Optional[bytes] = None) -> None:
        self.cert_dir = cert_dir
        self._master_key = master_key
        self._lock = threading.Lock()
        os.makedirs(cert_dir, exist_ok=True)
        self.ca_key_path = os.path.join(cert_dir, "ca_key.pem")
        self.ca_cert_path = os.path.join(cert_dir, "ca_cert.pem")
        self.revoked_certs_path = os.path.join(cert_dir, "revoked_certs.json")
        self._init_revocation_list()

    # ------------------------------------------------------------------
    # Revocation list con firma HMAC
    # ------------------------------------------------------------------

    def _sign_revocation_list(self, revoked: list) -> str:
        """Firma la lista de revocacion con HMAC-SHA256 usando la master key."""
        if not self._master_key:
            return ""
        payload = json.dumps(sorted(revoked), separators=(",", ":")).encode("utf-8")
        return hmac.new(self._master_key, payload, hashlib.sha256).hexdigest()

    def _init_revocation_list(self) -> None:
        if not os.path.exists(self.revoked_certs_path):
            self._write_revocation_list([])

    def _write_revocation_list(self, revoked: list) -> None:
        signature = self._sign_revocation_list(revoked)
        data = {"revoked": revoked, "signature": signature}
        tmp_path = self.revoked_certs_path + ".tmp"
        with open(tmp_path, "w") as f:
            json.dump(data, f)
        os.replace(tmp_path, self.revoked_certs_path)

    def _read_revocation_list(self) -> list:
        with open(self.revoked_certs_path, "r") as f:
            data = json.load(f)

        if isinstance(data, list):
            # Migrar formato antiguo
            logger.warning("revocation_list_legacy_format_migrated")
            self._write_revocation_list(data)
            return data

        revoked: list = data.get("revoked", [])

        if self._master_key:
            expected = self._sign_revocation_list(revoked)
            actual = data.get("signature", "")
            if not hmac.compare_digest(expected, actual):
                raise PKIError("Revocation list signature invalid — possible tampering detected")

        return revoked

    def revoke_certificate(self, entity_id: str) -> None:
        """Revoca permanentemente el acceso de una entidad."""
        with self._lock:
            revoked = self._read_revocation_list()
            if entity_id not in revoked:
                revoked.append(entity_id)
                self._write_revocation_list(revoked)
                logger.info("certificate_revoked", entity_id=entity_id)

    def is_revoked(self, entity_id: str) -> bool:
        """Comprueba si una entidad ha sido revocada."""
        revoked = self._read_revocation_list()
        return entity_id in revoked

    # ------------------------------------------------------------------
    # CA generation
    # ------------------------------------------------------------------

    def generate_ca(self) -> None:
        """Genera una CA raiz soberana si no existe."""
        if os.path.exists(self.ca_key_path) and os.path.exists(self.ca_cert_path):
            return

        private_key = ed25519.Ed25519PrivateKey.generate()

        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "ES"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IMC-Sovereign"),
            x509.NameAttribute(NameOID.COMMON_NAME, "IMC Root CA"),
        ])

        cert = (
            x509.CertificateBuilder()
            .subject_name(subject)
            .issuer_name(issuer)
            .public_key(private_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
            .not_valid_after(
                datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=3650)
            )
            .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
            .sign(private_key, hashes.SHA256())
        )

        with open(self.ca_key_path, "wb") as f:
            f.write(
                private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption(),
                )
            )

        with open(self.ca_cert_path, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))

        logger.info("ca_generated", ca_cert_path=self.ca_cert_path)

    # ------------------------------------------------------------------
    # CSR issuance
    # ------------------------------------------------------------------

    def issue_certificate_from_csr(self, csr_pem: bytes, entity_id: str) -> bytes:
        """
        Emite un certificado firmado por la CA a partir de un CSR.
        Garantiza que la clave privada nunca abandone el dispositivo (Zero Trust).
        Valida: firma del CSR, formato, y que entity_id no este ya revocado.
        """
        try:
            csr = x509.load_pem_x509_csr(csr_pem)
        except Exception as exc:
            raise PKIError(f"CSR parsing failed: {type(exc).__name__}") from exc

        if not csr.is_signature_valid:
            raise PKIError("CSR signature is invalid")

        if self.is_revoked(entity_id):
            raise PKIError(f"Entity {entity_id} is already revoked")

        try:
            with open(self.ca_key_path, "rb") as f:
                ca_private_key = serialization.load_pem_private_key(f.read(), password=None)
            with open(self.ca_cert_path, "rb") as f:
                ca_cert = x509.load_pem_x509_certificate(f.read())
        except FileNotFoundError as exc:
            raise PKIError("CA not initialized — call generate_ca() first") from exc

        cn_attrs = csr.subject.get_attributes_for_oid(NameOID.COMMON_NAME)
        cn_value = cn_attrs[0].value if cn_attrs else entity_id

        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "ES"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IMC-Sovereign"),
            x509.NameAttribute(NameOID.COMMON_NAME, cn_value),
            x509.NameAttribute(NameOID.USER_ID, entity_id),
        ])

        cert = (
            x509.CertificateBuilder()
            .subject_name(subject)
            .issuer_name(ca_cert.subject)
            .public_key(csr.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
            .not_valid_after(
                datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=365)
            )
            .sign(ca_private_key, hashes.SHA256())
        )

        logger.info("certificate_issued", entity_id=entity_id)
        return cert.public_bytes(serialization.Encoding.PEM)
