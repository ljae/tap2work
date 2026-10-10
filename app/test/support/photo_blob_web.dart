import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
// Exercise the actual federated implementation selected by image_picker.
// Flutter's browser unit-test bootstrap does not register application plugins.
// ignore: depend_on_referenced_packages
import 'package:image_picker_for_web/image_picker_for_web.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

String createFixtureBlob(Uint8List bytes) => web.URL.createObjectURL(
  web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/jpeg')),
);

Future<bool> canReadFixtureBlob(String path) async {
  try {
    final response = await web.window.fetch(path.toJS).toDart;
    return response.ok;
  } catch (_) {
    return false;
  }
}

int photoPickerInputCount() => web.document
    .querySelectorAll('#__image_picker_web-file-input input[type="file"]')
    .length;

String? photoPickerCaptureAttribute() => web.document
    .querySelector('#__image_picker_web-file-input input[type="file"]')
    ?.getAttribute('capture');

void cancelPhotoPickerInput() => web.document
    .querySelector('#__image_picker_web-file-input input[type="file"]')
    ?.dispatchEvent(web.Event('cancel'));

void registerRealWebPhotoPicker() =>
    ImagePickerPlugin.registerWith(webPluginRegistrar);
