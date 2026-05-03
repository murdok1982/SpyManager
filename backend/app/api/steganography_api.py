from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from stegano import lsb
from services.encryption_service import encrypt, decrypt
from core.security import get_current_agent
from sqlalchemy.orm import Session
from database.session_manager import get_db
import io
from PIL import Image
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/steganography", tags=["steganography"])

@router.post("/encode")
async def encode_steganography(
    image: UploadFile = File(...),
    message: str = "",
    agent=Depends(get_current_agent),
    db: Session = Depends(get_db)
):
    try:
        encrypted_msg = encrypt(message)
        img_data = await image.read()
        img = Image.open(io.BytesIO(img_data))
        encoded_img = lsb.hide(img, encrypted_msg)
        output = io.BytesIO()
        encoded_img.save(output, format=img.format or "PNG")
        output.seek(0)
        logger.info(f"Steganography encode by agent {agent.id}")
        return {"encoded_image": output.read().hex(), "status": "success"}
    except Exception as e:
        logger.error(f"Steganography encode error: {e}")
        raise HTTPException(500, "Encoding failed")

@router.post("/decode")
async def decode_steganography(
    image: UploadFile = File(...),
    agent=Depends(get_current_agent),
    db: Session = Depends(get_db)
):
    try:
        img_data = await image.read()
        img = Image.open(io.BytesIO(img_data))
        hidden_msg = lsb.reveal(img)
        if not hidden_msg:
            raise HTTPException(400, "No hidden message found")
        decrypted_msg = decrypt(hidden_msg)
        logger.info(f"Steganography decode by agent {agent.id}")
        return {"message": decrypted_msg, "status": "success"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Steganography decode error: {e}")
        raise HTTPException(500, "Decoding failed")
