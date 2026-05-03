# Threat Prediction Dashboard - Design Specs

## Propósito
Mostrar predicción de probabilidad de compromiso de un agente basada en modelo ONNX local.

## Componentes

### 1. Threat Level Indicator (Circular)
- Gráfico circular tipo "speedometer"
- Colores: Verde (0-40%), Amarillo (40-70%), Rojo (70-100%)
- Número central: probabilidad exacta (ej. "73.5%")
- Etiqueta: "BAJO" / "MEDIO" / "ALTO"

### 2. Risk Factors Breakdown
- Lista de factores contribuyentes:
  - Frecuencia de check-in (últimas 48h)
  - Varianza de ubicación (desviación estándar)
  - Anomalía biométrica (puntuación 0-1)
  - Horas desde último check-in
- Cada factor tiene barra de progreso coloreada

### 3. Historical Trend (Line Chart)
- Gráfico de línea: probabilidad vs. tiempo (últimas 24h)
- Puntos de alerta marcados con icono de advertencia
- Filtro: 24h, 7d, 30d

### 4. Recommended Actions
- Si Threat Level > 70% (ALTO):
  - "Cambiar ubicación inmediatamente"
  - "Realizar check-in manual"
  - "Activar Ghost Mode"
  - "Enviar reporte de situación"
- Si Threat Level 40-70% (MEDIO):
  - "Mantener vigilancia"
  - "Verificar entorno"
- Si Threat Level < 40% (BAJO):
  - "Operación normal"

## Layout
```
+------------------------------------------------+
|  THREAT PREDICTION        Agente: ID-12345      |
+------------------------------------------------+
|                                                |
|            (     73.5%     )                    |
|            (   AMENAZA ALTA   )                |
|                                                |
|  Factores de Riesgo:                           |
|  [==========        ] Check-in: 45%            |
|  [============      ] Ubicación: 60%           |
|  [===============   ] Biometría: 75%           |
|                                                |
|  Tendencia (24h):                              |
|  (line chart here)                             |
|                                                |
|  ACCIONES RECOMENDADAS:                        |
|  - Cambiar ubicación                           |
|  - Activar Ghost Mode                          |
+------------------------------------------------+
```

## Accesibilidad
- No confiar solo en color: usar iconos y texto descriptivo
- Contraste 7:1 en texto e indicadores
- Soporte para lectores de pantalla (anuncia nivel de amenaza)

## Integración con Backend
- Endpoint: POST /api/v1/threat-prediction/predict
- Input: [checkin_freq, location_var, biometric_anomaly, hours_since_checkin]
- Output: {probability: float, threat_level: string}
- Modelo: threat_model.onnx (local, no conexión externa)
