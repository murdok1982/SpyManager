# SIEM Dashboard - Design Specs

## Propósito
Visualizar logs de auditoría exportados a SIEM (Splunk/QRadar) en tiempo real.

## Componentes

### 1. Log Stream View
- Lista desplazable de eventos de auditoría
- Cada fila: Timestamp | User | Action | Resource | Threat Level
- Colores: Verde (normal), Amarillo (sospechoso), Rojo (crítico)
- Filtro por: user_id, action_type, threat_level

### 2. Threat Map (World Map)
- Mapa mundi con puntos de origen de eventos
- Tamaño del punto = frecuencia de eventos
- Color = nivel de amenaza
- Click en punto: detalle de eventos de esa IP/ubicación

### 3. Live Alert Feed
- Panel lateral derecho
- Alertas en tiempo real (WebSocket)
- Tipos: Honeypot Access, Duress PIN, Dead Man's Switch, Anomaly
- Sonido de alerta configurable (silenciable)

### 4. Statistics Panel
- Eventos por hora (gráfico de barras)
- Top 5 agentes más activos
- Top 5 IPs sospechosas
- Tasa de eventos críticos (últimas 24h)

## Layout
```
+------------------------------------------------+
|  SIEM DASHBOARD        [Filter: v] [Search: ____]|
+------------------------------------------------+
| Log Stream          | Alert Feed                 |
| - 10:23 Agent1...  | ! Honeypot Access (CaseX) |
| - 10:24 Agent2...  | ! Duress PIN detected    |
| - 10:25 Agent3...  | ! Threat Level HIGH      |
| ...                 |                           |
+------------------------------------------------+
| Threat Map (World)  | Statistics                |
| (map here)          | (charts here)             |
+------------------------------------------------+
```

## Integración con Backend
- Endpoint: GET /api/v1/siem/logs?limit=100
- WebSocket: /ws/siem/alerts
- Export: POST /api/v1/siem/export (formato STANAG 5516)
