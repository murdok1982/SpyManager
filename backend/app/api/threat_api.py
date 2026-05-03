from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.session_manager import get_db
from core.security import get_current_agent
import onnxruntime as ort
import numpy as np
import os
from core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/threat-prediction", tags=["threat-prediction"])

MODEL_PATH = os.path.join(os.path.dirname(__file__), "../../../models/threat_model.onnx")
_session = None

def get_onnx_session():
    global _session
    if _session is None and os.path.exists(MODEL_PATH):
        _session = ort.InferenceSession(MODEL_PATH)
    return _session

@router.post("/predict")
async def predict_threat(
    features: list[float],
    agent=Depends(get_current_agent),
    db: Session = Depends(get_db)
):
    if len(features) != 4:
        raise HTTPException(400, "Features must be a list of 4 floats: [checkin_freq, location_var, biometric_anomaly, last_checkin_hours]")
    session = get_onnx_session()
    if session is None:
        raise HTTPException(503, "Threat model not available")
    input_data = np.array([features], dtype=np.float32)
    result = session.run(None, {"float_input": input_data})
    probability = float(result[0][0])
    logger.info(f"Threat prediction for agent {agent.id}: {probability}")
    threat_level = "LOW"
    if probability > 0.7:
        threat_level = "HIGH"
    elif probability > 0.4:
        threat_level = "MEDIUM"
    return {"compromise_probability": probability, "threat_level": threat_level, "agent_id": agent.id}
