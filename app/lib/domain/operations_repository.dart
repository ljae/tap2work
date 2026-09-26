typedef Json = Map<String, dynamic>;

/// Transitional snapshot contract; independent of Flutter and HTTP clients.
/// Feature entities can replace JSON incrementally without changing storage.
class OperationsResult {
  const OperationsResult(this.statusCode, this.data);
  final int statusCode;
  final Json data;
}

abstract interface class OperationsRepository {
  Future<OperationsResult> read({required String actorId, String? demoToken});
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  });
  void close();
}
