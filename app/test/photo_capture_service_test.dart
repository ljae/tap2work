import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tap2work/data/photo_capture_service.dart';

class RecordingPicker extends ImagePicker {
  ImageSource? source;
  CameraDevice? camera;
  double? width, height;
  bool? metadata;
  int? quality;
  XFile? result;
  PlatformException? error;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    camera = preferredCameraDevice;
    width = maxWidth;
    height = maxHeight;
    metadata = requestFullMetadata;
    quality = imageQuality;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'camera requests rear device without full metadata and returns only JPEG',
    () async {
      final picker = RecordingPicker()
        ..result = XFile.fromData(
          img.encodePng(img.Image(width: 60, height: 40)),
          mimeType: 'image/png',
        );
      final photo = await PhotoCaptureService(
        picker: picker,
      ).pick(PhotoSource.camera);
      expect(picker.source, ImageSource.camera);
      expect(picker.camera, CameraDevice.rear);
      expect(picker.metadata, false);
      expect(
        (picker.width, picker.height, picker.quality),
        (4096.0, 4096.0, 100),
      );
      expect(photo!.bytes.take(2), [0xff, 0xd8]);
      expect((photo.width, photo.height), (60, 40));
    },
  );

  test(
    'Android album uses one unscaled cache copy then application conversion',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final picker = RecordingPicker();
      expect(
        await PhotoCaptureService(picker: picker).pick(PhotoSource.gallery),
        isNull,
      );
      expect((picker.width, picker.height), (null, null));
      expect(picker.quality, 100);
    },
  );

  test(
    'cancellation is distinct from denied permission and corrupt image',
    () async {
      final picker = RecordingPicker();
      final service = PhotoCaptureService(picker: picker);
      expect(await service.pick(PhotoSource.camera), isNull);
      picker.error = PlatformException(code: 'camera_access_denied');
      await expectLater(
        service.pick(PhotoSource.camera),
        throwsA(
          isA<PhotoException>().having(
            (e) => e.message,
            'message',
            contains('권한'),
          ),
        ),
      );
      picker.error = null;
      picker.result = XFile.fromData(Uint8List.fromList([1, 2, 3]));
      await expectLater(
        service.pick(PhotoSource.gallery),
        throwsA(isA<PhotoException>()),
      );
    },
  );
}
