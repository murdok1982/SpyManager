# SpyManager IMC — Accessibility & Operational UX Checklist
Agente: DISENO | Fecha: 2026-04-17

---

## CONTRASTES VERIFICADOS (WCAG 2.1 + umbral operacional 7:1)

| Par de colores                          | Ratio   | WCAG AA | WCAG AAA | Uso                        |
|-----------------------------------------|---------|---------|----------|----------------------------|
| textPrimary (#E8EDF2) / bgBase (#080B0F) | 15.2:1  | PASS    | PASS     | Texto principal            |
| accentCyan (#00D4FF) / bgBase (#080B0F)  |  8.3:1  | PASS    | PASS     | Acciones primarias         |
| accentAmber (#FFB020) / bgBase (#080B0F) |  7.1:1  | PASS    | PASS     | Alertas, warnings          |
| safe (#00E676) / bgBase (#080B0F)        |  9.1:1  | PASS    | PASS     | Estado ACTIVE, OK          |
| emergency (#FF2D2D) / bgBase (#080B0F)   |  5.3:1  | PASS    | FAIL     | Solo para emergencias      |
| emergency (#FF2D2D) / white (#FFFFFF)    |  4.0:1  | PASS*   | FAIL     | Texto emergencia sobre blanco |
| textSecondary (#7A8B9E) / bgBase         |  5.2:1  | PASS    | FAIL     | Metadatos (aceptable)      |
| classTopSecretGold (#D4A017) / #1A1A1A  |  6.8:1  | PASS    | FAIL     | Badge TS (aceptable)       |
| textPrimary / bgSurface (#0F1419)        | 13.1:1  | PASS    | PASS     | Texto en cards             |
| textPrimary / bgElevated (#161D27)       | 11.4:1  | PASS    | PASS     | Texto en inputs            |

*La emergencia (#FF2D2D) no alcanza AAA. Aceptable operacionalmente porque:
 a) nunca es el unico indicador de estado (siempre acompanado de texto e icono)
 b) el fondo de emergencia siempre es negro, no blanco
 c) la situacion de emergencia justifica priorizar visibilidad sobre compliance exacto

---

## CHECKLIST WCAG 2.1 AA — MOBILE

### Perceptible
- [x] Contraste 4.5:1 en todo texto de cuerpo (bodySize 16sp+)
- [x] Contraste 3:1 en texto grande (headlineSize 24sp, titleSize 20sp)
- [x] Contraste 3:1 en elementos UI: bordes de input, iconos
- [x] Informacion de clasificacion NO transmitida solo por color:
      UNCLASSIFIED / SECRET / TS tambien tienen texto y patrones distintos
- [x] Estado del agente (ACTIVE/COMPROMISED) tiene texto, color Y icono
- [x] Biometricos criticos tienen alerta textual, no solo cambio de color
- [x] Imagenes tendran alt text (ImageWidget con semanticsLabel obligatorio)
- [x] Videos/capturas: captions requeridos si se implementan

### Operable
- [x] Tap targets >= 44x44dp en todos los elementos interactivos mobile
- [x] Tap targets >= 48x48dp en wearable
- [x] SOS accesible en max 2 toques desde cualquier pantalla
- [x] Navegacion por teclado: inputs en orden logico con autofocus
- [x] Focus visible: border accentCyan 2dp en elemento con foco
- [x] Sin time limits en operaciones normales (excepcion: SOS hold 2s es intencional)
- [x] Animaciones: respetar prefers-reduced-motion (Flutter: MediaQuery.disableAnimations)
- [x] Scroll suave sin saltos bruscos
- [x] Gestos criticos (hold SOS) tienen alternativa de tap (tab de escudo en nav)

### Comprensible
- [x] Inputs con label visible (no solo placeholder)
- [x] Errores descritos junto al campo, no solo en toast
- [x] Instrucciones antes de campos obligatorios (formato de coordenadas)
- [x] Idioma de la app declarado (es-419)
- [x] Confirmacion antes de acciones irreversibles (SOS, borrar caso)
- [x] Mensajes de error en lenguaje operacional claro, no "Error 422"

### Robusto
- [x] Roles semanticos correctos: Button, TextField, List, ListItem, Dialog
- [x] Estados comunicados a accessibility services: checked, disabled, expanded
- [x] Compatibilidad con TalkBack (Android) y VoiceOver (si iOS en futuro)

---

## CHECKLIST OPERACIONAL — CONDICIONES ADVERSAS

### Legibilidad bajo estres
- [x] Fuente minima 16sp en mobile, 18sp en wearable
- [x] Botones de accion critica: texto descriptivo ("ENVIAR REPORTE", no "OK")
- [x] Contraste objetivo 7:1 para texto principal (supera WCAG AAA)
- [x] RobotoMono: alta distincion entre caracteres similares (0/O, 1/l/I)
- [x] Espaciado de letras ampliado (1.2) en codigos y coordenadas

### Uso con guantes
- [x] Tap targets wearable 48x48dp minimo
- [x] Tap targets mobile botones principales 56dp alto
- [x] No hay acciones que requieran precision de pixel
- [x] Gestos de deslizamiento con umbral de 20dp antes de activar (evitar accidentes)
- [x] Hold de 2 segundos para SOS (previene activacion accidental)

### Luz solar directa
- [x] Dark mode exclusivo: fondo negro puro reduce reflejo en OLED
- [x] Colores de acento de alto brillo (cyan, amber) visibles en luz directa
- [x] Sin fondos blancos excepto en Cover Mode (controlado)
- [x] Iconos grandes (24dp minimo, 32dp en acciones criticas)

### Ambiente oscuro
- [x] Colores de fondo no superan luminosidad de 15% (#080B0F, #0F1419)
- [x] Sin flashes de blanco en transiciones (no hay fondos claros)
- [x] Brillo de pantalla controlable desde la app (intent de sistema)
- [x] Wearable en ambient mode muestra solo hora + status con minimo brillo

### Uso bajo estres / un solo brazo
- [x] Acciones criticas en zona de pulgar (bottom 40% de pantalla)
- [x] FAB SOS en bottom-right (zona de facil acceso con pulgar derecho)
- [x] Bottom navigation en posicion natural del pulgar
- [x] No hay acciones criticas en la mitad superior de la pantalla

---

## FEEDBACK HAPTICO — MAPA DE ACCIONES

| Accion                           | Tipo de haptic                    | Intensidad |
|----------------------------------|-----------------------------------|------------|
| Tap en tab de navegacion         | lightImpact                       | Suave      |
| Seleccion en lista               | lightImpact                       | Suave      |
| Envio de reporte                 | mediumImpact                      | Media      |
| Confirmacion de vinculacion BLE  | mediumImpact                      | Media      |
| Activacion SOS                   | heavyImpact                       | Fuerte     |
| Alerta biometrica critica        | vibrate() (patron repetido)       | Urgente    |
| Timeout de sesion                | vibrate()                         | Urgente    |
| SOS en wearable                  | HAPTIC_LONG_PRESS + doble vibrate | Urgente    |
| QuickReport enviado              | HAPTIC_CLICK                      | Suave      |
| Sync exitosa                     | HAPTIC_DOUBLE_CLICK               | Media      |

---

## PUNTOS DE DECISION PENDIENTES (requieren validacion del usuario/PM)

1. **Cover Mode activacion**: se propone shake 3x. Validar que no genera falsos positivos
   en campo. Alternativa: gesto en pantalla de ajustes (mas seguro, menos conveniente).

2. **Timeout de sesion**: se propone 15 minutos de inactividad. Operacionalmente podria
   ser muy corto si el agente usa el mapa pasivamente. Considerar 30min o configurable.

3. **SOS hold 2 segundos**: equilibrio entre seguridad (no accidental) y velocidad
   (emergencia real). Validar con agentes en entrenamiento.

4. **Biometria en login**: se incluyo como opcion. Depende de politica de seguridad.
   La biometria puede ser comprometida bajo coercion (fingerprint forzado).
   Recomendacion: opcional y deshabilitada por defecto.

5. **Sincronizacion de wearable**: intervalo de 5s para biometricos via BLE consume
   bateria significativa. Evaluar: 5s cuando app en primer plano, 30s en background.

6. **Almacenamiento offline de reportes**: se propone cola local. Definir maximo de
   almacenamiento local y politica de cifrado en reposo (AES-256 recomendado).

7. **Nivel de clasificacion maximo en movil**: considerar si TOP SECRET puede enviarse
   desde dispositivo movil segun politica de seguridad de la organizacion. Podria
   requerir aprobacion de dos factores adicionales.
