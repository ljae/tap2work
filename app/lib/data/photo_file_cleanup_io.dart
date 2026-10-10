import 'dart:io';

Future<void> deleteTemporaryPhoto(String path) async {
  // image_picker's mobile results are application-cache copies, never albums.
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // The OS also purges this cache. Never turn a successful conversion into
    // a failed edit when the plugin/OS has already removed its temporary file.
  }
}
