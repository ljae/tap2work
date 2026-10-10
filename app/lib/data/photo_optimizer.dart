import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../domain/optimized_photo.dart';

/// Initial proposed technical defaults; field readability needs device review.
const photoLongEdge = 1280;
const photoTargetBytes = 150000;
const photoMaxBytes = 250000;
const photoMaxInputBytes = 32 * 1024 * 1024;
const photoMaxDecodePixels = 60 * 1000 * 1000;

OptimizedPhoto optimizePhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > photoMaxInputBytes) {
    throw const PhotoException('사진을 읽기 어려워요. 다시 찍거나 다른 사진을 선택해 주세요.');
  }
  try {
    // Restrict formats and check dimensions before allocating decoded pixels.
    final img.Decoder? decoder;
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
      decoder = img.JpegDecoder();
    } else if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      decoder = img.PngDecoder();
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      decoder = img.WebPDecoder();
    } else {
      throw const PhotoException(
        '이 사진 형식을 읽지 못했어요. JPG·PNG·WebP 사진으로 다시 선택해 주세요.',
      );
    }
    final info = decoder.startDecode(bytes);
    if (info == null || info.width < 1 || info.height < 1) {
      throw const PhotoException('사진 파일을 읽지 못했어요. 다시 선택해 주세요.');
    }
    if (info.width * info.height > photoMaxDecodePixels ||
        info.width > 20000 ||
        info.height > 20000) {
      throw const PhotoException('사진이 너무 커서 읽기 어려워요. 다시 찍거나 다른 사진을 선택해 주세요.');
    }
    if (info.numFrames > 1) {
      throw const PhotoException('움직이는 사진 대신 한 장의 사진을 선택해 주세요.');
    }
    final decoded = decoder.decodeFrame(0);
    if (decoded == null) {
      throw const PhotoException('사진 파일을 읽지 못했어요. 다시 선택해 주세요.');
    }
    final oriented = img.bakeOrientation(decoded);
    OptimizedPhoto? underLimit;
    for (final edge in [photoLongEdge, 1024, 800]) {
      final longest = math.max(oriented.width, oriented.height);
      final scale = math.min(1.0, edge / longest);
      final resized = scale == 1
          ? oriented
          : img.copyResize(
              oriented,
              width: math.max(1, (oriented.width * scale).round()),
              height: math.max(1, (oriented.height * scale).round()),
              interpolation: img.Interpolation.average,
            );
      // Fresh RGB pixels discard EXIF/GPS, ICC, comments and other metadata.
      // Flatten transparent PNG/WebP on white rather than arbitrary black.
      final clean = img.Image(width: resized.width, height: resized.height);
      img.fill(clean, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(clean, resized);
      for (final quality in [82, 74, 66, 58]) {
        final encoded = img.encodeJpg(
          clean,
          quality: quality,
          chroma: img.JpegChroma.yuv420,
        );
        final photo = OptimizedPhoto(
          bytes: encoded,
          width: clean.width,
          height: clean.height,
        );
        if (encoded.length <= photoTargetBytes) return photo;
        if (encoded.length <= photoMaxBytes) underLimit ??= photo;
      }
    }
    if (underLimit != null) return underLimit;
    throw const PhotoException(
      '사진을 작은 크기로 변환하지 못했어요. 더 가까이 찍거나 다른 사진을 선택해 주세요.',
    );
  } on PhotoException {
    rethrow;
  } catch (_) {
    throw const PhotoException('사진 파일을 읽지 못했어요. 다시 선택해 주세요.');
  }
}
