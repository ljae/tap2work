import 'operations_repository.dart';

/// Translation is a read operation and must never replace an operations snapshot.
abstract interface class ContentTranslationRepository {
  Future<Json> translateContent({
    required String actorId,
    required String workspaceId,
    required String targetLocale,
    required String kind,
    String? id,
  });
}
