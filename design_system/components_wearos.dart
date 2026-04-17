// =============================================================================
// SpyManager IMC — Componentes WearOS Flutter
// Agente: DISENO | Fecha: 2026-04-17
// Framework: Flutter for WearOS (wear package) o Jetpack Compose Wear
// Nota: especificaciones validas para ambos. Se documenta Flutter primero,
//       equivalentes Compose al final de cada seccion.
// =============================================================================
//
// CONSTRAINT GLOBAL WEAROS:
//   - NO scroll en ninguna pantalla
//   - Tap targets MINIMO 48dp (uso con guantes)
//   - Todo el contenido debe caber en una pantalla
//   - Soporte formas: circular (Samsung Galaxy Watch, Pixel Watch) y rectangular
//   - Paleta identica al mobile pero con ajustes de densidad
//   - Fuente: RobotoCondensed para mayor compresion horizontal

// =============================================================================
// WATCHFACE DIMENSIONS
// Circular: asume pantalla 450x450dp logicos (Pixel Watch 2 = 41mm)
//   Zona segura circular: radio 180dp centrado (evita esquinas oscuras)
// Rectangular: asume 192x192dp (Galaxy Watch 6 Classic)
//   Safe inset: 8dp todos los lados
// =============================================================================

import 'tokens.dart';

class WearDimensions {
  WearDimensions._();

  // Circular
  static const double circularDiameter = 450.0;
  static const double circularSafeRadius = 180.0;
  static const double circularCenter = 225.0;

  // Rectangular
  static const double rectWidth  = 192.0;
  static const double rectHeight = 192.0;
  static const double rectSafeInset = 8.0;

  // Tap target
  static const double tapTarget = 48.0;

  // Zonas predefinidas para watchface circular (en dp desde el centro)
  static const double zoneCenterRadius = 60.0;    // zona central principal
  static const double zoneMiddleRadius = 120.0;   // zona media
  static const double zoneEdgeRadius   = 160.0;   // zona borde (evitar)
}

// =============================================================================
// 1. AGENT STATUS FACE — Watchface principal
// =============================================================================
//
// WIREFRAME CIRCULAR:
//
//         ┌─────────────────┐
//      ┌──┤  2026-04-17     ├──┐
//     /   │  14:23          │   \
//    │    ├─────────────────┤    │
//    │    │                 │    │
//    │    │   AGT-7734      │    │  ← 24sp bold, centrado
//    │    │                 │    │
//    │    │   [ ACTIVE ]    │    │  ← badge status, 20sp
//    │    │                 │    │
//    │    │   ♥ 87 bpm      │    │  ← dato vital, 18sp
//    │    │                 │    │
//    │    └────── ● ────────┘    │  ← indicador conexion
//     \                         /
//      └─────────────────────────┘
//
// WIREFRAME RECTANGULAR:
//
// ┌────────────────────────┐
// │ 14:23          AGT-7734│  ← hora y id, 18sp
// ├────────────────────────┤
// │      [ ACTIVE ]        │  ← status centrado, 22sp
// │       ♥ 87 bpm         │  ← biometrico, 18sp
// │  ● CONN  |  GPS: ON    │  ← status bar, 14sp
// └────────────────────────┘
//
// Flutter WearOS spec:
//
// Scaffold(
//   backgroundColor: AppColors.bgBase,
//   body: CustomPaint(
//     painter: WatchfacePainter(),  // dibuja borde sutil para forma circular
//     child: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(agentId,
//             style: TextStyle(
//               fontFamily: AppTypography.fontFamilyWearOS,
//               fontSize: AppTypography.wearHeadlineSize, // 22sp
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//               letterSpacing: AppTypography.monoSpacing,
//             ),
//           ),
//           SizedBox(height: AppSpacing.sm),
//           WearStatusBadge(status: agentStatus),
//           SizedBox(height: AppSpacing.wearSm),
//           WearBiometricRow(bpm: bpm),
//           SizedBox(height: AppSpacing.wearSm),
//           WearConnectionDot(connected: isConnected),
//         ],
//       ),
//     ),
//   ),
// )
//
// Hora: Positioned en top-center (circular) o top-left (rectangular)
//   fontSize: 18sp, color: AppColors.textSecondary, fontFamily: RobotoCondensed
//
// WearStatusBadge:
//   Igual que mobile StatusBadge pero:
//   padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6)
//   fontSize: AppTypography.wearBodySize (18sp)
//   minWidth: 120dp, height: 36dp
//   COMPROMISED: borde pulsante cada 800ms
//
// Borde watchface (forma circular, CustomPainter):
//   Color: segun estado del agente
//   ACTIVE      → AppColors.safe.withOpacity(0.3), strokeWidth: 2dp
//   DARK        → AppColors.borderSubtle, strokeWidth: 1dp
//   COMPROMISED → AppColors.emergency, strokeWidth: 3dp + pulso opacity 1.0->0.3

// =============================================================================
// 2. EMERGENCY SOS — Pantalla de emergencia WearOS
// =============================================================================
//
// ACTIVACION: Long press corona (poder button) por 1.5 segundos
// Esta pantalla OCUPA TODA LA PANTALLA. No hay elementos no-SOS visibles.
//
// WIREFRAME CIRCULAR:
//
//         ┌─────────────────┐
//        /                   \
//       │   ████████████████  │  ← fondo ROJO opaco #200000
//       │          ⚠          │  ← icono 48dp, color blanco
//       │                     │
//       │    EMERGENCIA       │  ← 28sp bold blanco
//       │                     │
//       │  ┌─────────────┐   │
//       │  │  ACTIVAR    │   │  ← boton rojo borde blanco, 56dp alto
//       │  │    SOS      │   │     tap target FULL 48dp
//       │  └─────────────┘   │
//       │                     │
//       │  [ Cancelar ]       │  ← texto solo, 16sp, textSecondary
//        \                   /
//         └─────────────────┘
//
// spec:
//   Scaffold background: Color(0xFF200000)
//   Eliminado border de watchface
//
// Boton ACTIVAR SOS:
//   Container(
//     height: 56,
//     width: double.infinity,  // circular: 70% del ancho seguro
//     decoration: BoxDecoration(
//       color: AppColors.emergency,
//       borderRadius: BorderRadius.circular(AppRadius.wearCard),
//       border: Border.all(color: Colors.white, width: 2),
//       boxShadow: AppShadows.emergency,
//     ),
//     child: Center(
//       child: Text('ACTIVAR SOS',
//         style: TextStyle(
//           fontFamily: AppTypography.fontFamilyWearOS,
//           fontSize: AppTypography.wearBodySize,  // 18sp
//           fontWeight: FontWeight.w900,
//           color: Colors.white,
//           letterSpacing: 2.0,
//         ),
//       ),
//     ),
//   )
//   onTap: HapticFeedback.heavyImpact() + activar SOS en mobile via BLE
//
// Cancelar:
//   GestureDetector > Text('Cancelar')
//   minHeight: 44dp (tap target)
//   color: AppColors.textSecondary
//
// Post-activacion:
//   Background permanece rojo
//   Texto cambia a "SOS ACTIVO"
//   Parpadeo del borde cada 500ms
//   Boton cambia a "DESACTIVAR SOS" (mismo estilo, diferente texto)

// =============================================================================
// 3. QUICK REPORT — Reporte rapido 4 botones
// =============================================================================
//
// Acceso: Swipe LEFT desde watchface principal
// REGLA: 1 tap = reporte enviado + confirmacion haptica. Sin formulario.
//
// WIREFRAME CIRCULAR:
//
//         ┌─────────────────┐
//        /                   \
//       │  REPORTE RAPIDO     │  ← 16sp, textSecondary, top
//       │                     │
//       │   ┌──────┐ ┌──────┐ │
//       │   │      │ │      │ │
//       │   │ SAFE │ │COMP. │ │  ← 2x2 grid de botones
//       │   │  ●   │ │  ⚠  │ │    cada uno 80x60dp
//       │   └──────┘ └──────┘ │
//       │                     │
//       │   ┌──────┐ ┌──────┐ │
//       │   │      │ │      │ │
//       │   │INTEL │ │EXFIL │ │
//       │   │  📡  │ │  →  │ │
//       │   └──────┘ └──────┘ │
//        \                   /
//         └─────────────────┘
//
// RECTANGULAR:
//   Mismo grid 2x2, padding menor (8dp)
//   Botones: 80x52dp
//
// Colores de botones:
//   SAFE        → bg: Color(0xFF0D2E1A), border: AppColors.safe,      icon: AppColors.safe
//   COMPROMISED → bg: Color(0xFF2E0D0D), border: AppColors.emergency, icon: AppColors.emergency
//   INTEL       → bg: Color(0xFF0D1E2E), border: AppColors.accentCyan, icon: AppColors.accentCyan
//   EXFIL       → bg: Color(0xFF1E1A0D), border: AppColors.accentAmber, icon: AppColors.accentAmber
//
// Spec boton:
//   GestureDetector(
//     onTap: () {
//       HapticFeedback.mediumImpact();
//       sendQuickReport(type);
//       showWearConfirmation(type);
//     },
//     child: Container(
//       height: 60,  // rectangular: 52
//       decoration: BoxDecoration(
//         color: _bgColor,
//         borderRadius: BorderRadius.circular(AppRadius.wearCard),
//         border: Border.all(color: _borderColor, width: 1.5),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(_icon, color: _iconColor, size: 20),
//           SizedBox(height: 4),
//           Text(_label,
//             style: TextStyle(
//               fontFamily: AppTypography.fontFamilyWearOS,
//               fontSize: AppTypography.wearLabelSize, // 16sp
//               fontWeight: FontWeight.w700,
//               color: _borderColor,
//               letterSpacing: 1.2,
//             ),
//           ),
//         ],
//       ),
//     ),
//   )
//
// Confirmacion post-tap:
//   Overlay temporal (1.5s) con checkmark:
//   Container full-screen, color: _bgColor.withOpacity(0.95)
//   Icon check, color: _borderColor, size: 48
//   Text('ENVIADO', fontSize: 18, bold)
//   Desaparece automaticamente. Haptic: lightImpact al desaparecer.

// =============================================================================
// 4. BIOMETRIC DISPLAY — Corazon + estres en wearable
// =============================================================================
//
// Acceso: Swipe RIGHT desde watchface principal
//
// WIREFRAME CIRCULAR:
//
//         ┌─────────────────┐
//        /                   \
//       │    BIOMETRICOS      │  ← label top
//       │                     │
//       │    ♥  87 bpm        │  ← 34sp bold, icono 28sp, centrado
//       │    NORMAL           │  ← status bpm, 14sp
//       │                     │
//       │  ESTRES  ████░░ 65% │  ← barra + valor, 18sp
//       │                     │
//       │  SpO2: 98%  T:36.8° │  ← datos secundarios, 16sp
//        \                   /
//         └─────────────────┘
//
// BPM Display:
//   Row centrado: [Icon(Icons.favorite, size: 28, color: bpmColor)] + [Text(bpm)]
//   bpmColor: bpm < 40 || bpm > 150 ? AppColors.emergency (+ blink)
//              bpm >= 100 ? AppColors.alert
//              else AppColors.safe
//   fontSize BPM: AppTypography.wearDisplaySize (32sp)
//   fontWeight: w700, fontFamily: RobotoCondensed
//
// Barra de estres:
//   LinearProgressIndicator(
//     value: stressPercent / 100,
//     backgroundColor: AppColors.bgElevated,
//     valueColor: AlwaysStoppedAnimation(_stressColor),
//     minHeight: 8,
//   )
//   borderRadius en contenedor: 4dp
//   Etiqueta: 'ESTRES $stressPercent%', fontSize: 16sp
//
// Datos secundarios:
//   Row con separador '|': SpO2 y temperatura
//   fontSize: AppTypography.wearLabelSize (16sp)
//   color: AppColors.textSecondary

// =============================================================================
// 5. LOCATION BEACON — Indicador GPS activo en wearable
// =============================================================================
//
// Acceso: Bottom de watchface (icono tap), o swipe DOWN
//
// WIREFRAME CIRCULAR:
//
//         ┌─────────────────┐
//        /                   \
//       │    GPS ACTIVO  ●   │  ← dot pulso 8dp cyan
//       │                     │
//       │  40.7128° N         │  ← coord lat, 20sp mono
//       │  74.0060° W         │  ← coord lon, 20sp mono
//       │                     │
//       │  Precision: 5m      │  ← 16sp
//       │  Ultima sync: 14:23 │  ← 14sp textSecondary
//       │                     │
//       │  [COMPARTIR UBIC.]  │  ← boton 48dp, cyan, full-width zona segura
//        \                   /
//         └─────────────────┘
//
// Dot GPS activo:
//   Container(width: 8, height: 8, decoration: BoxDecoration(
//     shape: BoxShape.circle,
//     color: AppColors.accentCyan,
//   ))
//   + ScaleTransition 1.0->1.5 + FadeTransition 1.0->0.0, duracion 1200ms loop
//
// Sin GPS (modo degradado):
//   Dot: AppColors.alert (ambar)
//   Coordenadas: "BUSCANDO SENAL..."
//   Precision: "--"
//
// GPS offline:
//   Dot: AppColors.textDisabled
//   Background: sin cambio
//   Texto: "GPS NO DISPONIBLE"
//   Boton: deshabilitado, opacity 0.3
//
// Boton COMPARTIR:
//   height: 48dp (tap target wearable)
//   background: AppColors.accentCyan
//   textColor: AppColors.textOnAccent
//   borderRadius: AppRadius.wearCard
//   onTap: HapticFeedback.mediumImpact() + beacon al servidor + toast de confirmacion en mobile

// =============================================================================
// WEAROS NAVIGATION — Swipe navigation spec
// =============================================================================
//
// Estructura de paginas (PageView horizontal):
//   [QuickReport] ← [AgentStatusFace] → [BiometricDisplay]
//                          ↓ (swipe down)
//                   [LocationBeacon]
//
// PageController:
//   initialPage: 1  (AgentStatusFace siempre al centro)
//   physics: CustomPageScrollPhysics con snapToPage
//
// Indicadores de pagina (WearOS circular):
//   Dots de 4dp en el borde inferior de la zona segura
//   Color activo: AppColors.accentCyan
//   Color inactivo: AppColors.textDisabled
//   NO mostrar en EmergencySOS (toma pantalla completa)
//
// Long press corona → EmergencySOS siempre, desde cualquier pagina:
//   Navigator.of(context).push(
//     MaterialPageRoute(
//       fullscreenDialog: true,
//       builder: (_) => EmergencySOSScreen(),
//     ),
//   )
//
// Sincronizacion BLE con mobile:
//   Tap en dot de conexion del watchface → sync manual
//   Auto-sync cada 30 segundos si BLE conectado
//   Indicador offline: icono antena tachado en AppColors.alert

// =============================================================================
// COMPOSE WEAR EQUIVALENCES (referencia para implementacion nativa)
// =============================================================================
//
// Si se implementa en Jetpack Compose Wear en lugar de Flutter:
//
// tokens.dart → Colors.kt + Typography.kt + Spacing.kt
//
// AppColors.bgBase       → Color(0xFF080B0F)
// AppColors.accentCyan   → Color(0xFF00D4FF)
// AppColors.emergency    → Color(0xFFFF2D2D)
// AppColors.safe         → Color(0xFF00E676)
//
// MaterialTheme {
//   colorScheme = darkColorScheme(
//     primary = Color(0xFF00D4FF),
//     onPrimary = Color(0xFF000000),
//     background = Color(0xFF080B0F),
//     surface = Color(0xFF0F1419),
//     error = Color(0xFFFF2D2D),
//   )
// }
//
// WearOS Typography:
//   DisplayLarge → fontSize: 32.sp, fontWeight: Bold, fontFamily: RobotoCondensed
//   BodyLarge    → fontSize: 18.sp, fontWeight: Normal
//   LabelSmall   → fontSize: 14.sp
//
// Scaffold:
//   Scaffold(
//     timeText = { TimeText() },
//     content = { ... }
//   )
//   Para pantalla circular: usar Curvedtext con ArcPaddingValues
//
// Chip (Quick Report buttons):
//   Chip(
//     onClick = { hapticFeedback(); sendReport(type) },
//     colors = ChipDefaults.chipColors(
//       backgroundColor = _bgColor,
//       contentColor = _borderColor,
//     ),
//     border = ChipDefaults.chipBorder(borderColor = _borderColor),
//     label = { Text(label, fontSize = 14.sp) },
//     icon = { Icon(icon, tint = _iconColor) },
//   )
