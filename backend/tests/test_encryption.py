import pytest
from app.services.encryption_service import EncryptionService
from app.core.exceptions import EncryptionError


MASTER_KEY = bytes.fromhex("a" * 64)


def test_encrypt_decrypt_roundtrip():
    svc = EncryptionService(MASTER_KEY)
    plaintext = "CLASSIFIED INTEL: Operation Alpha"
    encrypted = svc.encrypt(plaintext, purpose="test")
    assert encrypted != plaintext
    decrypted = svc.decrypt(encrypted, purpose="test")
    assert decrypted == plaintext


def test_different_purposes_isolate_keys():
    svc = EncryptionService(MASTER_KEY)
    plaintext = "secret data"
    encrypted = svc.encrypt(plaintext, purpose="audit")
    with pytest.raises(EncryptionError):
        svc.decrypt(encrypted, purpose="intel")


def test_associated_data_enforced():
    svc = EncryptionService(MASTER_KEY)
    plaintext = "message"
    encrypted = svc.encrypt(plaintext, purpose="test", associated_data="context_a")
    with pytest.raises(EncryptionError):
        svc.decrypt(encrypted, purpose="test", associated_data="context_b")


def test_nonces_are_unique():
    svc = EncryptionService(MASTER_KEY)
    plaintext = "same message"
    enc1 = svc.encrypt(plaintext, purpose="test")
    enc2 = svc.encrypt(plaintext, purpose="test")
    assert enc1 != enc2


def test_tampered_ciphertext_rejected():
    svc = EncryptionService(MASTER_KEY)
    import base64
    encrypted = svc.encrypt("data", purpose="test")
    raw = bytearray(base64.b64decode(encrypted + "=="))
    raw[-1] ^= 0xFF
    tampered = base64.b64encode(bytes(raw)).decode()
    with pytest.raises(EncryptionError):
        svc.decrypt(tampered, purpose="test")


def test_empty_string_encrypts():
    svc = EncryptionService(MASTER_KEY)
    encrypted = svc.encrypt("", purpose="test")
    assert svc.decrypt(encrypted, purpose="test") == ""


def test_unicode_content():
    svc = EncryptionService(MASTER_KEY)
    text = "Operacion Aguila — coordenadas: 40N 3W"
    assert svc.decrypt(svc.encrypt(text, purpose="test"), purpose="test") == text
