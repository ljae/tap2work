import 'package:shared_preferences/shared_preferences.dart';

/// Device preference only. Every server request still validates membership.
class WorkspaceSelectionRepository {
  const WorkspaceSelectionRepository(this.userId);
  final String userId;
  String get key => 'selected-workspace/$userId';
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);
  Future<void> save(String workspaceId) async {
    await (await SharedPreferences.getInstance()).setString(key, workspaceId);
  }
}
