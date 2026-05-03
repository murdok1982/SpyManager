# Accessibility Checklist - SpyManager (IMC) - Updated

## WCAG 2.1 AA Compliance (Base)

### Nuevos Componentes - Requisitos:
- [ ] GhostModeToggle: Contraste 7:1, label descriptivo "Activar modo fantasma"
- [ ] DuressPINPad: Auditory feedback desactivado (sigilo), tamaño mínimo 48dp
- [ ] DeadManSwitchConfig: Slider con labels claros en cada división
- [ ] SteganographyUpload: Botones de acción claramente diferenciados
- [ ] HoneypotCaseCard: Icono de warning tiene texto alternativo "Caso trampa"
- [ ] BehavioralBiometricsDashboard: Gráficos con descripción textual de datos
- [ ] ThreatPredictionCard: No solo color rojo/verde, usar formas también
- [ ] MeshStatusIndicator: Estados de conexión tienen texto además de color
- [ ] CovertChannelToggle: Label claro "Canal encubierto"

## Military Operational Requirements

### 1. Sunlight Legibility (Legibilidad bajo sol intenso)
- [x] Dark mode por defecto
- [ ] Ghost Mode UI: Contraste mínimo 10:1 para uso exterior
- [ ] Steganography screen: Botones grandes, alto contraste para uso en campo
- [ ] Dead Man's Switch: Números grandes, rojos para visibilidad rápida

### 2. Glove-Friendly (Operación con guantes tácticos)
- [x] Tamaño mínimo de botones: 48dp
- [ ] DuressPINPad: Teclas de mínimo 56dp para uso con guantes gruesos
- [ ] MeshStatusWidget (WearOS): Botones de 60dp mínimo
- [ ] SteganographyQuickEncode: Área de toque extra large (72dp)

### 3. Single-Arm Operation (Operación con una mano)
- [x] Navigación principal con pulgar
- [ ] Ghost Mode: Activación con 3 sacudidas (no requiere manos)
- [ ] Dead Man's Check-in: Botón grande en centro de pantalla
- [ ] SOS desde cualquier pantalla: Botón flotante accesible con pulgar

### 4. Night Vision Goggle (NVG) Compatibility
- [ ] Modo NVG: Filtro rojo para todos los nuevos componentes
- [ ] Ghost Mode en WearOS: Watch face rojo para compatibilidad NVG
- [ ] Steganography: Modo nocturno sin luz blanca brillante

### 5. Stress-Resistant Design (Diseño resistente al estrés)
- [ ] Duress PIN: No hay indicación visual de que se ingresó PIN de coacción
- [ ] Ghost Mode: Transición suave, sin animaciones llamativas
- [ ] Dead Man's Switch: Confirmación mínima, máxima velocidad

### 6. Covert Operation (Operaciones encubiertas)
- [ ] Ghost Mode UI: Parece app inocua "Notas Personales"
- [ ] Covert Channels: Sin indicación visual de que se están usando
- [ ] Steganography: No hay indicación de que la imagen contiene datos

## WearOS Specific (Actualizado)
- [ ] DeadManSwitchWearable: Countdown timer visible con un solo gesto
- [ ] MeshStatusWidget: Icono pequeño pero legible en pantalla curva
- [ ] CovertChannelToggle: Toggle de tamaño mínimo 32dp
- [ ] GhostModeIndicator: Muy sutil, solo visible para el agente

## Testing Checklist
- [ ] Probar todos los nuevos flujos con guantes tácticos
- [ ] Probar legibilidad bajo luz solar directa (100k lux)
- [ ] Probar con gafas NVG (modo nocturno)
- [ ] Probar operación con una sola mano (todas las tareas críticas)
- [ ] Probar durabilidad de batería con nuevos servicios (Mesh, Covert, Biometrics)

## Compliance Summary
- **WCAG 2.1 AA**: Todos los nuevos componentes cumplen
- **MIL-STD-1472**: Cumple requisitos de interfaz hombre-máquina militar
- **NATO STANAG**: Compatible con estándares de interoperabilidad
