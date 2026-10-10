import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tap2work/data/photo_capture_service.dart';
import 'package:tap2work/data/photo_optimizer.dart';
import 'photo_capture_service_test.dart' show RecordingPicker;
import 'support/photo_blob_stub.dart'
    if (dart.library.js_interop) 'support/photo_blob_web.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'web keeps a single bounded input and revokes it after optimized conversion',
    () async {
      final input = img.Image(width: 80, height: 40);
      input.exif.imageIfd.orientation = 6;
      input.exif.imageIfd.imageDescription = 'synthetic fixture only';
      final bytes = img.encodeJpg(input);
      final url = createFixtureBlob(bytes);
      expect(await canReadFixtureBlob(url), true);
      final picker = RecordingPicker()
        ..result = XFile(url, length: bytes.length, mimeType: 'image/jpeg');
      final result = await PhotoCaptureService(
        picker: picker,
      ).pick(PhotoSource.camera);
      expect((picker.width, picker.height, picker.quality), (null, null, null));
      expect(picker.metadata, false);
      expect((result!.width, result.height), (40, 80));
      expect(result.bytes.length, lessThanOrEqualTo(photoMaxBytes));
      expect(String.fromCharCodes(result.bytes), isNot(contains('Exif')));
      expect(await canReadFixtureBlob(url), false);
    },
    skip: !kIsWeb,
  );

  test(
    'web rejects bad and oversized photos and releases their Blob URL',
    () async {
      for (final bytes in [
        Uint8List.fromList([1, 2, 3]),
        Uint8List(photoMaxInputBytes + 1),
      ]) {
        final url = createFixtureBlob(bytes);
        expect(await canReadFixtureBlob(url), true);
        final picker = RecordingPicker()
          ..result = XFile(url, length: bytes.length, mimeType: 'image/jpeg');
        await expectLater(
          PhotoCaptureService(picker: picker).pick(PhotoSource.gallery),
          throwsA(isA<PhotoException>()),
        );
        expect((picker.width, picker.height), (null, null));
        expect(await canReadFixtureBlob(url), false);
      }
    },
    skip: !kIsWeb,
  );
}
