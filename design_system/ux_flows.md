# SpyManager IMC — UX Flows
Agente: DISENO | Fecha: 2026-04-17

---

## FLUJO 1: Login con certificado PKI

**USUARIO:** Agente operativo
**OBJETIVO:** Autenticarse de forma segura en campo en menos de 10 segundos

**PANTALLAS:**

```
1. SplashScreen (1.5s)
   Fondo: #080B0F
   Logo: texto "SPY MANAGER IMC" en RobotoMono 24sp, color #00D4FF
   Subtexto: "SISTEMA CLASIFICADO — ACCESO RESTRINGIDO" 12sp, #7A8B9E
   → automatico a LoginScreen

2. LoginScreen
   Campo: Agent ID (texto, autocompletado deshabilitado)
   Campo: PIN (6 digitos, keypad numerico, sin mostrar input)
   Boton: "AUTENTICAR CON CERTIFICADO PKI" (56dp, full-width, cyan)
   Link: "Usar biometria" (si dispositivo lo soporta)
   Indicador: estado del certificado PKI (verde si valido, rojo si expirado)
   → onSuccess a Dashboard
   → onError a LoginScreen con mensaje inline (no toast)

3. Auth Error
   Mensaje inline bajo el PIN: "AUTENTICACION FALLIDA — intento 1/3"
   Color: #FF2D2D, icono advertencia
   Al 3er intento: bloqueo 5min + alerta a supervisor
   → vuelve a LoginScreen limpio despues del bloqueo

4. Dashboard
   → flujo principal
```

**CASOS EDGE:**
- Certificado PKI expirado: pantalla dedicada con instruccion de renovacion, no login
- Sin red: login offline con certificado local si existe sesion cached (max 4h)
- Timeout de sesion (15min inactivo): regresa a LoginScreen manteniendo Agent ID
- Dispositivo robado / wipe remoto: login fuerza logout de todas las sesiones, borrado local

---

## FLUJO 2: Dashboard — Flujo principal del agente

**USUARIO:** Agente operativo en campo
**OBJETIVO:** Ver estado actual, casos asignados y acceder a cualquier funcion en 2 toques

**PANTALLAS:**

```
1. Dashboard (home tab)
   Composicion de arriba a abajo:
   - AppBar: "DASHBOARD" | AgentID | clasificacion de sesion
   - StatusCard (estado del agente: ACTIVE/DARK/COMPROMISED)
   - SeccionHeader: "CASOS ACTIVOS (n)"
   - Lista: max 3 CaseListItems, boton "Ver todos"
   - SeccionHeader: "BIOMETRICOS"
   - BiometricWidget (si wearable conectado, sino placeholder)
   - FAB: SOS (posicion bottom-right, siempre visible)

   Bottom Navigation:
     Tab 1: Dashboard (icono home) — activo
     Tab 2: Casos (icono folder)
     Tab 3: Mapa (icono map)
     Tab 4: Perfil (icono person)
```

**CASOS EDGE:**
- Sin wearable conectado: BiometricWidget muestra "WEARABLE NO SINCRONIZADO" con boton "CONECTAR"
- Mas de 3 casos activos: "Ver todos X casos" en texto cyan debajo de la lista
- Estado COMPROMISED: StatusCard con glow rojo + toast persistente "MODO EMERGENCIA ACTIVO"

---

## FLUJO 3: Ver caso y anadir reporte de inteligencia

**USUARIO:** Agente operativo
**OBJETIVO:** Registrar un hallazgo de inteligencia vinculado a un caso especifico

**PANTALLAS:**

```
1. CaseList (tab Casos)
   ListView de CaseListItems con pull-to-refresh
   SearchBar en top para filtrar por ID o nombre
   → tap en item → CaseDetail

2. CaseDetail
   AppBar: CASO-XXXX | [badge clasificacion]
   Seccion: datos del caso (objetivo, operacion, prioridad)
   Seccion: "REPORTES (n)" — lista de AuditLogEntry estilo
   FAB: "+" anadir reporte
   → tap FAB → IntelReportForm (bottom sheet modal altura 90%)

3. IntelReportForm (bottom sheet)
   Handle en top
   Campos: Clasificacion (picker), Tipo (picker), Descripcion (textarea),
           Coordenadas (auto-GPS + manual), Adjuntar archivo
   Boton: "ENVIAR REPORTE CIFRADO"
   → onSubmit: cerrar sheet + toast "REPORTE ENVIADO" + entrada en lista
   → onCancel: dialogo confirmacion si hay datos escritos

4. Confirmacion envio
   Toast de 3s: "REPORTE CIFRADO ENVIADO — ID: RPT-XXXXX"
   Color: background #0D2E1A, border #00E676
   → automatico, sin interaccion requerida
```

**CASOS EDGE:**
- Sin red al enviar: guardar en cola local + indicador "PENDIENTE SYNC" en el reporte
- GPS sin senal: campo coordenadas editable manualmente, icono GPS tachado
- Clasificacion TS en formulario: dialogo adicional de confirmacion antes de envio
- Adjunto demasiado grande (>10MB): error inline "Max 10MB"

---

## FLUJO 4: Emergencia SOS

**USUARIO:** Agente en peligro
**OBJETIVO:** Activar broadcast de emergencia en 2 toques, sin error posible

**PANTALLAS:**

```
1. Boton SOS (accesible desde cualquier pantalla)
   FAB en Dashboard + Tab de escudo en Bottom Navigation
   → tap → SOSConfirmation

2. SOSConfirmation (dialogo modal)
   Fondo: semi-transparente oscuro (Color(0xCC000000))
   Titulo: "ACTIVAR EMERGENCIA" en rojo 24sp
   Subtitulo: "Esta accion notificara al comando de manera inmediata"
   Componente: BotonHoldToActivate (GestureDetector hold 2s con barra de progreso)
   Boton cancelar: ghost, texto "Cancelar"
   barrierDismissible: false
   → hold 2s completo → SOSActive

3. SOSActive (overlay fullscreen, z-index: 32)
   Background: Color(0xCC200000)
   Contenido:
     Icono advertencia 56dp, blanco
     "EMERGENCIA ACTIVA" 34sp bold blanco
     "Transmitiendo ubicacion GPS..."
     Container pulsante: "● BROADCASTING — AGT-7734 | [timestamp]"
     Boton: "CANCELAR EMERGENCIA" (borde blanco, texto blanco, 56dp)
   Haptic: HapticFeedback.heavyImpact() al activar
   Wearable: EmergencySOSScreen en paralelo via BLE
   → tap CANCELAR → SOSCancelConfirmation

4. SOSCancelConfirmation
   Dialogo: "Confirmar cancelacion de emergencia"
   Boton primario: "CONFIRMAR CANCELACION" (hold 1s)
   Boton secundario: "MANTENER ACTIVO" (regresa al overlay)
   → confirmado → vuelve a Dashboard
```

**CASOS EDGE:**
- Sin red al activar SOS: guardar timestamp + coords localmente, reintento cada 30s
- Bateria baja (<10%): notificacion adicional al comando con nivel de bateria
- SOS activado por error (en 5s): ventana de cancelacion rapida antes de broadcast completo

---

## FLUJO 5: Mapa en tiempo real

**USUARIO:** Agente / coordinador de campo
**OBJETIVO:** Ver posicion propia y puntos de interes operacionales

**PANTALLAS:**

```
1. MapScreen (tab Mapa)
   Mapa de fondo oscuro (MapLibre dark style o equivalente)
   LocationPin del agente (pulsante, cyan)
   Pines de puntos de interes registrados
   FAB: "+" anadir punto de interes
   BottomSheet colapsable: lista de pines activos
   → tap en pin → PinDetail (bottom sheet mini)
   → tap FAB → AddPinForm (bottom sheet)

2. PinDetail (bottom sheet, 30% pantalla)
   Nombre del punto
   Coordenadas en formato grado decimal y MGRS
   Tipo: POI / EXFIL / PELIGRO
   Botones: "NAVEGAR" | "EDITAR" | "ELIMINAR"
   → NAVEGAR: abre GPS externo (Google Maps / HERE) con coords

3. AddPinForm (bottom sheet, 60% pantalla)
   Campos: Nombre, Tipo (picker), Notas, Coordenadas (GPS auto)
   Boton: "MARCAR PUNTO"
   → cierra sheet + nuevo pin aparece en mapa con animacion
```

**CASOS EDGE:**
- GPS muy impreciso (>50m): advertencia "Precision baja: XXm" sobre el boton confirmar
- Modo sin GPS: coordenadas manuales con validacion de formato
- Zona restringida (futuro): overlay de area prohibida en el mapa con color danger

---

## FLUJO 6: Sincronizacion wearable

**USUARIO:** Agente operativo
**OBJETIVO:** Conectar reloj inteligente y ver biometricos en tiempo real

**PANTALLAS:**

```
1. Dashboard → tap en BiometricWidget placeholder → WearableSyncScreen

2. WearableSyncScreen
   Lista de dispositivos BLE disponibles (formato: modelo + RSSI)
   Indicador de busqueda (ProgressIndicator lineal, no circular)
   → tap en dispositivo → PairingConfirmation

3. PairingConfirmation
   "Confirmar vinculacion con: [nombre dispositivo]"
   "Verificar que el PIN en el reloj sea: XXXX"
   Botones: "VINCULAR" | "Cancelar"
   → VINCULAR → sync exitosa → vuelve a Dashboard con BiometricWidget activo

4. Sincronizado (estado en Dashboard)
   BiometricWidget muestra datos en tiempo real
   Indicador "LIVE" verde pulsante en widget
   Update cada 5 segundos via BLE GATT notify
```

**CASOS EDGE:**
- Sin BLE disponible: mensaje "Bluetooth no disponible"
- Dispositivo fuera de rango: "WEARABLE FUERA DE RANGO" + ultimo dato con timestamp
- Datos biometricos criticos: push notification local + vibration aunque app en background

---

## FLUJO WEARABLE 1: Navegacion principal

**USUARIO:** Agente operativo (reloj en muneca)
**OBJETIVO:** Acceder a cualquier funcion critica en 1 gesto + 1 tap

```
Watchface (pantalla principal)
├── Swipe RIGHT → BiometricDisplay
│                  (bpm, estres, SpO2)
│                  Swipe LEFT regresa
│
├── Swipe LEFT → QuickReport
│                  (4 botones: SAFE/COMP/INTEL/EXFIL)
│                  1 tap = reporte enviado
│                  Swipe RIGHT regresa
│
├── Swipe DOWN → LocationBeacon
│                  (coords GPS, boton compartir)
│                  Swipe UP regresa
│
├── Tap en dot central → Sync manual con mobile
│                          Haptic confirmacion
│
└── Long press corona (1.5s) → EmergencySOSScreen
                                  Desde CUALQUIER pagina
                                  Haptic: heavyImpact al activar
```

**CASOS EDGE:**
- Mobile desconectado: icono antena tachado en watchface, reporte rapido en cola local
- Bateria reloj <15%: indicador visible en watchface, sync reducida a cada 60s
- Modo avion activado: todos los indicadores de conexion en amber
- Pantalla apagada (ambient mode): mostrar solo hora, AgentID y status con minimo brillo

---

## FLUJO WEARABLE 2: Quick Report

**USUARIO:** Agente en campo, sin tiempo para abrir mobile
**OBJETIVO:** Enviar status de situacion en 1 tap

```
1. QuickReport screen (swipe left desde watchface)
   4 botones 2x2: SAFE | COMPROMISED | INTEL | EXFIL
   → tap en cualquier boton:
     a. Haptic mediumImpact
     b. Envio inmediato a servidor via mobile (BLE) o directamente (WiFi/4G si disponible)
     c. Overlay de confirmacion 1.5s (pantalla completa con checkmark)
     d. Regresa a watchface
     e. Haptic lightImpact al volver

2. Confirmacion (overlay 1.5s)
   Fondo: color del boton presionado (translucido)
   Icono check 48dp
   Texto: "ENVIADO: [tipo]"
   Timestamp: hora:minuto
   → automatico, sin accion del usuario
```

**CASOS EDGE:**
- Sin conexion al enviar: cola local, indicador pending en watchface (dot ambar)
- COMPROMISED enviado: activa alerta en mobile del coordinador automaticamente
- EXFIL enviado: marca punto GPS de exfiltracion automaticamente en el mapa mobile

---

## WIREFRAME FINAL: Layout Mobile (referencia de implementacion)

```
DASHBOARD SCREEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

StatusBar (sistema)

AppBar [56dp]:
  "DASHBOARD"  [14:23]  [AGT-7734]  [icono config]
  color: bgSurface | border bottom: borderSubtle 1dp

ScrollView (padding horizontal: 16dp, top: 8dp, bottom: 80dp):

  StatusCard [96dp min]:
    borde izq 4dp segun estado
    agentId + badge + operacion + ultimo ping + sync btn

  SizedBox [16dp]

  SectionHeader: "CASOS ACTIVOS"
    Row: [texto 18sp bold] [Spacer] ["Ver todos" 14sp cyan]

  SizedBox [8dp]

  CaseListItem #1 [96dp]
  CaseListItem #2 [96dp]
  CaseListItem #3 [96dp]

  SizedBox [16dp]

  SectionHeader: "BIOMETRICOS EN VIVO"

  SizedBox [8dp]

  BiometricWidget [120dp]

  SizedBox [80dp]  ← espacio para FAB

FAB (bottom-right, 16dp de borde):
  FloatingActionButton.extended
  background: emergency (#FF2D2D)
  label: "SOS"
  height: 48dp

Bottom Navigation [56dp]:
  Tab 1: Home icon    — "DASHBOARD"
  Tab 2: Folder icon  — "CASOS"
  Tab 3: Map icon     — "MAPA"
  Tab 4: Person icon  — "PERFIL"
  color: bgSurface | top border: borderDefault 1dp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COVER MODE (modo discrecion)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Activacion: shake 3x o gesto personalizado en ajustes
La app cambia aspecto a "Bloc de Notas Personal":
  - AppBar: "MIS NOTAS"
  - fondo: blanco (unico momento con modo claro)
  - lista de "notas" que son en realidad los cases (nombre ofuscado)
  - icono: bloc de notas en launcher
  - los datos reales siguen disponibles bajo autenticacion
  - desactivacion: misma secuencia o desde "Ajustes > Privacidad"

Implementacion: MaterialApp con theme switcher + route renaming
No modifica datos, solo la capa de presentacion
```
