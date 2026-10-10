import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/optimized_photo.dart';
import 'photo_optimizer.dart';
import 'photo_file_cleanup_stub.dart'
    if (dart.library.io) 'photo_file_cleanup_io.dart'
    if (dart.library.js_interop) 'photo_file_cleanup_web.dart';
export '../domain/optimized_photo.dart';

enum PhotoSource { camera, gallery }

class PhotoCaptureService {
  PhotoCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  bool get supportsCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<OptimizedPhoto?> pick(PhotoSource source) async {
    XFile? file;
    try {
      // Android gallery resizing leaves an additional unreturned original
      // cache copy in the plugin. Optimize its single returned copy ourselves.
      // On web, skip the plugin's full image decode/canvas copy so our byte
      // and dimension guards run first and we own the single Blob URL.
      final nativeResize =
          !kIsWeb &&
          (defaultTargetPlatform != TargetPlatform.android ||
              source == PhotoSource.camera);
      file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        // Bound camera decode size; iOS picker re-encodes HEIC through UIKit.
        maxWidth: nativeResize ? 4096 : null,
        maxHeight: nativeResize ? 4096 : null,
        // Even quality=100 triggers the web plugin's canvas conversion.
        imageQuality: kIsWeb ? null : 100,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      if (await file.length() > photoMaxInputBytes) {
        throw const PhotoException('사진을 읽기 어려워요. 다시 찍거나 다른 사진을 선택해 주세요.');
      }
      final bytes = await file.readAsBytes();
      return await compute(optimizePhoto, bytes);
    } on PhotoException {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code.contains('denied') || e.code.contains('restricted')) {
        throw const PhotoException(
          '사진 사용 권한이 필요해요. 기기 설정에서 권한을 허용한 뒤 다시 시도해 주세요.',
        );
      }
      throw const PhotoException('사진을 가져오지 못했어요. 다시 시도해 주세요.');
    } catch (_) {
      throw const PhotoException('사진을 가져오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (file != null) await deleteTemporaryPhoto(file.path);
    }
  }

  /// After Android process death there is no trusted actor/workspace/draft to
  /// attach the result to. Discard it instead of silently editing another TAP.
  Future<void> discardLostData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final lost = await _picker.retrieveLostData();
      for (final file in lost.files ?? <XFile>[]) {
        await deleteTemporaryPhoto(file.path);
      }
    } catch (_) {
      // Missing recovered cache cannot affect persisted editor state.
    }
  }
}
