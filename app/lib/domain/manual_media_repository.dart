import 'dart:typed_data';

/// Optional authenticated transport; media does not replace an operations snapshot.
abstract interface class ManualMediaRepository {
  Future<String> uploadManualPhoto({
    required String actorId,
    required String workspaceId,
    required Uint8List bytes,
  });
  Future<Uint8List> loadManualPhoto({
    required String actorId,
    required String workspaceId,
    required String reference,
  });
}

class ManualMediaException implements Exception {
  const ManualMediaException(this.message);
  final String message;
  @override
  String toString() => message;
}

final _manualMediaPattern = RegExp(
  r'^tap2work-media:([a-zA-Z0-9-]{1,80})/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\.jpg$',
);

String? manualMediaWorkspace(String value) =>
    _manualMediaPattern.firstMatch(value)?.group(1);

bool isManualMediaReference(String value) =>
    manualMediaWorkspace(value) != null;
