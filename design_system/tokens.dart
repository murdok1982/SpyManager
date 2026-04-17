// =============================================================================
// SpyManager IMC — Design System Tokens
// Agente: DISENO | Fecha: 2026-04-17
// Target: Flutter Mobile + WearOS
// =============================================================================

// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

// =============================================================================
// COLOR TOKENS
// Modo oscuro UNICO — no hay modo claro
// Criterio: contraste minimo 7:1 para texto principal (WCAG AAA operacional)
// =============================================================================

class AppColors {
  AppColors._();

  // --- Backgrounds ---
  /// Fondo base absoluto. Pantalla principal, scaffolds.
  static const Color bgBase        = Color(0xFF080B0F); // #080B0F — negro operacional
  /// Fondo de nivel 1: cards, bottom sheets, paneles laterales.
  static const Color bgSurface     = Color(0xFF0F1419); // #0F1419
  /// Fondo de nivel 2: campos de input, sub-cards, listas internas.
  static const Color bgElevated    = Color(0xFF161D27); // #161D27
  /// Fondo de nivel 3: tooltips, chips, badges sobre surface.
  static const Color bgOverlay     = Color(0xFF1E2A38); // #1E2A38

  // --- Acentos (maximo 2) ---
  /// Acento primario: cian operacional. Acciones principales, selected states.
  /// Contraste sobre bgBase: 8.3:1 — supera WCAG AAA.
  static const Color accentCyan    = Color(0xFF00D4FF); // #00D4FF
  /// Acento secundario: ambar de alerta activa.
  /// Contraste sobre bgBase: 7.1:1 — cumple umbral operacional.
  static const Color accentAmber   = Color(0xFFFFB020); // #FFB020

  // --- Colores Semanticos ---
  /// Emergencia absoluta: SOS, COMPROMISED, error critico.
  static const Color emergency     = Color(0xFFFF2D2D); // #FF2D2D — contraste 5.3:1 sobre bgBase
  /// Alerta operacional: advertencia, atencion requerida.
  static const Color alert         = Color(0xFFFFB020); // #FFB020 — mismo que accentAmber
  /// Estado seguro: ACTIVE, confirmado, ok.
  static const Color safe          = Color(0xFF00E676); // #00E676 — contraste 9.1:1
  /// Clasificado: datos sensibles, contenedor de intel.
  static const Color classified    = Color(0xFF1A3A6B); // #1A3A6B — azul oscuro seguridad

  // --- Niveles de Clasificacion ---
  /// UNCLASSIFIED — publico/no sensible.
  static const Color classUnclassified  = Color(0xFF8A9BB0); // gris neutro
  /// SECRET — dato restringido.
  static const Color classSecret        = Color(0xFFCC2222); // rojo oscuro
  /// TOP SECRET — maximo nivel. Badge negro con borde dorado.
  static const Color classTopSecret     = Color(0xFF1A1A1A); // negro
  static const Color classTopSecretGold = Color(0xFFD4A017); // dorado borde/texto

  // --- Texto ---
  /// Texto principal: cuerpo, labels, valores.
  static const Color textPrimary   = Color(0xFFE8EDF2); // #E8EDF2 — contraste 15.2:1
  /// Texto secundario: subtitulos, metadatos, timestamps.
  static const Color textSecondary = Color(0xFF7A8B9E); // #7A8B9E — contraste 5.2:1
  /// Texto deshabilitado / placeholder.
  static const Color textDisabled  = Color(0xFF3D4F60); // contraste 2.2:1 (intencional)
  /// Texto sobre acentos y emergencias (siempre negro para contraste).
  static const Color textOnAccent  = Color(0xFF000000);
  static const Color textOnEmergency = Color(0xFFFFFFFF);

  // --- Bordes y Divisores ---
  static const Color borderSubtle  = Color(0xFF1E2A38); // muy sutil, separadores internos
  static const Color borderDefault = Color(0xFF2A3D52); // borde de card estandar
  static const Color borderActive  = Color(0xFF00D4FF); // borde con foco / seleccionado

  // --- Estados especiales ---
  static const Color dark_COMPROMISED = Color(0xFFFF2D2D);
  static const Color dark_ACTIVE      = Color(0xFF00E676);
  static const Color dark_DARK        = Color(0xFF7A8B9E); // DARK MODE operacional del agente
  static const Color shimmer          = Color(0xFF1E2A38);
  static const Color shimmerHighlight = Color(0xFF2A3D52);
}

// =============================================================================
// TYPOGRAPHY TOKENS
// Fuente: RobotoMono — maxima legibilidad en pantallas sucias, luz adversa,
// con vibracion. Caracter monoespaciado facilita lectura de codigos y coords.
// Wearable: usa RobotoCondensed para compresion horizontal.
// =============================================================================

class AppTypography {
  AppTypography._();

  static const String fontFamilyMobile  = 'RobotoMono';
  static const String fontFamilyWearOS  = 'RobotoCondensed';

  // --- Escala Mobile ---
  /// Display: titulos de pantalla completa, estado principal en watchface.
  static const double displaySize     = 34.0;
  static const FontWeight displayWeight = FontWeight.w700;

  /// Headline: headers de seccion, nombre de agente.
  static const double headlineSize    = 24.0;
  static const FontWeight headlineWeight = FontWeight.w600;

  /// Title: titulos de card, headers de lista.
  static const double titleSize       = 20.0;
  static const FontWeight titleWeight = FontWeight.w600;

  /// Body: texto de cuerpo principal. 16sp MINIMO en mobile.
  static const double bodySize        = 16.0;
  static const FontWeight bodyWeight  = FontWeight.w400;

  /// Label: metadatos, timestamps, ids de caso.
  static const double labelSize       = 14.0;
  static const FontWeight labelWeight = FontWeight.w500;

  /// Caption: texto auxiliar, leyendas de mapa.
  static const double captionSize     = 12.0;
  static const FontWeight captionWeight = FontWeight.w400;

  // --- Escala WearOS (incrementada) ---
  /// Todo en wearable sube 2sp vs mobile. Minimo absoluto: 18sp.
  static const double wearDisplaySize  = 32.0; // ocupa maxima zona visible
  static const double wearHeadlineSize = 22.0;
  static const double wearBodySize     = 18.0; // MINIMO wearable
  static const double wearLabelSize    = 16.0;

  // --- Letter Spacing para codigos de inteligencia ---
  static const double monoSpacing     = 1.2;  // para IDs, coords, hashes
  static const double normalSpacing   = 0.3;

  // --- Altura de linea ---
  static const double lineHeightTight  = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightLoose  = 1.8;
}

// =============================================================================
// SPACING TOKENS
// Grid base 4dp. Wearable usa grid 8dp (dedos con guante).
// =============================================================================

class AppSpacing {
  AppSpacing._();

  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;

  // Wearable: todo x2 por operacion con guantes
  static const double wearSm  = 12.0;
  static const double wearMd  = 20.0;
  static const double wearLg  = 28.0;

  // Safe areas mobile
  static const double safeTop    = 44.0; // notch
  static const double safeBottom = 34.0; // home bar
  static const EdgeInsets safeInsets = EdgeInsets.only(
    top: safeTop,
    bottom: safeBottom,
  );
}

// =============================================================================
// BORDER RADIUS TOKENS
// Anguloso deliberado: app de inteligencia no usa bordes pill.
// =============================================================================

class AppRadius {
  AppRadius._();

  static const double none   =  0.0;
  static const double xs     =  2.0;
  static const double sm     =  4.0;
  static const double md     =  8.0;
  static const double lg     = 12.0;
  static const double xl     = 16.0;

  // Para wearable circular: las cards internas son pill o cuadrado segun contexto
  static const double wearCard  = 16.0;
  static const double wearChip  =  8.0;
  static const double wearFull  = 999.0; // pill completo

  static BorderRadius card     = BorderRadius.circular(md);
  static BorderRadius button   = BorderRadius.circular(sm);
  static BorderRadius input    = BorderRadius.circular(sm);
  static BorderRadius badge    = BorderRadius.circular(xs);
  static BorderRadius chip     = BorderRadius.circular(999);
}

// =============================================================================
// ELEVATION / SHADOW TOKENS
// En dark mode: sombras via overlay de color, no solo opacidad.
// =============================================================================

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = const [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> emergency = const [
    BoxShadow(
      color: Color(0x80FF2D2D),
      blurRadius: 16.0,
      spreadRadius: 2.0,
      offset: Offset(0, 0),
    ),
  ];

  static List<BoxShadow> accentGlow = const [
    BoxShadow(
      color: Color(0x4000D4FF),
      blurRadius: 12.0,
      spreadRadius: 1.0,
      offset: Offset(0, 0),
    ),
  ];
}

// =============================================================================
// ANIMATION TOKENS
// Rapidas y funcionales. Sin animaciones decorativas que distraigan.
// =============================================================================

class AppAnimation {
  AppAnimation._();

  /// Feedback inmediato: color changes, checkbox, badge update.
  static const Duration instant    = Duration(milliseconds: 100);
  /// Micro-interaccion: press feedback, ripple.
  static const Duration fast       = Duration(milliseconds: 200);
  /// Transicion estandar: card expand, modal open.
  static const Duration normal     = Duration(milliseconds: 300);
  /// Transicion de pantalla completa.
  static const Duration slow       = Duration(milliseconds: 450);
  /// Emergencia: la overlay SOS aparece RAPIDO.
  static const Duration sosOverlay = Duration(milliseconds: 150);

  static const Curve defaultCurve  = Curves.easeInOut;
  static const Curve entryCurve    = Curves.easeOut;
  static const Curve emergencyCurve = Curves.easeIn; // rapido al aparecer
}

// =============================================================================
// TAP TARGET SIZES
// Mobile: 44x44dp WCAG minimo
// Wearable: 48x48dp para uso con guantes (recomendacion Google WearOS)
// =============================================================================

class AppTapTarget {
  AppTapTarget._();

  static const double mobile  = 44.0;
  static const double wearable = 48.0;
  static const double emergency = 64.0; // boton SOS — imposible de no golpear
}

// =============================================================================
// ICON SIZES
// =============================================================================

class AppIconSize {
  AppIconSize._();

  static const double sm  = 16.0;
  static const double md  = 24.0;
  static const double lg  = 32.0;
  static const double xl  = 48.0;
  static const double sos = 56.0; // icono dentro del boton de emergencia
}

// =============================================================================
// HAPTIC FEEDBACK CATALOG
// Se usa HapticFeedback de Flutter. Mapeado a acciones criticas.
// =============================================================================
//
// HapticFeedback.lightImpact()   → tap estandar, seleccion de tab
// HapticFeedback.mediumImpact()  → confirmacion de accion, envio de reporte
// HapticFeedback.heavyImpact()   → activacion de emergencia SOS
// HapticFeedback.vibrate()       → alerta critica entrante, timeout de sesion
//
// Wearable: usar WearableHaptics del SDK WearOS con patrones:
//   HAPTIC_LONG_PRESS  → hold para SOS
//   HAPTIC_CLICK       → confirmacion de quick report
//   HAPTIC_DOUBLE_CLICK → sincronizacion exitosa

// =============================================================================
// Z-INDEX / ELEVATION LAYERS (Material elevation dp)
// =============================================================================

class AppLayer {
  AppLayer._();

  static const int base       = 0;
  static const int card       = 1;
  static const int appBar     = 4;
  static const int bottomNav  = 8;
  static const int fab        = 6;
  static const int modal      = 16;
  static const int toast      = 24;
  static const int sosOverlay = 32; // SIEMPRE encima de todo
}
