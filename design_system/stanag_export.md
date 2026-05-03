# STANAG 5516 / Link 16 Export - UI Specs

## Propósito
Exportar intelligence packages en formato compatible con sistemas NATO (STANAG 5516 / Link 16).

## Flujo de Exportación

### 1. Selección de Inteligencia
- Usuario selecciona uno o varios IntelPackages
- Filtro por caso, clasificación, fecha
- Checkbox para selección múltiple

### 2. Configuración STANAG
- Dropdown: Formato de salida (Link 16 Message, XML, JSON)
- Campo: Track Number (ej. "A-123")
- Campo: Exercise Indicator (Real / Exercise)
- Toggle: Encriptación adicional (AES-256 extra)

### 3. Vista Previa
- Muestra mensaje formateado según STANAG 5516
- Ejemplo: `STANAG5516|A-123|2026-05-03T10:30:00|SECRET|Contenido...`
- Validación de campos requeridos

### 4. Exportación
- Botón "Exportar a SIEM"
- Botón "Descargar Archivo"
- Notificación de éxito/fallo
- Registro en auditoría: "STANAG_EXPORT"

## Componentes UI

### StanGExportButton
```dart
ElevatedButton.icon(
  onPressed: _showExportDialog,
  icon: Icon(Icons.download),
  label: Text('Export STANAG'),
  style: ElevatedButton.styleFrom(backgroundColor: AppTokens.militaryGreen),
)
```

### StanGConfigDialog
- AlertDialog con campos mencionados arriba
- Validación en tiempo real
- Botones "Cancelar" y "Exportar"

## Integración con Backend
- Endpoint: POST /api/v1/stanag/export
- Body: { intel_ids: [str], format: str, track_number: str }
- Response: { stanag_messages: [str], download_url: str }

## Accesibilidad
- Contraste 7:1 en diálogo
- Navegación por teclado en selección de inteligencia
- Labels descriptivos para lectores de pantalla
