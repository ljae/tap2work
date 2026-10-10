import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tap2work/data/photo_optimizer.dart';
import 'package:tap2work/domain/optimized_photo.dart';

void main() {
  test('large camera original is optimized rather than rejected at 350KB', () {
    final original = img.Image(width: 1800, height: 1400);
    final random = Random(5);
    for (final p in original) {
      p.setRgb(random.nextInt(256), random.nextInt(256), random.nextInt(256));
    }
    final input = img.encodeJpg(original, quality: 95);
    expect(input.length, greaterThan(350000));
    final photo = optimizePhoto(input);
    expect(photo.bytes.length, lessThanOrEqualTo(photoMaxBytes));
    expect(max(photo.width, photo.height), lessThanOrEqualTo(1280));
    expect(photo.width, lessThan(1280)); // Detailed input requires fallback.
    expect(photo.bytes.take(2), [0xff, 0xd8]);
    expect(img.decodeJpg(photo.bytes)!.width, photo.width);
  });

  test('EXIF orientation baked once; EXIF description/GPS discarded', () {
    final original = img.Image(width: 80, height: 40);
    img.fill(original, color: img.ColorRgb8(255, 0, 0));
    img.fillRect(
      original,
      x1: 40,
      y1: 0,
      x2: 79,
      y2: 39,
      color: img.ColorRgb8(0, 0, 255),
    );
    original.exif.imageIfd.orientation = 6;
    original.exif.imageIfd.imageDescription = 'fixture camera metadata';
    original.exif.gpsIfd[1] = img.IfdValueAscii('N');
    final photo = optimizePhoto(img.encodeJpg(original, quality: 95));
    expect((photo.width, photo.height), (40, 80));
    final output = img.decodeJpg(photo.bytes)!;
    expect(output.getPixel(20, 10).r, greaterThan(200));
    expect(output.getPixel(20, 70).b, greaterThan(200));
    expect(output.exif.imageIfd.hasOrientation, false);
    expect(output.exif.imageIfd.imageDescription, isNull);
    expect(output.exif.gpsIfd.isEmpty, true);
    expect(String.fromCharCodes(photo.bytes), isNot(contains('Exif')));
  });

  test('small transparent image is not upscaled and flattens on white', () {
    final input = img.Image(width: 100, height: 80, numChannels: 4);
    final photo = optimizePhoto(img.encodePng(input));
    expect((photo.width, photo.height), (100, 80));
    final p = img.decodeJpg(photo.bytes)!.getPixel(20, 20);
    expect(p.r, greaterThan(245));
    expect(p.g, greaterThan(245));
    expect(p.b, greaterThan(245));
  });

  test('bad input reports a recoverable error', () {
    for (final input in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      Uint8List.fromList([0xff, 0xd8, 0, 1, 2]),
    ]) {
      expect(() => optimizePhoto(input), throwsA(isA<PhotoException>()));
    }
  });

  test('oversized decoded header rejected before allocation', () {
    final png = img.encodePng(img.Image(width: 2, height: 2));
    // PNG IHDR width/height can be inspected without allocating huge pixels.
    final altered = Uint8List.fromList(png);
    ByteData.sublistView(altered).setUint32(16, 30000);
    expect(() => optimizePhoto(altered), throwsA(isA<PhotoException>()));
  });
}
