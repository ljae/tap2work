import 'dart:convert';
import 'dart:typed_data';

/// The only photo bytes retained by editors or submitted to storage.
class OptimizedPhoto {
  const OptimizedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });
  final Uint8List bytes;
  final int width;
  final int height;
  String get dataUrl => 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

class PhotoException implements Exception {
  const PhotoException(this.message);
  final String message;
  @override
  String toString() => message;
}
