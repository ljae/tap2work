import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

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
