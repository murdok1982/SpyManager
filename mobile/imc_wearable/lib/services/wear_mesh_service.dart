import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String _wearMeshPrefix = 'IMC_WEAR_';

class WearMeshService {
  WearMeshService._();

  static final WearMeshService instance = WearMeshService._();

  bool _isScanning = false;
  bool _isAdvertising = false;
  final List<ScanResult> _nearbyDevices = [];

  List<ScanResult> get nearbyDevices => List.unmodifiable(_nearbyDevices);
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;

  Future<bool> initialize() async {
    try {
      return await FlutterBluePlus.isSupported == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> startAdvertising(String agentId) async {
    try {
      final name = '$_wearMeshPrefix$agentId';
      await FlutterBluePlus.startAdvertising(name);
      _isAdvertising = true;
    } catch (_) {}
  }

  Future<void> stopAdvertising() async {
    try {
      await FlutterBluePlus.stopAdvertising();
      _isAdvertising = false;
    } catch (_) {}
  }

  Future<void> scanForDevices() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _nearbyDevices.clear();

      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (result.device.name.startsWith(_wearMeshPrefix) ||
              result.device.name.startsWith('IMC_MESH_')) {
            _nearbyDevices.add(result);
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (_) {
    } finally {
      _isScanning = false;
    }
  }

  Future<MeshStatus> getStatus() async {
    return MeshStatus(
      isEnabled: _isAdvertising || _isScanning,
      nearbyDevices: _nearbyDevices.length,
    );
  }
}

class MeshStatus {
  const MeshStatus({
    required this.isEnabled,
    required this.nearbyDevices,
  });

  final bool isEnabled;
  final int nearbyDevices;
}
