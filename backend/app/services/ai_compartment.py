"""
🦅 Intelligence Management Core (IMC)
Creador: [USUARIO] (@murdok1982)
PROPIEDAD PRIVADA - USO RESTRINGIDO
"""
from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Dict
import os
import json

class AICompartmentService:
    """
    Servicio de IA Compartimentada.
    Genera embeddings locales y gestiona la búsqueda vectorial aislada por caso.
    """
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2", store_path: str = "data/vector_store.json"):
        # En producción esto cargaría un modelo local (ej. vía Ollama o Transformers)
        self.model = SentenceTransformer(model_name)
        self.store_path = store_path
        os.makedirs(os.path.dirname(store_path), exist_ok=True)
        self.vector_store: Dict[str, List[Dict]] = self._load_store()

    def _load_store(self) -> Dict:
        if os.path.exists(self.store_path):
            with open(self.store_path, "r") as f:
                return json.load(f)
        return {}

    def _save_store(self):
        with open(self.store_path, "w") as f:
            json.dump(self.vector_store, f)

    def ingest_intel(self, case_id: str, package_id: str, content: str):
        """Genera embedding y lo guarda en el compartimento del caso."""
        embedding = self.model.encode(content)
        
        if case_id not in self.vector_store:
            self.vector_store[case_id] = []
            
        self.vector_store[case_id].append({
            "id": package_id,
            "vector": embedding.tolist()
        })
        self._save_store()

    def search_similar(self, case_id: str, query: str, limit: int = 5) -> List[str]:
        """Busca información relacionada ÚNICAMENTE dentro del compartimento del caso."""
        if case_id not in self.vector_store:
            return []
            
        query_vec = self.model.encode(query)
        
        results = []
        for item in self.vector_store[case_id]:
            sim = self.cosine_similarity(query_vec, np.array(item["vector"]))
            results.append((item["id"], sim))
            
        # Ordenar por similitud
        results.sort(key=lambda x: x[1], reverse=True)
        return [id for id, sim in results[:limit]]

    @staticmethod
    def cosine_similarity(a, b):
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        
    def cross_compartment_check(self, query: str):
        """
        Relación inter-caso segura.
        Solo devuelve metadatos minimizados si hay una correlación alta,
        sin revelar el contenido de otros compartimentos.
        """
        # TODO: Implementar lógica de 'Differential Privacy' o metadatos ciegos
        pass
