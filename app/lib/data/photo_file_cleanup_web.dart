import 'package:web/web.dart' as web;

Future<void> deleteTemporaryPhoto(String path) async {
  if (path.startsWith('blob:')) web.URL.revokeObjectURL(path);
}
