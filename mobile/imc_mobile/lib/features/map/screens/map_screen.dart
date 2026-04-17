import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/colors.dart';
import '../../../services/location_service.dart';
import '../widgets/location_pin.dart';

class _MarkerData {
  const _MarkerData({
    required this.point,
    required this.variant,
    required this.label,
  });

  final LatLng point;
  final LocationPinVariant variant;
  final String label;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  LatLng? _currentPosition;
  final List<_MarkerData> _markers = [];
  bool _panelExpanded = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentPosition!, 14);
    }

    _positionSub = LocationService.positionStream().listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _markCurrentPoint() {
    if (_currentPosition == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _markers.add(_MarkerData(
        point: _currentPosition!,
        variant: LocationPinVariant.intel,
        label: 'INT-${_markers.length + 1}',
      ));
    });
  }

  void _markDeadDrop() {
    if (_currentPosition == null) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _markers.add(_MarkerData(
        point: _currentPosition!,
        variant: LocationPinVariant.deadDrop,
        label: 'DD-${_markers.length + 1}',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'FIELD MAP',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            color: AppColors.accentCyan,
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(_currentPosition!, 14);
              }
            },
            tooltip: 'Center on current location',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition ?? const LatLng(40.4168, -3.7038),
              initialZoom: 14,
              backgroundColor: const Color(0xFF0A0E1A),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.imc.mobile',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 48,
                      height: 56,
                      child: _PulsingCurrentPin(),
                    ),
                  ..._markers.map(
                    (m) => Marker(
                      point: m.point,
                      width: 48,
                      height: 64,
                      child: LocationPin(
                        variant: m.variant,
                        label: m.label,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Action buttons top-right
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MapActionButton(
                  label: 'MARK POINT',
                  icon: Icons.push_pin_outlined,
                  color: AppColors.warning,
                  onPressed: _markCurrentPoint,
                ),
                const SizedBox(height: 8),
                _MapActionButton(
                  label: 'DEAD DROP',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.danger,
                  onPressed: _markDeadDrop,
                ),
              ],
            ),
          ),
          // Bottom coordinate panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CoordinatePanel(
              position: _currentPosition,
              expanded: _panelExpanded,
              onToggle: () =>
                  setState(() => _panelExpanded = !_panelExpanded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingCurrentPin extends StatefulWidget {
  @override
  State<_PulsingCurrentPin> createState() => _PulsingCurrentPinState();
}

class _PulsingCurrentPinState extends State<_PulsingCurrentPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const LocationPin(variant: LocationPinVariant.current),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinatePanel extends StatelessWidget {
  const _CoordinatePanel({
    required this.position,
    required this.expanded,
    required this.onToggle,
  });

  final LatLng? position;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: expanded ? 120 : 52,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed,
                    size: 14,
                    color: AppColors.accentCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CURRENT POSITION',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                _CoordRow(
                  label: 'LAT',
                  value: position != null
                      ? position!.latitude.toStringAsFixed(6)
                      : '---',
                ),
                const SizedBox(height: 4),
                _CoordRow(
                  label: 'LON',
                  value: position != null
                      ? position!.longitude.toStringAsFixed(6)
                      : '---',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.accentCyan,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
