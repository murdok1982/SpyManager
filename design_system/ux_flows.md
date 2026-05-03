# UX Flows - SpyManager (IMC) - Actualizado

## Flujos Existentes (Actualizados)

### 1. Login → Dashboard
- [Existente] + **Nuevo**: Opción de Duress PIN (PIN secundario)
- [Existente] + **Nuevo**: Anti-Tamper check en inicio

### 2. Dashboard → Mensaje SOS
- [Existente] + **Nuevo**: Dead Man's Switch check-in al presionar SOS

### 3. Casos → Detalle de Caso
- [Existente] + **Nuevo**: Honeypot Cases (marcados con borde amarillo)
- [Existente] + **Nuevo**: Link Analysis graph (botón "Ver Relaciones")

### 4. Mapa Táctico
- [Existente] + **Nuevo**: Mesh Network nodes visibles en el mapa
- [Existente] + **Nuevo**: Covert Channel toggle en configuración del mapa

## Nuevos Flujos UX

### 5. Ghost Mode Activation
1. Usuario va a Settings → Ghost Mode toggle
2. Activa Ghost Mode
3. App se oculta del launcher (Android/iOS)
4. Para invocar: 3 sacudidas rápidas o código Morse (... --- ...)
5. Se muestra interfaz falsa "Bloc de Notas Personales"
6. Para desactivar: Secuencia inversa en settings (acceso oculto)

### 6. Duress PIN Entry
1. En pantalla de login, usuario ingresa Duress PIN (diferente al normal)
2. Sistema muestra dashboard falso (datos ficticios)
3. En segundo plano: se envía alerta silenciosa al comando
4. Todas las acciones se registran como normales en auditoría
5. Comando recibe notificación: "Agente bajo coacción"

### 7. Dead Man's Switch Configuration
1. Usuario va a Settings → Dead Man's Switch
2. Activa el switch
3. Ajusta slider: 12-168 horas (umbral)
4. Activa toggle "Auto-Wipe" (opcional)
5. Sistema inicia background service de check-in
6. Cada N horas, usuario debe hacer check-in manual
7. Si no hay check-in: alerta al comando + opcional auto-wipe

### 8. Steganography Flow
1. Usuario selecciona imagen desde galería
2. Escribe mensaje secreto
3. Presiona "Codificar"
4. App cifra mensaje (AES-256) + oculta en imagen (LSB)
5. Imagen resultante se guarda/compartir
6. Para decodificar: selecciona imagen → "Decodificar" → mensaje descifrado

### 9. Honeypot Case Access
1. Agente accede a caso marcado como Honeypot (borde amarillo)
2. Sistema registra acceso en auditoría especial
3. Alerta inmediata al comando: "Acceso a Honeypot detectado"
4. Agente ve el caso normalmente (no sabe que es trampa)
5. Comando analiza intención del agente

### 10. Mesh Network Connection
1. Usuario activa Mesh en settings
2. BLE comienza a escanear nodos cercanos
3. Nodos detectados aparecen en lista (ID del nodo)
4. Usuario selecciona nodo → envía mensaje
5. Mensaje se propaga de nodo en nodo hasta llegar al gateway
6. Estado de envío visible en MeshStatusWidget

### 11. Covert Channel Usage
1. Usuario activa Covert Channel en settings
2. Selecciona tipo: DNS TXT / ICMP / HTTP Headers
3. Escribe mensaje oculto
4. App encapsula mensaje en el protocolo seleccionado
5. Envío automático en background (sin notificar al usuario)
6. Receptor (backend) decodifica y procesa

### 12. Behavioral Biometrics Setup
1. Usuario va a Settings → Behavioral Biometrics
2. Activa recolección de datos
3. App comienza a medir: velocidad de tipeo, presión táctil, hora de uso
4. Datos se envían al backend para análisis
5. Si se detecta anomalía: alerta al comando
6. Dashboard muestra métricas en tiempo real

### 13. Threat Prediction
1. Usuario va a Dashboard → Threat Level
2. Sistema muestra nivel de riesgo (verde/amarillo/rojo)
3. Basado en: frecuencia de check-in, biometría, ubicación
4. Si es ROJO: recomendaciones de acción (cambiar ubicación, etc.)
5. Predicción se actualiza en tiempo real vía WebSockets

## WearOS UX Flows

### 14. WearOS Ghost Mode
- Mantener presionado por 5 segundos → activa Ghost Mode en wearable
- Watch face cambia a "Reloj Simple" (sin indicaciones de IMC)

### 15. WearOS Dead Man's Switch
- Botón grande "CHECK-IN" siempre visible
- Countdown timer muestra horas restantes
- Si llega a 0: vibración intensa + notificación

### 16. WearOS Steganography Quick
- Menú rápido: "Encode Image"
- Seleccionar de galería del teléfono (vía BLE)
- 1 tap para codificar mensaje corto

## Consideraciones Militares en UX
- **Sunlight legible**: Contraste mínimo 7:1 en todos los flujos nuevos
- **Operación con guantes**: Botones de mínimo 48dp en nuevos flujos
- **Una mano**: Todos los flujos nuevos son navegables con una sola mano
- **NVG Compatible**: Modo nocturno (rojo) en todos los flujos
- **Stress-resistant**: Los flujos críticos (SOS, Ghost Mode) requieren confirmación mínima
