# SpyManager IMC — STANAG 5516/Link 16 Export UI Design
Agente: DISENO | Fecha: 2026-05-03

---

## VISION GENERAL

Interfaz para exportar datos de inteligencia en formatos compatibles con estándares militares NATO STANAG 5516 (Link 16) para intercambio táctico de información en tiempo real.

**Objetivo:** Permitir la exportación de tracks, contactos, amenazas y datos de inteligencia en formato Link 16 para integración con sistemas de mando y control (C2), AWACS, y plataformas tácticas aliadas.

---

## LAYOUT PRINCIPAL

```
┌──────────────────────────────────────────────────────┐
│  AppBar [EXPORT LINK 16 / STANAG 5516]  [⚙ CONFIG] │
│  color: bgSurface | border bottom: borderDefault 1dp │
├──────────────────────────────────────────────────────┤
│  Estado de Compatibilidad:                              │
│  ┌────────────────────────────────────────────────┐  │
│  │  ✓ COMPATIBLE CON: AWACS, E-3A, Sistemas C2  │  │ ← green
│  │  Formato: Link 16 J3.2/J14.0                  │  │
│  │  Encripcion: AES-256 + NATO Secret           │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Selección de Datos a Exportar:                        │
│  ┌────────────────────────────────────────────────┐  │
│  │  [✔] Tracks Activos (12 contactos)            │  │
│  │  [✔] Amenazas Detectadas (3 items)            │  │
│  │  [✔] Perfiles de Objetivos (5 items)          │  │
│  │  [ ] Historial de Movimientos (ruido)         │  │
│  │  [✔] Inteligencia HUMINT (8 reportes)        │  │
│  │  [ ] Metadatos Técnicos (grande)             │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Configuración de Exportación:                          │
│  ┌────────────────────────────────────────────────┐  │
│  │  Tipo de Mensaje: [J3.2 Track Report ▾]      │  │
│  │  Nivel de Clasificación: [NATO SECRET ▾]     │  │
│  │  Cifrado: [AES-256 + Link 16 ▾]              │  │
│  │  Canales: [HF ▾] [UHF ▾] [Satcom ▾]         │  │
│  │  ─────────────────────────────────────────── │  │
│  │  Frecuencia de actualización:                  │  │
│  │  ████████░░░░░░░░  2 Hz (cada 500ms)        │  │ ← slider
│  │  ─────────────────────────────────────────── │  │
│  │  Opciones:                                    │  │
│  │  [✔] Compresión de datos (Lempel-Ziv)        │  │
│  │  [✔] Checksum automático (CRC-32)            │  │
│  │  [ ] Modo stealth (reduce footprint)          │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Vista Previa de Payload (colapsable, 150dp):           │
│  ┌────────────────────────────────────────────────┐  │
│  │  0x00: 4A 33 02 1F 00 00 00 00 00 00 00  │  │ ← hex preview
│  │  0x0C: 00 00 00 00 00 00 00 00 00 00 00  │  │
│  │  ...                                         │  │
│  │  Tamaño estimado: 2.4 KB / mensaje            │  │
│  │  [COPIAR HEX] [VER TABLA COMPLETA]           │  │
│  └────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────┤
│  Acciones:                                           │
│  [GENERAR PAYLOAD]  [TRANSMITIR AHORA]  [CANCELAR] │
└──────────────────────────────────────────────────────┘
```

---

## COMPATIBILIDAD (Header)

### Compatibility Indicator:
```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.safe.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.safe, width: 1.5),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.check_circle, color: AppColors.safe, size: AppIconSize.md),
        SizedBox(width: AppSpacing.sm),
        Text('COMPATIBLE CON: AWACS, E-3A, Sistemas C2',
          style: TextStyle(
            fontSize: AppTypography.titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.safe,
            letterSpacing: 1.0,
          )),
      ]),
      SizedBox(height: AppSpacing.sm),
      Text('Formato: Link 16 J3.2/J14.0',
        style: TextStyle(fontSize: AppTypography.labelSize, color: AppColors.textSecondary)),
      Text('Encripcion: AES-256 + NATO Secret',
        style: TextStyle(fontSize: AppTypography.labelSize, color: AppColors.textSecondary)),
    ],
  ),
)
```

---

## SELECCION DE DATOS

### Data Source Checkbox List:
```dart
ListView(
  shrinkWrap: true,
  children: dataSources.map((source) => CheckboxListTile(
    value: source.isSelected,
    onChanged: (v) => toggleDataSource(source, v),
    activeColor: AppColors.accentCyan,
    checkColor: AppColors.textOnAccent,
    title: Text(source.name,
      style: TextStyle(
        fontSize: AppTypography.bodySize,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      )),
    subtitle: Text('${source.count} ${source.type}',
      style: TextStyle(
        fontSize: AppTypography.labelSize,
        color: AppColors.textSecondary,
      )),
    secondary: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getClassColor(source.classification).withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: _getClassColor(source.classification)),
      ),
      child: Text(source.classification, style: TextStyle(
        fontSize: AppTypography.microSize, // 10sp
        color: _getClassColor(source.classification),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      )),
    ),
    controlAffinity: ListTileControlAffinity.leading,
  )).toList(),
)
```

### Clasificaciones NATO:
| Nivel | Color | Border | Texto |
|-------|-------|--------|--------|
| UNCLASSIFIED | classUnclassified | classUnclassified | "U // NATO UNCLAS" |
| RESTRICTED | accentAmber | accentAmber | "R // NATO RESTR" |
| CONFIDENTIAL | accentCyan | accentCyan | "C // NATO CONF" |
| SECRET | classSecret | classSecret | "S // NATO SECRET" |
| TOP SECRET | classTopSecretGold | classTopSecretGold | "TS // NATO TOP SECRET" |

---

## CONFIGURACION DE EXPORTACION

### Message Type Picker:
```dart
DropdownButtonFormField<String>(
  value: selectedMessageType,
  decoration: InputDecoration(
    labelText: 'Tipo de Mensaje',
    labelStyle: TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.bgElevated,
    border: OutlineInputBorder(
      borderRadius: AppRadius.input,
      borderSide: BorderSide(color: AppColors.borderDefault),
    ),
  ),
  items: messageTypes.map((type) => DropdownMenuItem(
    value: type.code,
    child: Text('${type.code} ${type.name}', style: TextStyle(
      fontSize: AppTypography.bodySize,
      color: AppColors.textPrimary,
      fontFamily: AppTypography.fontFamilyMobile,
      letterSpacing: AppTypography.monoSpacing,
    )),
  )).toList(),
  onChanged: (v) => updateMessageType(v!),
)
```

### Link 16 Message Types:
| Codigo | Nombre | Descripcion |
|--------|---------|-------------|
| J3.2 | Track Report | Reporte de pista (contacto) |
| J14.0 | Airborne Track | Pista aerea |
| J18.0 | Intelligence Data | Datos de inteligencia |
| J28.0 | Electronic Warfare | Guerra electronica |
| J36.0 | HUMINT Report | Reporte HUMINT |

### Update Frequency Slider:
```dart
SliderTheme(
  data: SliderThemeData(
    activeTrackColor: AppColors.accentCyan,
    inactiveTrackColor: AppColors.bgElevated,
    thumbColor: AppColors.accentCyan,
    trackHeight: AppSpacing.sliderTrackHeight,
    thumbShape: RoundSliderThumbShape(
      enabledThumbRadius: AppSpacing.sliderThumbSize / 2,
    ),
  ),
  child: Slider(
    value: updateFrequency,
    min: 0.1,  // 0.1 Hz (10s)
    max: 10.0, // 10 Hz (100ms)
    divisions: 99,
    label: '${updateFrequency.toStringAsFixed(1)} Hz (cada ${(1000/updateFrequency).toInt()}ms)',
    onChanged: (v) => updateFrequency = v,
  ),
)
```

### Channel Selection (Multi-select Chips):
```dart
Wrap(
  spacing: AppSpacing.sm,
  children: channels.map((ch) => FilterChip(
    label: Text(ch.name, style: TextStyle(
      fontSize: AppTypography.labelSize,
      color: ch.isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
    )),
    selected: ch.isSelected,
    selectedColor: AppColors.accentCyan,
    backgroundColor: AppColors.bgElevated,
    side: BorderSide(
      color: ch.isSelected ? AppColors.accentCyan : AppColors.borderDefault,
    ),
    onSelected: (v) => toggleChannel(ch, v),
  )).toList(),
)
```

---

## VISTA PREVIA DE PAYLOAD

### Hex Preview Container:
```dart
Container(
  height: 150,
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.bgElevated,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.borderDefault),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('PAYLOAD HEXDUMP:', style: TextStyle(
          fontSize: AppTypography.labelSize,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        )),
        Spacer(),
        Text('Tamaño estimado: 2.4 KB / mensaje', style: TextStyle(
          fontSize: AppTypography.chartLabelSize, // 11sp
          color: AppColors.textSecondary,
        )),
      ]),
      SizedBox(height: AppSpacing.sm),
      Expanded(
        child: SingleChildScrollView(
          child: Text(hexDump, style: TextStyle(
            fontFamily: AppTypography.fontFamilyMobile,
            fontSize: AppTypography.chartLabelSize,
            color: AppColors.accentCyan,
            letterSpacing: AppTypography.monoSpacing,
            height: AppTypography.lineHeightTight,
          )),
        ),
      ),
    ],
  ),
)
```

---

## ACCIONES (Botones)

### Generate Payload Button:
```dart
ElevatedButton(
  onPressed: generatePayload,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accentCyan,
    foregroundColor: AppColors.textOnAccent,
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
  ),
  child: Text('GENERAR PAYLOAD',
    style: TextStyle(
      fontFamily: AppTypography.fontFamilyMobile,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
    )),
)
```

### Transmit Now Button:
```dart
ElevatedButton(
  onPressed: transmitNow,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.safe,
    foregroundColor: AppColors.textOnAccent,
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
  ),
  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.send, size: AppIconSize.sm),
    SizedBox(width: AppSpacing.sm),
    Text('TRANSMITIR AHORA',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      )),
  ]),
)
```

### Cancel Button:
```dart
TextButton(
  onPressed: cancelExport,
  child: Text('CANCELAR',
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: AppTypography.labelSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    )),
)
```

---

## CONFIGURACION AVANZADA (Dialogo)

```
┌──────────────────────────────────────────────┐
│  CONFIGURACION AVANZADA LINK 16                 │
│  ┌────────────────────────────────────────┐  │
│  │ Encripcion:                              │  │
│  │ [✔] AES-256 (estándar)                │  │
│  │ [ ] AES-128 (legacy)                   │  │
│  │ [ ] Null Encripcion (solo test)         │  │
│  │ ───────────────────────────────────── │  │
│  │ Compresión:                              │  │
│  │ [✔] Lempel-Ziv (LZ77)                 │  │
│  │ [ ] Deflate (gzip)                      │  │
│  │ [ ] Sin compresión                      │  │
│  │ ───────────────────────────────────── │  │
│  │ Checksum:                                │  │
│  │ [✔] CRC-32                             │  │
│  │ [ ] Fletcher-16                         │  │
│  │ [ ] Sin checksum                        │  │
│  │ ───────────────────────────────────── │  │
│  │ Límites de tamaño:                       │  │
│  │ Max payload: [2.4 KB ▾]                │  │
│  │ Max mensajes/burst: [10 ▾]              │  │
│  │ ───────────────────────────────────── │  │
│  │ Modo:                                   │  │
│  │ [◉] Normal (completo)                  │  │
│  │ [ ] Stealth (reduce footprint)          │  │
│  │ [ ] ECCM (Electronic Counter-Counter)   │  │
│  └────────────────────────────────────────┘  │
│  [GUARDAR]  [CANCELAR]                        │
└──────────────────────────────────────────────┘
```

---

## CASOS DE USO

### Caso 1: Exportar Track de Contacto Enemigo
```
1. Agente identifica contacto Hostil: "OBJ-7734"
2. Abre STANAG Export UI
3. Selecciona: [✔] Tracks Activos (incluye OBJ-7734)
4. Configura: Tipo J3.2, Clasificación NATO SECRET
5. Frecuencia: 2 Hz (actualización cada 500ms)
6. Tap "GENERAR PAYLOAD"
7. Vista previa muestra hex dump de 2.4 KB
8. Tap "TRANSMITIR AHORA"
9. → Enviado a AWACS via UHF
10. → Toast: "PAYLOAD ENVIADO A AWACS (2.4 KB)"
```

### Caso 2: Reporte HUMINT para C2
```
1. Agente tiene reporte HUMINT: "RPT-8821"
2. Abre STANAG Export
3. Selecciona: [✔] Inteligencia HUMINT (incluye RPT-8821)
4. Tipo: J36.0 HUMINT Report
5. Clasificación: NATO CONFIDENTIAL
6. Canal: Satcom (para larga distancia)
7. Tap "TRANSMITIR AHORA"
8. → Enviado a Sistema C2 via Satcom
9. → Confirmación: "HUMINT ENVIADO A C2"
```

---

## ACCESIBILIDAD

- [x] Colores de clasificación NATO tienen texto + código + color de borde
- [x] Checkbox tienen labels claras ("Tracks Activos (12 contactos)")
- [x] Dropdown para message type tiene descripción en cada item
- [x] Hex dump usa monospace (RobotoMono) para legibilidad
- [x] Contraste 4.5:1 en textos de configuración
- [x] Botones tienen descripción clara ("GENERAR PAYLOAD", no "OK")
- [x] Haptic feedback al generar y transmitir payload
- [x] TalkBack/VoiceOver: lectura de configuración y estado

---

## IMPLEMENTACION TECNICA

**Paquetes Flutter recomendados:**
- `hex: ^0.2.0` - para conversión a hexadecimal
- `encrypt: ^5.0.3` - para AES-256
- `archive: ^3.4.9` - para compresión Lempel-Ziv

**Estructura de datos:**
```dart
class Link16Message {
  String messageType; // J3.2, J14.0, etc.
  String classification; // NATO SECRET, etc.
  String encryption; // AES-256
  double frequency; // Hz
  List<String> channels; // HF, UHF, Satcom
  List<int> payload; // raw bytes
  DateTime generatedAt;
}

class STANAGExportConfig {
  bool useCompression;
  String compressionType; // LZ77, Deflate
  bool useChecksum;
  String checksumType; // CRC-32, Fletcher-16
  int maxPayloadSize; // KB
  int maxBurstMessages;
  bool stealthMode;
}
```

**Generación de Payload:**
1. Recopilar datos seleccionados
2. Serializar a formato binario Link 16
3. Aplicar encripción AES-256 si está habilitado
4. Comprimir con LZ77 si está habilitado
5. Calcular checksum CRC-32
6. Convertir a hexadecimal para vista previa
7. Transmitir via canal seleccionado

**Canales de Transmisión:**
- **HF (High Frequency):** 3-30 MHz, larga distancia
- **UHF (Ultra High Frequency):** 300-3000 MHz, línea de vista
- **Satcom (Satellite Communication):** Banda L/S, global
- **VHF (Very High Frequency):** 30-300 MHz, corta distancia

---

## REFERENCIA MILITAR (Stanag 5516)

**Link 16 Features:**
- Data rate: 28.8 kbps o 238 kbps (auspicioso)
- Frecuencia: 960-1215 MHz (banda L)
- Acceso múltiple: TDMA (Time Division Multiple Access)
- Nodos: hasta 128 participantes por red
- Salto de frecuencia: 51,000 hops/segundo
- Encripcion: AES-256 o algoritmo nacional

**Message Formats Soportados:**
- **J3.2:** Track Report (hasta 10 tracks/mensaje)
- **J14.0:** Airborne Track (posición, velocidad, identificación)
- **J18.0:** Intelligence Data (HUMINT, IMINT, SIGINT)
- **J28.0:** Electronic Warfare (EMA, ESM)
- **J36.0:** HUMINT Report (agentes, fuentes, evaluación)

**Notas de Implementación:**
- El estándar STANAG 5516 es clasificado NATO SECRET
- Implementación requiere acuerdo de licenciamiento con NATO
- Pruebas deben realizarse en entorno aislado (no producción)
- Export control: ITAR (International Traffic in Arms Regulations)
