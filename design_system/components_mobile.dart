// =============================================================================
// SpyManager IMC — Componentes Mobile Flutter
// Agente: DISENO | Fecha: 2026-04-17
// Todos los componentes son especificaciones implementables directas.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

// =============================================================================
// 1. STATUS CARD — Estado operacional del agente
// =============================================================================
//
// Dimensiones: ancho full, alto minimo 96dp
// Ubicacion: primer elemento del Dashboard, sticky si hay scroll
//
// ESTADOS:
//   ACTIVE      → borde izquierdo 4dp safe(#00E676), icono escudo verde
//   DARK        → borde izquierdo 4dp textSecondary(#7A8B9E), sin color destacado
//   COMPROMISED → borde izquierdo 4dp emergency(#FF2D2D), glow rojo, pulso animado
//
// WIREFRAME:
// ┌──────────────────────────────────────────────┐
// │▌  AGENTE-7734             [ACTIVE] ●        │  ← barra izquierda 4dp
// │   Op. MARES DEL SUR                          │
// │   Ultimo ping: hace 2 min    [SYNC ↺]        │
// └──────────────────────────────────────────────┘
//
// Flutter spec:
//
// Container(
//   constraints: BoxConstraints(minHeight: 96),
//   decoration: BoxDecoration(
//     color: AppColors.bgSurface,
//     borderRadius: AppRadius.card,
//     border: Border(
//       left: BorderSide(color: _statusColor, width: 4),
//       top:    BorderSide(color: AppColors.borderDefault, width: 1),
//       right:  BorderSide(color: AppColors.borderDefault, width: 1),
//       bottom: BorderSide(color: AppColors.borderDefault, width: 1),
//     ),
//     boxShadow: status == AgentStatus.COMPROMISED
//       ? AppShadows.emergency
//       : AppShadows.card,
//   ),
//   padding: EdgeInsets.all(AppSpacing.md),
//   child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Row(children: [
//         Text(agentId,
//           style: TextStyle(
//             fontFamily: AppTypography.fontFamilyMobile,
//             fontSize: AppTypography.titleSize,
//             fontWeight: AppTypography.titleWeight,
//             color: AppColors.textPrimary,
//             letterSpacing: AppTypography.monoSpacing,
//           ),
//         ),
//         Spacer(),
//         StatusBadge(status: agentStatus),
//       ]),
//       SizedBox(height: AppSpacing.xs),
//       Text(operationName,
//         style: TextStyle(
//           fontFamily: AppTypography.fontFamilyMobile,
//           fontSize: AppTypography.bodySize,
//           color: AppColors.textSecondary,
//         ),
//       ),
//       SizedBox(height: AppSpacing.sm),
//       Row(children: [
//         Text('Ultimo ping: $lastPing',
//           style: TextStyle(fontSize: AppTypography.labelSize, color: AppColors.textSecondary),
//         ),
//         Spacer(),
//         SyncButton(), // ver spec abajo
//       ]),
//     ],
//   ),
// )
//
// StatusBadge colores:
//   ACTIVE      → bgColor: Color(0xFF0D2E1A), textColor: AppColors.safe,      border: AppColors.safe
//   DARK        → bgColor: Color(0xFF1A2030), textColor: AppColors.textSecondary, border: AppColors.borderDefault
//   COMPROMISED → bgColor: Color(0xFF2E0D0D), textColor: AppColors.emergency,  border: AppColors.emergency
//
// StatusBadge spec:
//   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
//   borderRadius: BorderRadius.circular(AppRadius.xs)
//   border: Border.all(color: borderColor, width: 1)
//   fontSize: AppTypography.labelSize | fontWeight: FontWeight.w700
//   letterSpacing: 1.5 (uppercase tracking)

// =============================================================================
// 2. INTEL REPORT FORM — Formulario de reporte de campo
// =============================================================================
//
// Principio: formulario en modo "misil": rapido, sin campos opcionales visibles.
// Solo los campos criticos en pantalla. Campos avanzados bajo "Detalles adicionales".
//
// WIREFRAME:
// ┌──────────────────────────────────────────────┐
// │  NUEVO REPORTE INTEL              [× Cerrar] │
// ├──────────────────────────────────────────────┤
// │  Clasificacion                               │
// │  [ UNCLASSIFIED ▾ ]  ← Picker con colores   │
// │                                              │
// │  Tipo de reporte                             │
// │  [ HUMINT ▾ ]                               │
// │                                              │
// │  Descripcion *                               │
// │  ┌────────────────────────────────────────┐ │
// │  │ Describe la observacion...             │ │
// │  │                                        │ │
// │  └────────────────────────────────────────┘ │
// │  Max 500 chars | 0/500                       │
// │                                              │
// │  Coordenadas (GPS auto)                      │
// │  [ 40.7128° N, 74.0060° W ]  [↻ Actualizar] │
// │                                              │
// │  [+] Adjuntar archivo cifrado               │
// │                                              │
// │  ┌────────────────────────────────────────┐ │
// │  │         ENVIAR REPORTE CIFRADO         │ │  ← 56dp alto
// │  └────────────────────────────────────────┘ │
// └──────────────────────────────────────────────┘
//
// Campos spec:
//
// InputDecoration(
//   filled: true,
//   fillColor: AppColors.bgElevated,
//   labelStyle: TextStyle(
//     color: AppColors.textSecondary,
//     fontSize: AppTypography.labelSize,
//     fontFamily: AppTypography.fontFamilyMobile,
//   ),
//   border: OutlineInputBorder(
//     borderRadius: AppRadius.input,
//     borderSide: BorderSide(color: AppColors.borderDefault, width: 1),
//   ),
//   focusedBorder: OutlineInputBorder(
//     borderRadius: AppRadius.input,
//     borderSide: BorderSide(color: AppColors.accentCyan, width: 1.5),
//   ),
//   errorBorder: OutlineInputBorder(
//     borderRadius: AppRadius.input,
//     borderSide: BorderSide(color: AppColors.emergency, width: 1.5),
//   ),
//   errorStyle: TextStyle(color: AppColors.emergency, fontSize: AppTypography.labelSize),
//   contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
// )
//
// TextArea (descripcion):
//   minLines: 4, maxLines: 8
//   maxLength: 500
//   style: TextStyle(
//     fontFamily: AppTypography.fontFamilyMobile,
//     fontSize: AppTypography.bodySize,
//     color: AppColors.textPrimary,
//     height: AppTypography.lineHeightNormal,
//   )
//
// Boton ENVIAR:
//   height: 56dp
//   backgroundColor: AppColors.accentCyan
//   foregroundColor: AppColors.textOnAccent
//   borderRadius: AppRadius.button
//   textStyle: fontSize 18sp, fontWeight w700, letterSpacing 1.5
//   haptic: HapticFeedback.mediumImpact() al confirmar envio

// =============================================================================
// 3. EMERGENCY BUTTON — Boton SOS
// =============================================================================
//
// REGLA DE ORO: accesible en MAX 2 toques desde cualquier pantalla.
// Siempre presente en bottom navigation como tab de emergencia (icono escudo).
// FAB alternativo en Dashboard.
//
// WIREFRAME (overlay al activar):
// ┌──────────────────────────────────────────────┐
// │████████████████████████████████████████████│  ← overlay rojo semitransparente
// │                                              │     color: Color(0xCC200000)
// │                  ⚠                          │
// │                                              │
// │         EMERGENCIA ACTIVA                    │  ← 34sp bold
// │       Transmitiendo posicion...              │
// │                                              │
// │   ┌──────────────────────────────────────┐   │
// │   │  ● BROADCASTING SOS — AGENTE-7734   │   │  ← pulsing border
// │   └──────────────────────────────────────┘   │
// │                                              │
// │   ┌──────────────────────────────────────┐   │
// │   │         CANCELAR EMERGENCIA          │   │  ← 56dp, borde blanco
// │   └──────────────────────────────────────┘   │  (no rojo para diferenciar)
// └──────────────────────────────────────────────┘
//
// FAB SOS en Dashboard:
//   FloatingActionButton.extended(
//     backgroundColor: AppColors.emergency,
//     icon: Icon(Icons.emergency_share, color: Colors.white, size: AppIconSize.md),
//     label: Text('SOS', style: TextStyle(
//       color: Colors.white,
//       fontSize: 16,
//       fontWeight: FontWeight.w700,
//       letterSpacing: 2.0,
//     )),
//     onPressed: () {
//       HapticFeedback.heavyImpact();
//       // Mostrar dialogo confirmacion: hold 2 segundos para activar
//     },
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
//   )
//
// Confirmacion SOS (dialogo previo):
//   Dialogo de fondo negro, texto blanco, dos opciones:
//   - "MANTENER PRESIONADO 2s PARA ACTIVAR" (GestureDetector con timer)
//   - "CANCELAR" (ghost button)
//   Sin opcion de cerrar tocando fuera del dialogo (barrierDismissible: false)
//
// Overlay SOS spec:
//   Material overlay con elevation 32 (AppLayer.sosOverlay)
//   animation: FadeTransition duration AppAnimation.sosOverlay (150ms)
//   curve: AppAnimation.emergencyCurve
//   pulsing border: AnimatedContainer alternando entre:
//     border: Border.all(color: AppColors.emergency, width: 2)
//     border: Border.all(color: AppColors.emergency.withOpacity(0.3), width: 2)
//     duracion pulso: 800ms repeticion infinita

// =============================================================================
// 4. CASE LIST ITEM — Item de caso asignado
// =============================================================================
//
// WIREFRAME:
// ┌──────────────────────────────────────────────┐
// │  [SECRET]   CASO-2847                   ●   │  ← badge clasificacion + dot status
// │             Op. ALFA NORTE                   │
// │             Objetivo: Martinez, R.           │
// │             Prioridad: ALTA  |  3 reportes   │
// │             Actualizado: 14:23               │
// └──────────────────────────────────────────────┘
// Altura: 96dp minimo
// Padding: 16dp
// borde inferior: 1dp borderSubtle
// Borde izquierdo: 4dp segun clasificacion
//
// Colores de borde por clasificacion:
//   UNCLASSIFIED → AppColors.classUnclassified (#8A9BB0)
//   SECRET       → AppColors.classSecret (#CC2222)
//   TOP SECRET   → AppColors.classTopSecretGold (#D4A017)
//
// Interaccion:
//   InkWell con splash color: AppColors.accentCyan.withOpacity(0.1)
//   borderRadius: AppRadius.card
//   onTap: navegar a CaseDetail + HapticFeedback.lightImpact()

// =============================================================================
// 5. LOCATION PIN — Indicador en mapa
// =============================================================================
//
// Implementado como CustomPainter o widget sobre FlutterMap/MapLibre.
//
// TIPOS:
//   agente_propio   → circulo cyan 16dp + pulso animado + borde blanco 2dp
//   punto_interes   → pin hexagonal ambar, icono adentro 12dp
//   zona_peligro    → overlay rojo semitransparente, borde rojo punteado
//   punto_exfil     → circulo verde 16dp + codigo de 4 letras arriba
//
// Spec agente_propio:
//   Container circular diameter: 16dp
//   color: AppColors.accentCyan
//   border: 2dp blanco
//   sombra: BoxShadow(color: AppColors.accentCyan.withOpacity(0.6), blurRadius: 8, spreadRadius: 4)
//   pulso: ScaleTransition 1.0 -> 1.8, fade out, 2000ms loop
//
// Label bajo pin:
//   Container(
//     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//     decoration: BoxDecoration(
//       color: AppColors.bgSurface.withOpacity(0.9),
//       borderRadius: BorderRadius.circular(2),
//     ),
//     child: Text(label,
//       style: TextStyle(
//         fontFamily: AppTypography.fontFamilyMobile,
//         fontSize: 11,
//         color: AppColors.textPrimary,
//         letterSpacing: AppTypography.monoSpacing,
//       ),
//     ),
//   )

// =============================================================================
// 6. CLASSIFICATION BADGE — Badge de nivel de clasificacion
// =============================================================================
//
// Siempre visible en esquina superior del contenedor padre.
//
// UNCLASSIFIED:
//   background: Color(0xFF1A2030)
//   text: AppColors.classUnclassified
//   border: AppColors.classUnclassified
//   texto: "U // UNCLASSIFIED"
//
// SECRET:
//   background: Color(0xFF2E0A0A)
//   text: AppColors.classSecret
//   border: AppColors.classSecret
//   texto: "S // SECRET"
//
// TOP SECRET:
//   background: AppColors.classTopSecret (#1A1A1A)
//   text: AppColors.classTopSecretGold
//   border: AppColors.classTopSecretGold (2dp)
//   texto: "TS // TOP SECRET"
//
// Spec comun:
//   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)
//   borderRadius: BorderRadius.circular(AppRadius.xs)  // anguloso
//   border: Border.all(width: 1) // 2dp para TS
//   fontSize: 11sp
//   fontWeight: FontWeight.w700
//   letterSpacing: 1.8
//   fontFamily: AppTypography.fontFamilyMobile

// =============================================================================
// 7. BIOMETRIC WIDGET — Visualizacion de biometricos del wearable
// =============================================================================
//
// WIREFRAME:
// ┌─────────────────────────────────────────────┐
// │  BIOMETRICOS — AGENTE-7734    [LIVE ●]      │
// ├─────────────────────────────────────────────┤
// │   ♥ 87 bpm          ESTRES: MODERADO        │
// │   ━━━━━━━━━━━━━━━━   ████████░░░░ 65%        │
// │                                             │
// │   Temp: 36.8°C      SpO2: 98%              │
// │   Pasos: 4,823      Activo: 2h 15min        │
// └─────────────────────────────────────────────┘
//
// Colores de estres:
//   BAJO (0-40%)    → AppColors.safe
//   MODERADO (41-70%) → AppColors.alert
//   ALTO (71-100%)  → AppColors.emergency + pulso en badge
//
// BPM critico (>150 o <40):
//   El valor parpadea en AppColors.emergency
//   Toast: "ALERTA BIOMETRICA — AGENTE-7734"
//
// Indicador LIVE:
//   Dot 8dp AppColors.safe con pulso 1500ms
//   Si sin conexion: dot AppColors.textDisabled, texto "OFFLINE"
//
// Progress bar de estres:
//   height: 6dp
//   borderRadius: 3dp
//   background: AppColors.bgElevated
//   fill: color segun nivel
//   AnimatedContainer duration: AppAnimation.normal

// =============================================================================
// 8. ENCRYPTED MESSAGE BUBBLE — Burbuja de mensaje cifrado
// =============================================================================
//
// WIREFRAME — mensaje propio (derecha):
//    ┌──────────────────────────────┐
//    │  🔒 [CIFRADO AES-256]       │  ← antes de descifrar
//    └──────────────────────────────┘
//
//    ┌──────────────────────────────┐
//    │  Reunion en punto DELTA a   │  ← despues de descifrar
//    │  las 22:00. Traer equipo.   │
//    │                  14:23 ✓✓  │
//    └──────────────────────────────┘
//
// Mensaje propio (enviado):
//   alineacion: Alignment.centerRight
//   maxWidth: 75% del ancho de pantalla
//   background: AppColors.classified (#1A3A6B)
//   border: none
//   borderRadius: BorderRadius.only(
//     topLeft: Radius.circular(12), topRight: Radius.circular(12),
//     bottomLeft: Radius.circular(12), bottomRight: Radius.circular(2),
//   )
//   padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)
//   textColor: AppColors.textPrimary
//
// Mensaje recibido:
//   alineacion: Alignment.centerLeft
//   background: AppColors.bgElevated
//   border: Border.all(color: AppColors.borderDefault, width: 1)
//   borderRadius: inverso al propio
//
// Estado cifrado (antes de tap para descifrar):
//   background con patron: combinacion de AppColors.bgOverlay + icono lock centrado
//   texto visible: "MENSAJE CIFRADO — TAP PARA DESCIFRAR"
//   fontSize: AppTypography.labelSize, color: AppColors.textSecondary
//
// Timestamp:
//   fontSize: 11sp, color: AppColors.textDisabled
//   align: end del bubble

// =============================================================================
// 9. AUDIT LOG ENTRY — Entrada de log de auditoria
// =============================================================================
//
// WIREFRAME:
// ┌──────────────────────────────────────────────┐
// │ 2026-04-17 14:23:07Z                         │  ← timestamp mono
// │ AGT-7734  LOGIN_SUCCESS  IP:10.0.0.44        │  ← accion principal
// │ Device: Pixel 8 Pro | Hash: a3f2...          │  ← detalles colapsables
// └──────────────────────────────────────────────┘
// Separador: 1dp AppColors.borderSubtle
//
// Color de accion por tipo:
//   LOGIN_SUCCESS / REPORT_SENT / SYNC_OK → AppColors.safe
//   AUTH_FAILED / ACCESS_DENIED           → AppColors.emergency
//   DATA_ACCESSED / LOCATION_SHARED       → AppColors.alert
//   SYSTEM / CONFIG                       → AppColors.textSecondary
//
// Timestamp: fontFamily mono, fontSize 12sp, color textDisabled
// Accion: fontSize 14sp, fontWeight w600, color segun tipo
// Detalles: fontSize 12sp, color textSecondary, colapsables con ExpansionTile
//
// Container(
//   padding: EdgeInsets.symmetric(
//     horizontal: AppSpacing.md,
//     vertical: AppSpacing.sm,
//   ),
//   decoration: BoxDecoration(
//     border: Border(
//       bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
//       left: BorderSide(color: _actionColor, width: 2),
//     ),
//   ),
// )

// =============================================================================
// THEME DATA — MaterialApp ThemeData completo
// =============================================================================

ThemeData buildSpyManagerTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgBase,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentCyan,
      secondary: AppColors.accentAmber,
      error: AppColors.emergency,
      background: AppColors.bgBase,
      surface: AppColors.bgSurface,
      onPrimary: AppColors.textOnAccent,
      onSecondary: AppColors.textOnAccent,
      onError: Colors.white,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
    fontFamily: AppTypography.fontFamilyMobile,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.displaySize,
        fontWeight: AppTypography.displayWeight,
        color: AppColors.textPrimary,
        letterSpacing: AppTypography.monoSpacing,
      ),
      headlineMedium: TextStyle(
        fontSize: AppTypography.headlineSize,
        fontWeight: AppTypography.headlineWeight,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: AppTypography.titleSize,
        fontWeight: AppTypography.titleWeight,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bodyWeight,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.labelSize,
        fontWeight: AppTypography.labelWeight,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: AppTypography.captionSize,
        color: AppColors.textDisabled,
        letterSpacing: AppTypography.monoSpacing,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgSurface,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyMobile,
        fontSize: AppTypography.titleSize,
        fontWeight: AppTypography.titleWeight,
        color: AppColors.textPrimary,
        letterSpacing: AppTypography.monoSpacing,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: AppIconSize.md),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgSurface,
      selectedItemColor: AppColors.accentCyan,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyMobile,
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyMobile,
        fontSize: AppTypography.captionSize,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontFamily: AppTypography.fontFamilyMobile,
        fontSize: AppTypography.labelSize,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textDisabled,
        fontFamily: AppTypography.fontFamilyMobile,
        fontSize: AppTypography.bodySize,
      ),
      errorStyle: const TextStyle(
        color: AppColors.emergency,
        fontSize: AppTypography.labelSize,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.textOnAccent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamilyMobile,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.bgSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
      space: 0,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppIconSize.md,
    ),
    useMaterial3: true,
  );
}
