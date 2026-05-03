import 'dart:io';
import 'package:whisper_flutter/whisper_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Multimodal intelligence: audio transcription (Whisper) and image classification (YOLO)
class MultimodalService {
  Whisper? _whisper;
  Interpreter? _yoloInterpreter;
  static const String _whisperModelAsset = 'assets/whisper-tiny.bin';
  static const String _yoloModelAsset = 'assets/yolov8n.tflite';

  /// Initialize Whisper and YOLO models
  Future<void> initialize() async {
    _whisper = await Whisper.loadModelFromAsset(_whisperModelAsset);
    _yoloInterpreter = await Interpreter.fromAsset(_yoloModelAsset);
  }

  /// Transcribe audio file using Whisper
  Future<String> transcribeAudio(File audioFile) async {
    if (_whisper == null) await initialize();
    final result = await _whisper!.transcribe(
      audioFile.path,
      language: 'en',
      model: WhisperModel.tiny,
    );
    return result.text ?? '';
  }

  /// Classify image using YOLO
  Future<List<Map<String, dynamic>>> classifyImage(File imageFile) async {
    if (_yoloInterpreter == null) await initialize();
    
    final image = img.decodeImage(await imageFile.readAsBytes())!;
    final resized = img.copyResize(image, width: 640, height: 640);
    
    // Prepare input tensor
    final input = _prepareImageInput(resized);
    final output = List.filled(1 * 25200 * 85, 0).reshape([1, 25200, 85]);
    
    _yoloInterpreter!.run(input, output);
    
    // Parse YOLO output (simplified)
    final results = <Map<String, dynamic>>[];
    for (final detection in output[0]) {
      final confidence = detection[4];
      if (confidence > 0.5) {
        final classId = detection.sublist(5).indexOf(detection.sublist(5).reduce((a, b) => a > b ? a : b));
        results.add({
          'label': 'class_$classId',
          'confidence': confidence,
          'bbox': detection.sublist(0, 4),
        });
      }
    }
    return results;
  }

  /// Prepare image for YOLO input
  List<List<List<List<double>>>> _prepareImageInput(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(
          640,
          (x) {
            final pixel = image.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );
    return input;
  }

  /// Clean up resources
  void dispose() {
    _whisper?.dispose();
    _yoloInterpreter?.close();
  }
}
