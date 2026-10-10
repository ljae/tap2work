import 'dart:typed_data';

String createFixtureBlob(Uint8List bytes) =>
    throw UnsupportedError('Browser only');
Future<bool> canReadFixtureBlob(String path) async => false;
int photoPickerInputCount() => 0;
String? photoPickerCaptureAttribute() => null;
void cancelPhotoPickerInput() {}
void registerRealWebPhotoPicker() {}
