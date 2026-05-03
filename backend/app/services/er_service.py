from thefuzz import process, fuzz
from sqlalchemy.orm import Session
from database.models import HUMINTSource
import logging

logger = logging.getLogger(__name__)

class ERService:
    def deduplicate_sources(self, db: Session):
        sources = db.query(HUMINTSource).all()
        updated = 0
        for source in sources:
            if source.duplicate_of_id:
                continue
            names = [s.name for s in sources if s.id != source.id and not s.duplicate_of_id]
            if not names:
                continue
            matches = process.extract(source.name, names, scorer=fuzz.ratio, limit=3)
            for match_name, score in matches:
                if score > 85:
                    duplicate = db.query(HUMINTSource).filter(HUMINTSource.name == match_name).first()
                    if duplicate and duplicate.id != source.id:
                        source.duplicate_of_id = duplicate.id
                        source.fuzzy_match_score = float(score)
                        updated += 1
                        break
        db.commit()
        logger.info(f"Entity Resolution: {updated} sources marked as duplicates")
        return updated

er_service = ERService()
