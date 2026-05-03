# SpyManager IMC — Predictive Threat Modeling Dashboard Design
Agente: DISENO | Fecha: 2026-05-03

---

## VISION GENERAL

Dashboard predictivo que utiliza analisis de datos historicos, machine learning y patrones de comportamiento para predecir amenazas potenciales antes de que ocurran.

**Objetivo:** Proporcionar una vista anticipatoria del entorno operacional, permitiendo acciones preventivas.

---

## LAYOUT PRINCIPAL

```
┌──────────────────────────────────────────────────────┐
│  AppBar [PREDICCION DE AMENAZAS]  [⚙ CONFIG]      │
│  color: bgSurface | border bottom: borderSubtle 1dp │
├──────────────────────────────────────────────────────┤
│  Threat Level Global:                                │
│  ┌────────────────────────────────────────────────┐  │
│  │  ████████████░░░░░░░░  ALTO (78%)          │  │ ← threat bar
│  │  Tendencia: ↗ SUBIENDO (ultimas 72h)         │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Row de 3 Cards (horizontal scroll si < 900dp):       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│
│  │ COMPORTAMIENTO │ │ UBICACION    │ │ COMUNICACIONES│
│  │ Risk: 82%     │ │ Risk: 65%    │ │ Risk: 71%    │
│  │ ↗ MEDIO       │ │ → ESTABLE    │ │ ↗ SUBIENDO  │
│  └──────────────┘ └──────────────┘ └──────────────┘│
├──────────────────────────────────────────────────────┤
│  Grafico de Prediccion (300dp):                       │
│  ┌────────────────────────────────────────────────┐  │
│  │  Risk Score (0-100)                           │  │
│  │  90 ┤               ● (prediccion 72h)       │  │
│  │     │          ● ●                           │  │ ← line chart
│  │  60 ┤      ● ●                               │  │
│  │     │   ● ●                                   │  │
│  │  30 ┤● ●                                       │  │
│  │     └─────┬─────┬─────┬─────┬─────┬─────┬───   │  │
│  │       -24h  -12h  0h  12h   24h   48h   72h    │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Factores de Riesgo (expansible):                    │
│  • Movimiento inusual detectado (peso: 0.35)        │
│  • Comunicacion con activos comprometidos (0.28)     │
│  • Patron de ubicacion sospechoso (0.22)            │
│  • Desviacion en biometria conductual (0.15)         │
├──────────────────────────────────────────────────────┤
│  Recomendaciones:                                     │
│  ┌────────────────────────────────────────────────┐  │
│  │  🔴 CAMBIAR DE POSICION AHORA               │  │ ← recomendacion alta
│  │  🟡 VERIFICAR CONTACTO AGT-4455             │  │ ← recomendacion media
│  │  🟢 MANTENER VIGILANCIA EN ZONA SUR         │  │ ← recomendacion baja
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Acciones:                                           │
│  [GENERAR REPORTE]  [ALERTAR COMANDO]  [IGNORAR]   │
└──────────────────────────────────────────────────────┘
```

---

## THREAT LEVEL INDICATOR

### Barra de Nivel de Amenaza
```dart
Stack(
  children: [
    Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    FractionallySizedBox(
      widthFactor: threatPercent / 100,
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: _threatColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: threatPercent > 70
              ? AppShadows.emergency
              : AppShadows.accentGlow,
        ),
      ),
    ),
    Positioned.fill(
      child: Center(
        child: Text('$threatPercent%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: AppTypography.titleSize,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ),
  ],
)
```

### Logica de Color:
| Nivel | Porcentaje | Color | Animacion |
|-------|-----------|-------|-----------|
| CRITICO | >80% | emergency (#FF2D2D) | Pulso cada 600ms |
| ALTO | 60-80% | threatOrange (#DD6B20) | Pulso cada 1000ms |
| MEDIO | 40-60% | accentAmber (#FFB020) | Estatico |
| BAJO | <40% | safe (#00E676) | Estatico |

### Tendencia:
- **↗ SUBIENDO:** textColor: emergency, icono arrow_upward
- **→ ESTABLE:** textColor: accentAmber, icono arrow_forward
- **↘ BAJANDO:** textColor: safe, icono arrow_downward

---

## CARDS DE RIESGO POR CATEGORIA

### Card Spec:
```dart
Container(
  width: 180,
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: _isHighRisk ? AppColors.emergency : AppColors.borderDefault,
      width: _isHighRisk ? 2 : 1,
    ),
    boxShadow: _isHighRisk ? AppShadows.emergency : AppShadows.card,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(_categoryIcon, color: _categoryColor, size: AppIconSize.sm),
        SizedBox(width: AppSpacing.sm),
        Text(categoryName, style: TextStyle(
          fontSize: AppTypography.labelSize,
          color: AppColors.textSecondary,
        )),
      ]),
      SizedBox(height: AppSpacing.sm),
      Text('$riskPercent%', style: TextStyle(
        fontSize: AppTypography.dataValueSize, // 28sp
        fontWeight: AppTypography.dataValueWeight,
        color: _riskColor,
      )),
      SizedBox(height: AppSpacing.xs),
      Row(children: [
        Icon(_trendIcon, color: _trendColor, size: 16),
        SizedBox(width: 4),
        Text(trendText, style: TextStyle(
          fontSize: AppTypography.chartLabelSize, // 11sp
          color: _trendColor,
          fontWeight: FontWeight.w600,
        )),
      ]),
    ],
  ),
)
```

### Categorias:
| Categoria | Icono | Color Base | Peso en Prediccion |
|-----------|-------|------------|---------------------|
| COMPORTAMIENTO | psychology | covertPurple (#805AD5) | 0.30 |
| UBICACION | location_on | accentCyan (#00D4FF) | 0.25 |
| COMUNICACIONES | forum | accentAmber (#FFB020) | 0.20 |
| BIOMETRICO | favorite | emergency (#FF2D2D) | 0.15 |
| TEMPORAL | schedule | meshGreen (#38A169) | 0.10 |

---

## GRAFICO DE PREDICCION

### Line Chart (usando fl_chart):
```dart
LineChart(
  LineChartData(
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) => FlLine(
        color: AppColors.borderSubtle,
        strokeWidth: 1,
      ),
    ),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Text(
            '${value.toInt()}h',
            style: TextStyle(
              fontSize: AppTypography.chartLabelSize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: AppTypography.chartLabelSize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border.all(color: AppColors.borderDefault),
    ),
    minX: -24,
    maxX: 72,
    minY: 0,
    maxY: 100,
    lineBarsData: [
      LineChartBarData(
        spots: historySpots + predictionSpots,
        isCurved: true,
        color: AppColors.accentCyan,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) =>
            FlDotCirclePainter(
              radius: spot.x > 0 ? 4 : 3,
              color: spot.x > 0
                  ? AppColors.threatOrange
                  : AppColors.accentCyan,
              strokeWidth: 2,
              strokeColor: AppColors.bgSurface,
            ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.accentCyan.withOpacity(0.1),
        ),
      ),
    ],
  ),
)
```

### Zonas de Riesgo en Grafico:
- **Background 0-40 (BAJO):** `AppColors.safe.withOpacity(0.05)`
- **Background 40-70 (MEDIO):** `AppColors.accentAmber.withOpacity(0.05)`
- **Background 70-100 (ALTO):** `AppColors.emergency.withOpacity(0.05)`

---

## FACTORES DE RIESGO

### Lista de Factores:
```dart
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: factors.length,
  itemBuilder: (context, index) {
    final factor = factors[index];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentCyan,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(factor.description, style: TextStyle(
            fontSize: AppTypography.bodySize,
            color: AppColors.textPrimary,
          )),
        ),
        SizedBox(width: AppSpacing.sm),
        Text('${(factor.weight * 100).toInt()}%', style: TextStyle(
          fontSize: AppTypography.labelSize,
          color: AppColors.textSecondary,
          fontFamily: AppTypography.fontFamilyMobile,
          letterSpacing: AppTypography.monoSpacing,
        )),
      ]),
    );
  },
)
```

---

## RECOMENDACIONES

### Recomendacion Card:
```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  margin: EdgeInsets.only(bottom: AppSpacing.sm),
  decoration: BoxDecoration(
    color: AppColors.bgElevated,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.left(
      BorderSide(
        color: _priorityColor, // emergency / amber / safe
        width: 4,
      ),
    ),
  ),
  child: Row(children: [
    Text(_priorityEmoji, style: TextStyle(fontSize: 20)), // 🔴🟡🟢
    SizedBox(width: AppSpacing.sm),
    Expanded(
      child: Text(recommendationText, style: TextStyle(
        fontSize: AppTypography.bodySize,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      )),
    ),
    Icon(Icons.arrow_forward_ios, color: AppColors.textDisabled, size: 16),
  ]),
)
```

### Niveles de Recomendacion:
| Prioridad | Emoji | Color | Accion Automatica |
|-----------|-------|-------|-------------------|
| ALTA | 🔴 | emergency | Alerta al comando + SOS recomendado |
| MEDIA | 🟡 | accentAmber | Notificacion push al agente |
| BAJA | 🟢 | safe | Registro en log, sin notificacion |

---

## CONFIGURACION (Dialogo)

```
┌──────────────────────────────────────────────┐
│  CONFIGURACION DE PREDICCION                  │
│  ┌────────────────────────────────────────┐  │
│  │ Sensibilidad:                          │  │
│  │  ██████████░░░░░░  ALTA              │  │ ← slider
│  │  (mayor sensibilidad = mas falsos    │  │
│  │   positivos)                          │  │
│  │ ───────────────────────────────────── │  │
│  │ Factores activos:                     │  │
│  │ [✔] Comportamiento (peso: 0.30)    │  │
│  │ [✔] Ubicacion (peso: 0.25)          │  │
│  │ [✔] Comunicaciones (peso: 0.20)     │  │
│  │ [ ] Biometrico (peso: 0.15)         │  │
│  │ [✔] Temporal (peso: 0.10)           │  │
│  │ ───────────────────────────────────── │  │
│  │ Horizonte de prediccion:               │  │
│  │ [72 horas ▾]                          │  │
│  │ ───────────────────────────────────── │  │
│  │ Notificaciones:                        │  │
│  │ [◉] Alerta cuando > 70%              │  │
│  │ [◉] Recomendaciones automaticas      │  │
│  └────────────────────────────────────────┘  │
│  [GUARDAR]  [CANCELAR]                      │
└──────────────────────────────────────────────┘
```

---

## CASOS DE USO

### Caso 1: Amenaza Inminente Detectada
```
1. Dashboard muestra Threat Level: 85% (CRITICO) - ↗ SUBIENDO
2. Grafico muestra prediccion de 92% en 48h
3. Factor principal: "Comunicacion con AGT-4455 (comprometido)"
4. Recomendacion: "CAMBIAR DE POSICION AHORA"
5. Agente toca "ALERTAR COMANDO"
6. → envia reporte automatico con factores y prediccion
7. → comando responde "APROBADO - Nueva posicion enviada"
```

### Caso 2: Patron de Comportamiento Anomalo
```
1. Threat Level: 58% (MEDIO) - → ESTABLE
2. Factor: "Desviacion 23% en ritmo de tecleo (3 dias)"
3. Comportamiento Risk: 62% (↗)
4. Agente selecciona factor → detalles:
   - "Cambio en velocidad promedio: 68->52 WPM"
   - "Errores aumentaron 15%"
5. Accion: "RE-CALIBRAR BIOMETRIA" (boton)
6. → inicia flujo de calibracion BehavioralBiometricsSetup
```

---

## ACCESIBILIDAD

- [x] Threat Level Bar: texto porcentual + color + descripcion ("ALTO")
- [x] Grafico: descripcion semantica "Grafico de prediccion, riesgo subiendo de 60% a 85%"
- [x] Cards de riesgo: contraste 4.5:1 minimo en textos
- [x] Recomendaciones: nivel indicado por emoji + texto + borde de color
- [x] Navegacion por teclado: Tab entre cards, Enter para seleccionar
- [x] TalkBack/VoiceOver: lectura de nivel de amenaza y tendencia
- [x] Haptic feedback: emergency vibration cuando threat > 80%

---

## ACCIONES Y NOTIFICACIONES

### Alertas Push Automaticas:
| Threat Level | Notificacion | Frecuencia |
|--------------|--------------|-------------|
| >70% | "⚠ AMENAZA ALTA DETECTADA" | Inmediata |
| >85% | "🔴 AMENAZA CRITICA - ACCION REQUERIDA" | Inmediata + repetir cada 5min |
| Tendencia ↗ | "📈 Riesgo en aumento" | Cada 6 horas |

### Integracion con SOS:
- Si Threat Level > 90% por mas de 30 minutos
- Boton SOS cambia a "ALERTA AMENAZA CRITICA"
- Al presionar: envia prediccion completa + datos actuales
- Comando recibe contexto predictivo adicional

---

## IMPLEMENTACION TECNICA

**Paquetes Flutter recomendados:**
- `fl_chart: ^0.65.0` - para graficos de linea
- `syncfusion_flutter_charts: ^24.1.0` - alternativa mas robusta para dashboards
- `animations: ^2.0.0` - para transiciones suaves de datos

**Estructura de datos:**
```dart
class ThreatPrediction {
  double currentRisk;
  double predictedRisk;
  String trend; // 'rising', 'stable', 'falling'
  List<RiskFactor> factors;
  List<TimeSeriesPoint> history;
  List<TimeSeriesPoint> prediction;
  List<Recommendation> recommendations;
  DateTime generatedAt;
}

class RiskFactor {
  String description;
  double weight;
  String category; // comportamiento, ubicacion, etc.
}

class Recommendation {
  String text;
  Priority priority; // alta, media, baja
  bool actionable;
}
```

**Actualizacion de datos:**
- **Tiempo real:** cada 5 minutos (app abierta)
- **Background:** cada 30 minutos (via background fetch)
- **Trigger manual:** pull-to-refresh en dashboard
