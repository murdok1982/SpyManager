from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from core.security import get_current_agent
from sqlalchemy.orm import Session
from database.session_manager import get_db
import whisper
import tempfile
import os
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/multimodal", tags=["multimodal"])

_whisper_model = None

def get_whisper_model():
    global _whisper_model
    if _whisper_model is None:
        try:
            _whisper_model = whisper.load_model("base")
        except Exception as e:
            logger.error(f"Whisper load failed: {e}")
    return _whisper_model

MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB max

@router.post("/transcribe-audio")
async def transcribe_audio(
    audio: UploadFile = File(...),
    agent=Depends(get_current_agent),
    db: Session = Depends(get_db)
):
    # Validar tamaño del archivo
    audio_data = await audio.read()
    if len(audio_data) > MAX_FILE_SIZE:
        raise HTTPException(413, "File too large (max 50MB)")
    if len(audio_data) == 0:
        raise HTTPException(400, "Empty file")

    model = get_whisper_model()
    if model is None:
        raise HTTPException(503, "Whisper model not available")
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(audio_data)
            tmp_path = tmp.name
        result = model.transcribe(tmp_path)
        os.unlink(tmp_path)
        logger.info(f"Audio transcribed by agent {agent.id}")
        return {"transcript": result["text"], "language": result.get("language")}
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        raise HTTPException(500, "Transcription failed")

@router.post("/classify-image")
async def classify_image(
    image: UploadFile = File(...),
    agent=Depends(get_current_agent),
    db: Session = Depends(get_db)
):
    # Validar tamaño
    image_data = await image.read()
    if len(image_data) > MAX_FILE_SIZE:
        raise HTTPException(413, "File too large (max 50MB)")
    if len(image_data) == 0:
        raise HTTPException(400, "Empty file")

    try:
        from ultralytics import YOLO
        model = YOLO("yolov8n.pt")
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            tmp.write(image_data)
            tmp_path = tmp.name
        results = model(tmp_path)
        os.unlink(tmp_path)
        classifications = []
        for r in results:
            if r.boxes:
                for box in r.boxes:
                    cls_id = int(box.cls[0])
                    conf = float(box.conf[0])
                    classifications.append({"class": r.names[cls_id], "confidence": conf})
        logger.info(f"Image classified by agent {agent.id}: {len(classifications)} objects")
        return {"classifications": classifications}
    except Exception as e:
        logger.error(f"Image classification error: {e}")
        raise HTTPException(500, "Classification failed")
