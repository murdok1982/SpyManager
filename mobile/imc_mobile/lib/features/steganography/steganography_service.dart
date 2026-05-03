import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../core/encryption/encryption_service.dart';

/// LSB Steganography service for hiding messages in images
class SteganographyService {
  final EncryptionService _encryptionService;
  static const int _bitsPerChannel = 1; // LSB only

  SteganographyService(this._encryptionService);

  /// Encode encrypted message into image using LSB steganography
  Future<File> encodeMessage(File imageFile, String message) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception('Invalid image file');

    // Encrypt message first
    final encrypted = await _encryptionService.encrypt(message);
    final messageBytes = encrypted.codeUnits;
    
    // Calculate max capacity (3 channels * width * height * bitsPerChannel / 8 bits per byte)
    final maxBytes = (image.width * image.height * 3 * _bitsPerChannel) ~/ 8;
    if (messageBytes.length + 4 > maxBytes) { // +4 for length prefix
      throw Exception('Message too long for image capacity');
    }

    // Encode message length first (32-bit integer)
    final lengthBytes = _intToBytes(messageBytes.length);
    _encodeBytes(image, lengthBytes);

    // Encode message bytes
    _encodeBytes(image, messageBytes);

    // Save encoded image
    final encodedImage = img.encodePng(image);
    final outputFile = File('${imageFile.parent.path}/encoded_${imageFile.uri.pathSegments.last}');
    await outputFile.writeAsBytes(encodedImage);
    return outputFile;
  }

  /// Decode message from image using LSB steganography
  Future<String> decodeMessage(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception('Invalid image file');

    // Decode message length (first 32 bits)
    final lengthBytes = _decodeBytes(image, 0, 4);
    final messageLength = _bytesToInt(lengthBytes);

    // Decode message bytes
    final messageBytes = _decodeBytes(image, 4, messageLength);
    final encrypted = String.fromCharCodes(messageBytes);

    // Decrypt message
    return await _encryptionService.decrypt(encrypted);
  }

  /// Encode bytes into image LSBs
  void _encodeBytes(img.Image image, List<int> bytes) {
    int byteIndex = 0;
    int bitIndex = 0;
    bool lengthEncoded = false;
    int totalBits = bytes.length * 8;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Encode R channel
        if (byteIndex < bytes.length) {
          final bit = (bytes[byteIndex] >> bitIndex) & 1;
          var r = pixel.r.toInt();
          r = (r & 0xFE) | bit; // Set LSB
          image.setPixelRgba(x, y, r, pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
          
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        // Encode G channel
        if (byteIndex < bytes.length) {
          final bit = (bytes[byteIndex] >> bitIndex) & 1;
          var g = pixel.g.toInt();
          g = (g & 0xFE) | bit;
          image.setPixelRgba(x, y, pixel.r.toInt(), g, pixel.b.toInt(), pixel.a.toInt());
          
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        // Encode B channel
        if (byteIndex < bytes.length) {
          final bit = (bytes[byteIndex] >> bitIndex) & 1;
          var b = pixel.b.toInt();
          b = (b & 0xFE) | bit;
          image.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), b, pixel.b.toInt());
          
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        if (byteIndex >= bytes.length) return;
      }
    }
  }

  /// Decode bytes from image LSBs
  List<int> _decodeBytes(img.Image image, int startByte, int length) {
    final bytes = List<int>.filled(length, 0);
    int byteIndex = 0;
    int bitIndex = 0;
    int totalBits = length * 8;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (byteIndex >= length) break;
        final pixel = image.getPixel(x, y);
        
        // Decode R channel
        if (byteIndex < length) {
          final bit = pixel.r.toInt() & 1;
          bytes[byteIndex] |= (bit << bitIndex);
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        // Decode G channel
        if (byteIndex < length) {
          final bit = pixel.g.toInt() & 1;
          bytes[byteIndex] |= (bit << bitIndex);
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        // Decode B channel
        if (byteIndex < length) {
          final bit = pixel.b.toInt() & 1;
          bytes[byteIndex] |= (bit << bitIndex);
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            byteIndex++;
          }
        }

        if (byteIndex >= length) break;
      }
      if (byteIndex >= length) break;
    }
    return bytes;
  }

  /// Convert integer to 4-byte list
  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  /// Convert 4-byte list to integer
  int _bytesToInt(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
}
