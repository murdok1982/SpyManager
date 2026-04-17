"""
Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
import asyncio
import os
from typing import List, Optional

import structlog

logger = structlog.get_logger(__name__)


class AICompartmentService:
    """
    Servicio de IA Compartimentada usando ChromaDB como vector store.
    Cada caso opera en su propia coleccion aislada (compartimentacion estricta).
    El modelo de embeddings se ejecuta localmente para garantizar air-gap.
    """

    def __init__(self, store_path: str = "./data/chroma") -> None:
        self._store_path = store_path
        self._client = None
        self._model = None
        os.makedirs(store_path, exist_ok=True)

    def _get_client(self):
        """Inicializacion lazy de ChromaDB para no bloquear el startup."""
        if self._client is None:
            try:
                import chromadb
                self._client = chromadb.PersistentClient(path=self._store_path)
            except ImportError as exc:
                raise RuntimeError(
                    "chromadb no esta instalado. Agrega 'chromadb>=0.4.24' a requirements.txt"
                ) from exc
        return self._client

    def _get_model(self):
        """Inicializacion lazy del modelo de embeddings."""
        if self._model is None:
            try:
                from sentence_transformers import SentenceTransformer
                self._model = SentenceTransformer("all-MiniLM-L6-v2")
            except ImportError as exc:
                raise RuntimeError(
                    "sentence-transformers no esta instalado."
                ) from exc
        return self._model

    def _get_collection(self, case_id: str):
        """Obtiene o crea la coleccion ChromaDB para un caso especifico."""
        client = self._get_client()
        # Sanitizar case_id para nombre de coleccion valido en ChromaDB
        safe_name = "case_" + "".join(c if c.isalnum() else "_" for c in case_id)[:60]
        return client.get_or_create_collection(
            name=safe_name,
            metadata={"hnsw:space": "cosine"},
        )

    async def ingest_intel(
        self, case_id: str, package_id: str, content: str
    ) -> None:
        """
        Genera embedding del contenido y lo indexa en el compartimento del caso.
        La operacion CPU-intensiva se delega a un thread worker para no bloquear.
        """
        def _sync_ingest():
            model = self._get_model()
            embedding = model.encode(content).tolist()
            collection = self._get_collection(case_id)
            collection.upsert(
                ids=[package_id],
                embeddings=[embedding],
                documents=[content[:500]],  # Solo fragmento para evitar PII en metadatos
            )

        await asyncio.to_thread(_sync_ingest)
        logger.info("intel_ingested", case_id=case_id, package_id=package_id)

    async def search_similar(
        self,
        case_id: str,
        query: str,
        limit: int = 5,
        user_classification: Optional[int] = None,
    ) -> List[str]:
        """
        Busca informacion relacionada UNICAMENTE dentro del compartimento del caso.
        Nunca filtra entre casos distintos para garantizar compartimentacion estricta.
        """
        def _sync_search():
            model = self._get_model()
            query_embedding = model.encode(query).tolist()
            collection = self._get_collection(case_id)
            results = collection.query(
                query_embeddings=[query_embedding],
                n_results=min(limit, 10),
            )
            return results.get("ids", [[]])[0]

        try:
            ids = await asyncio.to_thread(_sync_search)
            return ids
        except Exception as exc:
            logger.error("intel_search_failed", case_id=case_id, error=str(exc))
            return []

    async def delete_case_compartment(self, case_id: str) -> None:
        """Elimina completamente el compartimento de un caso (para kill switch)."""
        def _sync_delete():
            client = self._get_client()
            safe_name = "case_" + "".join(c if c.isalnum() else "_" for c in case_id)[:60]
            try:
                client.delete_collection(safe_name)
            except Exception:
                pass  # Ya no existia

        await asyncio.to_thread(_sync_delete)
        logger.warning("case_compartment_deleted", case_id=case_id)
