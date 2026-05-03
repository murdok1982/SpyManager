# Link Analysis Dashboard - Design Specs

## Propósito
Visualizar relaciones entre agentes, casos, fuentes HUMINT y objetivos usando grafo de conocimiento (Neo4j).

## Componentes

### 1. Force-Directed Graph (Core)
- Motor: Neo4j + D3.js (vía WebView en Flutter)
- Nodos: Agentes (círculos azules), Casos (cuadrados rojos), Fuentes (triángulos verdes)
- Aristas: "ASSIGNED_TO", "REPORTED_BY", "LINKED_TO"
- Interacción: Zoom, pan, arrastrar nodos

### 2. Node Detail Panel
- Al hacer clic en nodo: panel lateral con:
  - ID y nombre
  - Clasificación de seguridad
  - Última actividad
  - Lista de conexiones (aristas)

### 3. Filter Controls
- Por tipo de nodo (Agente, Caso, Fuente)
- Por nivel de clasificación (UNCLASSIFIED a TOP_SECRET)
- Por fecha de última actividad
- Por caso específico

### 4. Threat Heatmap
- Mapa de calor en el grafo
- Colores: Verde (baja amenaza) a Rojo (alta amenaza)
- Basado en: frecuencia de check-in, anomalías biométricas

## Layout
```
+------------------------------------------------+
|  LINK ANALYSIS        [Filter: v] [Search: ____]|
+------------------------------------------------+
|                                                |
|    (Force-Directed Graph Visualization)          |
|                                                |
|   [Agent] ---- [Case] ---- [Source]            |
|      |            |           |                  |
|      +------------+-----------+                  |
|                                                |
+------------------------------------------------+
| Node Detail: [selected node info here]          |
+------------------------------------------------+
```

## Accesibilidad
- Grafo navegable con teclado (flechas para mover nodos)
- Lectores de pantalla anuncian conexiones de cada nodo
- Contraste 7:1 en todos los elementos del grafo

## Integración con Backend
- Endpoint: GET /api/v1/link-analysis/graph?case_id=X
- Formato: JSON con nodos y aristas
- Actualización en tiempo real cada 30 segundos
