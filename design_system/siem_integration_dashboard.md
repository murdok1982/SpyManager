# SpyManager IMC — SIEM Integration Dashboard Design
Agente: DISENO | Fecha: 2026-05-03

---

## VISION GENERAL

Dashboard de integracion con sistemas SIEM (Security Information and Event Management) para monitoreo centralizado, correlacion de eventos y deteccion de intrusiones en tiempo real.

**Objetivo:** Proporcionar una vista unificada de la postura de seguridad, eventos criticos y cumplimiento de normativas de ciberseguridad.

---

## LAYOUT PRINCIPAL

```
┌──────────────────────────────────────────────────────┐
│  AppBar [SIEM INTEGRATION]  [⚙ CONFIG]  [🔄 SYNC]  │
│  color: bgSurface | border bottom: borderSubtle 1dp   │
├──────────────────────────────────────────────────────┤
│  Estado de Conexion SIEM:                              │
│  ┌────────────────────────────────────────────────┐  │
│  │  ● CONECTADO A: Splunk Enterprise             │  │ ← green dot
│  │  Ultimo evento: hace 23 segundos               │  │
│  │  Eventos/seg: 142  |  Ancho de banda: 1.2MB/s│  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Row de 4 Metric Cards (horizontal scroll si < 1200dp):│
│  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐  │
│  │ EVENTOS  ││ ALERTAS  ││ CRITICOS││ BLOQUEOS │  │
│  │  1,284   ││   23     ││    7     ││   12     │  │ ← data values
│  │ ↗ +12%   ││ → ESTABLE││ ↗ +2    ││ ← -3    │  ← trends
│  └──────────┘└──────────┘└──────────┘└──────────┘  │
├──────────────────────────────────────────────────────┤
│  Row: Grafico de Eventos (60%) + Alertas Recientes (40%)│
│  ┌─────────────────────────┐ ┌──────────────────┐  │
│  │  EVENTOS POR HORA       │ │ ALERTAS RECIENTES│  │
│  │  300 ┤         █      │ │ ● CRIT: AGT-7734 │  │
│  │      │    █    █  █   │ │ ● WARN: Firewall │  │
│  │  150 ┤ █  █  █  █   │ │ ● INFO: Login OK │  │
│  │      │ █  █  █  █  █│ │ ● CRIT: DDoS    │  │
│  │    0 └─────────────────┤ │ ● WARN: AuthFail │  │
│  │      0h 4h 8h 12h 16h │ └──────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Log de Eventos (expansible, 200dp collapsed):         │
│  ┌────────────────────────────────────────────────┐  │
│  │ 2026-05-03 14:23:07Z  AGT-7734 LOGIN_SUCCESS │  │
│  │ 2026-05-03 14:22:15Z  FIREWALL DENY 10.0.0.44│  │
│  │ 2026-05-03 14:21:03Z  AGT-2281 REPORT_SENT   │  │
│  │ [VER LOG COMPLETO...]                            │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Acciones:                                           │
│  [GENERAR REPORTE CEF]  [ENVIAR ALERTA]  [CONFIG]   │
└──────────────────────────────────────────────────────┘
```

---

## METRIC CARDS

### Card Spec:
```dart
Container(
  width: 160,
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: isCritical ? AppColors.emergency : AppColors.borderDefault,
      width: isCritical ? 2 : 1,
    ),
    boxShadow: isCritical ? AppShadows.emergency : AppShadows.card,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(cardTitle, style: TextStyle(
        fontSize: AppTypography.labelSize,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      )),
      SizedBox(height: AppSpacing.sm),
      Text(value.toString(), style: TextStyle(
        fontSize: AppTypography.dataValueSize, // 28sp
        fontWeight: AppTypography.dataValueWeight,
        color: _valueColor,
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

### Colores de Metricas:
| Metrica | Color Valor | Color Tendencia |
|---------|--------------|----------------|
| EVENTOS | accentCyan | segun tendencia |
| ALERTAS | accentAmber | igual |
| CRITICOS | emergency | igual |
| BLOQUEOS | safe | inverso (↗ es malo) |

---

## GRAFICO DE EVENTOS (Timeline)

### Bar Chart (usando fl_chart):
```dart
BarChart(
  BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: 300,
    barTouchData: BarTouchData(enabled: true),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final hours = ['0h', '4h', '8h', '12h', '16h', '20h'];
            return Text(hours[value.toInt()], style: TextStyle(
              fontSize: AppTypography.chartLabelSize,
              color: AppColors.textSecondary,
            ));
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
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
    barGroups: eventData.map((data) => BarChartGroupData(
      x: data.hour,
      barRods: [
        BarChartRodData(
          toY: data.count,
          color: data.isCritical
              ? AppColors.emergency
              : AppColors.accentCyan,
          width: 16,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    )).toList(),
  ),
)
```

### Leyenda:
- **Barra cyan:** eventos normales
- **Barra roja:** eventos criticos
- **Altura maxima:** 300 eventos/hora

---

## ALERTAS RECIENTES

### Lista de Alertas:
```dart
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: alerts.length,
  itemBuilder: (context, index) {
    final alert = alerts[index];
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: AppColors.borderSubtle, width: 1)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: alert.severity == 'CRIT'
                ? AppColors.emergency
                : alert.severity == 'WARN'
                    ? AppColors.accentAmber
                    : AppColors.safe,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.title, style: TextStyle(
                fontSize: AppTypography.bodySize,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
              Text(alert.source, style: TextStyle(
                fontSize: AppTypography.labelSize,
                color: AppColors.textSecondary,
              )),
            ],
          ),
        ),
        Text(alert.timeAgo, style: TextStyle(
          fontSize: AppTypography.chartLabelSize,
          color: AppColors.textDisabled,
          fontFamily: AppTypography.fontFamilyMobile,
          letterSpacing: AppTypography.monoSpacing,
        )),
      ]),
    );
  },
)
```

### Niveles de Severidad:
| Severidad | Color | Icono | Accion Automatica |
|-----------|-------|-------|-------------------|
| CRIT | emergency | error | Notificacion + SMS al comando |
| WARN | accentAmber | warning | Notificacion push |
| INFO | safe | info | Solo log, sin notificacion |

---

## LOG DE EVENTOS

### Entrada de Log:
```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(color: _actionColor, width: 2),
      bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
    ),
  ),
  child: Row(children: [
    Text(event.timestamp, style: TextStyle(
      fontFamily: AppTypography.fontFamilyMobile,
      fontSize: AppTypography.labelSize,
      color: AppColors.textDisabled,
      letterSpacing: AppTypography.monoSpacing,
    )),
    SizedBox(width: AppSpacing.sm),
    Expanded(
      child: Text('$agentId ${event.action}', style: TextStyle(
        fontSize: AppTypography.bodySize,
        color: _actionColor,
        fontWeight: FontWeight.w600,
      )),
    ),
    if (event.isBlocked)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.emergency.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text('BLOQUEADO', style: TextStyle(
          fontSize: AppTypography.microSize, // 10sp
          color: AppColors.emergency,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        )),
      ),
  ]),
)
```

### Colores de Accion:
| Accion | Color |
|--------|-------|
| LOGIN_SUCCESS / REPORT_SENT | safe |
| AUTH_FAILED / ACCESS_DENIED | emergency |
| FIREWALL_DENY / DDoS | accentAmber |
| SYSTEM / CONFIG | textSecondary |

---

## CONFIGURACION SIEM

### Dialogo de Configuracion:
```
┌──────────────────────────────────────────────┐
│  CONFIGURACION SIEM                           │
│  ┌────────────────────────────────────────┐  │
│  │ SIEM Conectado: [Splunk ▾]            │  │
│  │ Endpoint: [tcp://10.0.0.100:9997   ] │  │
│  │ Formato: [CEF ▾]                      │  │
│  │ ───────────────────────────────────── │  │
│  │ Eventos a enviar:                      │  │
│  │ [✔] Autenticacion                    │  │
│  │ [✔] Reportes de inteligencia          │  │
│  │ [✔] Fallos de firewall               │  │
│  │ [ ] Trafico normal (ruido)            │  │
│  │ ───────────────────────────────────── │  │
│  │ Frecuencia de envio:                   │  │
│  │ [Tiempo real ▾]                       │  │
│  │ (alternativas: 1 min, 5 min, 15 min) │  │
│  │ ───────────────────────────────────── │  │
│  │ Nivel de detalle:                      │  │
│  │ [COMPLETO ▾]                         │  │
│  └────────────────────────────────────────┘  │
│  [PROBAR CONEXION]  [GUARDAR]  [CANCELAR]   │
└──────────────────────────────────────────────┘
```

---

## EXPORTACION DE REPORTES

### Formatos Soportados:
- **CEF (Common Event Format):** estandar para SIEMs
- **JSON:** para integracion con APIs modernas
- **Syslog:** formato RFC 5424
- **PDF Report:** reporte ejecutivo automatico

### Reporte Automatico:
- Diario: resumen de eventos, alertas y bloqueos
- Semanal: analisis de tendencias y anomalias
- Mensual: cumplimiento y postura de seguridad

---

## CASOS DE USO

### Caso 1: Intrusion Detectada
```
1. SIEM Dashboard muestra "CRITICOS: 7" (↗ +2)
2. Grafico muestra pico de 280 eventos/hora (barra roja)
3. Alerta reciente: "● CRIT: Intento de intrusión AGT-7734"
4. Log: "14:23:07Z AGT-7734 AUTH_FAILED 3 intentos"
5. Accion automatica: IP 10.0.0.44 BLOQUEADA
6. Agente toca "ENVIAR ALERTA" → notificacion al comando
```

### Caso 2: DDoS en Curso
```
1. MetricCard "EVENTOS" muestra 1,284 (↗ +12%)
2. Grafico: barras rojas continuas > 200/hora
3. Alertas: "● CRIT: DDoS detectado desde 45.33.12.x"
4. Log: multiples "FIREWALL_DENY" en segundos
5. Accion: "ACTIVAR PROTECCION DDoS" (boton)
6. → redirige trafico via CDN, mitigacion automatica
```

---

## ACCESIBILIDAD

- [x] MetricCards: valor numerico grande (28sp) + texto descriptivo + tendencia
- [x] Grafico: descripcion semantica "Eventos por hora, pico de 280 a las 12h"
- [x] Alertas: nivel indicado por color + texto + icono
- [x] Log entries: timestamp mono, accion con color + texto
- [x] Contraste 4.5:1 en todos los textos
- [x] Navegacion por teclado: Tab entre cards, Enter para seleccionar
- [x] TalkBack/VoiceOver: lectura de metricas y estados

---

## IMPLEMENTACION TECNICA

**Paquetes Flutter recomendados:**
- `fl_chart: ^0.65.0` - para graficos de barras y lineas
- `syncfusion_flutter_charts: ^24.1.0` - alternativa enterprise
- `intl: ^0.18.1` - para formateo de timestamps

**Estructura de datos:**
```dart
class SIEMEvent {
  DateTime timestamp;
  String agentId;
  String action;
  String sourceIp;
  Severity severity;
  bool isBlocked;
  Map<String, dynamic> metadata;
}

class SIEMMetric {
  String title;
  int value;
  double trendPercent;
  String trendDirection; // 'rising', 'stable', 'falling'
}

enum Severity { CRIT, WARN, INFO }
```

**Conexion SIEM:**
- **Protocolos:** TCP/TLS para envio de eventos
- **Formato:** CEF (Common Event Format) por defecto
- **Reintentos:** 3 intentos con backoff exponencial
- **Queue local:** max 10,000 eventos sin conexion

---

## INTEGRACION CON OTROS SISTEMAS

### STANAG 5516/Link 16 (referencia):
- Exportacion de eventos en formato compatible con sistemas militares
- Mapping de severidades a clasificaciones militares
- Encripcion adicional para transmision en redes tácticas

### Honeypot Integration:
- Eventos de honeypot aparecen como "HONEYPOT_ALERT"
- Color: honeypotYellow con bordes especiales
- Accion: "INVESTIGAR HONEYPOT" (boton amarillo)

### Behavioral Biometrics:
- Eventos de anomalia biometrica integrados
- "BIOMETRIC_ANOMALY" con score de desviacion
- Accion: "RE-CALIBRAR" o "BLOQUEAR DISPOSITIVO"
