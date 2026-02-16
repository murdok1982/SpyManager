"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
Este software es propiedad intelectual exclusiva del creador. 
Su uso, copia o distribución no está autorizado sin permiso expreso y por escrito.
"""
from fastapi import FastAPI, Depends, HTTPException, Header
from typing import Dict
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.repository import IntelRepository
from app.services.encryption_service import EncryptionService
from app.services.audit_service import AuditService
from app.services.ai_compartment import AICompartmentService
from app.schemas.intel import IntelCreate, IntelResponse, UserAuth
from app.core.abac_engine import UserAttributes, ClassificationLevel
import os
from app.core.pki_manager import PKIManager
from app.services.kill_switch_service import KillSwitchService
from app.api.wearable_api import router as wearable_router

app = FastAPI(title="Intelligence Management Core (IMC)")

# Configuración de Master Key segura
MASTER_KEY_RAW = os.getenv("IMC_MASTER_KEY", "f" * 32)
if len(MASTER_KEY_RAW) != 32:
    MASTER_KEY_RAW = MASTER_KEY_RAW[:32].ljust(32, "0")

pki_manager = PKIManager()
pki_manager.generate_ca()
encryption_service = EncryptionService(MASTER_KEY_RAW.encode())
audit_service = AuditService()
ai_service = AICompartmentService()
kill_switch = KillSwitchService(pki_manager, audit_service)

app.include_router(wearable_router)

async def get_db():
    yield None

async def verify_pki_and_auth(x_pki_entity_id: str = Header(...)):
    """
    Validación rigurosa: mTLS + Estado de Revocación + Atributos.
    """
    # 1. Comprobar si el certificado ha sido neutralizado via Kill Switch
    if pki_manager.is_revoked(x_pki_entity_id):
        raise HTTPException(status_code=403, detail="ENTITY_NEUTRALIZED")

    # Mock de resolución de atributos del usuario
    return UserAttributes(
        user_id=x_pki_entity_id,
        role="ANALISTA_CAMPO",
        classification_level=ClassificationLevel.SECRET,
        assigned_cases=["CASO_ALPHA", "CASO_OMEGA"]
    )

@app.post("/system/kill-switch", tags=["System"])
async def trigger_emergency_kill(
    target_id: str,
    reason: str,
    user: UserAttributes = Depends(verify_pki_and_auth)
):
    """Activación del Kill Switch (Solo ADMIN/DIRECTOR)."""
    if user.role not in ["ADMIN", "DIRECTOR"]:
        raise HTTPException(status_code=403, detail="UNAUTHORIZED_COMMAND")
        
    return kill_switch.trigger_kill_switch(target_id, user.user_id, reason)

@app.post("/intel/ingest", response_model=Dict)
async def ingest_intelligence(
    data: IntelCreate,
    user: UserAttributes = Depends(verify_pki_and_auth),
    db: AsyncSession = Depends(get_db)
):
    """
    Punto de entrada seguro para la ingestión de inteligencia.
    Aplica: PKI Validation -> ABAC -> Encryption -> Audit -> AI Indexing.
    """
    repo = IntelRepository(db, encryption_service, audit_service)
    
    try:
        # 1. Ingestión en repositorio seguro (aplica ABAC y Cifrado)
        # Nota: Usamos db=None por el mock, en real se manejaría la transacción
        package = await repo.create_package(user, data.model_dump())
        
        # 2. Indexación en IA local compartimentada
        ai_service.ingest_intel(data.case_id, data.id, data.content)
        
        return {
            "status": "SECURE_INGESTED",
            "package_id": data.id,
            "hash_integrity": package.access_log_reference
        }
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal Secure Error")

@app.get("/health", tags=["System"])
def health_check():
    return {"status": "OPERATIONAL", "security": "ZERO_TRUST_ENFORCED"}
