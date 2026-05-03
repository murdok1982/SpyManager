from neo4j import GraphDatabase
from core.config import settings
from circuitbreaker import circuit
import logging

logger = logging.getLogger(__name__)

class Neo4jService:
    def __init__(self):
        self.uri = settings.NEO4J_URI
        self.user = settings.NEO4J_USER
        self.password = settings.NEO4J_PASSWORD
        self._driver = None

    @property
    def driver(self):
        if self._driver is None:
            self._driver = GraphDatabase.driver(self.uri, auth=(self.user, self.password))
        return self._driver

    def close(self):
        if self._driver:
            self._driver.close()
            self._driver = None

    @circuit(failure_threshold=settings.CIRCUIT_BREAKER_FAIL_MAX, recovery_timeout=settings.CIRCUIT_BREAKER_RESET_TIMEOUT)
    def create_node(self, label: str, props: dict):
        with self.driver.session() as session:
            session.run(f"CREATE (n:{label} $props)", props=props)

    @circuit(failure_threshold=settings.CIRCUIT_BREAKER_FAIL_MAX, recovery_timeout=settings.CIRCUIT_BREAKER_RESET_TIMEOUT)
    def create_relationship(self, node1_id: int, node2_id: int, rel_type: str, node1_label: str = "Agent", node2_label: str = "Case"):
        # Validar que rel_type y labels no contengan caracteres peligrosos
        import re
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', rel_type):
            raise ValueError("Invalid relationship type")
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', node1_label):
            raise ValueError("Invalid node1 label")
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', node2_label):
            raise ValueError("Invalid node2 label")
        with self.driver.session() as session:
            session.run(
                f"MATCH (a:`{node1_label}`), (b:`{node2_label}`) WHERE a.id = $id1 AND b.id = $id2 CREATE (a)-[:`{rel_type}`]->(b)",
                id1=node1_id, id2=node2_id
            )

    @circuit(failure_threshold=settings.CIRCUIT_BREAKER_FAIL_MAX, recovery_timeout=settings.CIRCUIT_BREAKER_RESET_TIMEOUT)
    def query_graph(self, cypher_query: str, params: dict = None):
        # Solo permitir consultas parametrizadas seguras (no modificaciones)
        if any(kw in cypher_query.upper() for kw in ["CREATE", "DELETE", "SET", "REMOVE", "MERGE"]):
            raise ValueError("Only read queries allowed via this method")
        with self.driver.session() as session:
            result = session.run(cypher_query, params or {})
            return [record.data() for record in result]

neo4j_service = Neo4jService()
