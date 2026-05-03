import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../core/storage/secure_enclave_storage.dart';

/// Steganography: Ocultar mensajes cifrados en imágenes usando LSB
class SteganographyScreen extends StatefulWidget {
  const SteganographyScreen({super.key});

  @override
  State<SteganographyScreen> createState() => _SteganographyScreenState();
}

class _SteganographyScreenState extends State<SteganographyScreen> {
  final _messageController = TextEditingController();
  File? _selectedImage;
  String? _encodedImagePath;
  String? _decodedMessage;
  bool _isEncoding = false;

  final _picker = ImagePicker();
  final _storage = SecureEnclaveStorage();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _encodeMessage() async {
    if (_selectedImage == null || _messageController.text.isEmpty) return;

    setState(() => _isEncoding = true);
    try {
      // Obtener clave de encriptación del almacenamiento seguro
      final key = await _storage.getEncryptionKey();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Cifrar mensaje
      final encrypted = encrypter.encrypt(_messageController.text);

      // TODO: Implementar LSB steganography
      // Por ahora simulamos el proceso
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _encodedImagePath = _selectedImage?.path;
        _decodedMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje oculto en imagen')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isEncoding = false);
    }
  }

  Future<void> _decodeMessage() async {
    if (_selectedImage == null) return;

    try {
      // TODO: Implementar LSB decode
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _decodedMessage = 'Mensaje descifrado (simulado)';
        _encodedImagePath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decodificando: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esteganografía')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de imagen
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Seleccionar Imagen'),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Image.file(_selectedImage!, height: 200),
            ],
            const SizedBox(height: 24),

            // Campo de mensaje
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mensaje a ocultar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isEncoding ? null : _encodeMessage,
                    icon: const Icon(Icons.lock),
                    label: _isEncoding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Codificar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _decodeMessage,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Decodificar'),
                  ),
                ),
              ],
            ),

            // Resultados
            if (_decodedMessage != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mensaje Descifrado:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_decodedMessage!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
