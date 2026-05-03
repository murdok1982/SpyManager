import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Mesh networking service for device-to-device communication
class MeshService {
  static const String _meshServiceUuid = '12345678-1234-1234-1234-1234567890ab';
  static const String _meshCharUuid = 'abcdefab-1234-1234-1234-abcdefabcdef';
  final List<BluetoothDevice> _connectedNodes = [];
  StreamSubscription? _scanSubscription;
  StreamSubscription? _advertisingSubscription;

  /// Start mesh networking (advertising and scanning)
  Future<void> startMesh() async {
    // Start BLE advertising
    await FlutterBluePlus.startAdvertising(
      AdvertiseData(
        serviceUuids: [_meshServiceUuid],
        localName: 'SpyManagerMesh',
        timeout: const Duration(hours: 1),
      ),
    );

    // Start scanning for other mesh nodes
    _scanSubscription = FlutterBluePlus.scanResults.listen(_handleScanResult);
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 30),
      withServices: [_meshServiceUuid],
    );
  }

  /// Handle discovered mesh nodes
  void _handleScanResult(List<ScanResult> results) {
    for (final result in results) {
      if (result.advertisementData.serviceUuids.contains(_meshServiceUuid)) {
        _connectToNode(result.device);
      }
    }
  }

  /// Connect to a mesh node
  Future<void> _connectToNode(BluetoothDevice device) async {
    if (_connectedNodes.contains(device)) return;
    
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedNodes.add(device);
      
      // Discover services
      final services = await device.discoverServices();
      final meshService = services.firstWhere(
        (s) => s.uuid.toString() == _meshServiceUuid,
        orElse: () => throw Exception('Mesh service not found'),
      );
      
      // Get mesh characteristic
      final meshChar = meshService.characteristics.firstWhere(
        (c) => c.uuid.toString() == _meshCharUuid,
        orElse: () => throw Exception('Mesh characteristic not found'),
      );
      
      // Listen for incoming messages
      meshChar.value.listen(_handleIncomingMessage);
      
      // Subscribe to notifications
      await meshChar.setNotifyValue(true);
    } catch (e) {
      debugPrint('Failed to connect to mesh node: $e');
    }
  }

  /// Handle incoming mesh message
  void _handleIncomingMessage(List<int> value) {
    final message = String.fromCharCodes(value);
    debugPrint('Received mesh message: $message');
    // Forward message to all connected nodes
    _broadcastMessage(message);
  }

  /// Broadcast message to all connected mesh nodes
  Future<void> _broadcastMessage(String message) async {
    final bytes = message.codeUnits;
    for (final node in _connectedNodes) {
      try {
        final services = await node.discoverServices();
        final meshService = services.firstWhere(
          (s) => s.uuid.toString() == _meshServiceUuid,
        );
        final meshChar = meshService.characteristics.firstWhere(
          (c) => c.uuid.toString() == _meshCharUuid,
        );
        await meshChar.write(bytes);
      } catch (e) {
        debugPrint('Failed to broadcast to node: $e');
      }
    }
  }

  /// Send message via mesh network
  Future<void> sendMessage(String message) async {
    await _broadcastMessage(message);
  }

  /// Stop mesh networking
  Future<void> stopMesh() async {
    await _scanSubscription?.cancel();
    await _advertisingSubscription?.cancel();
    for (final node in _connectedNodes) {
      await node.disconnect();
    }
    _connectedNodes.clear();
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.stopAdvertising();
  }
}
