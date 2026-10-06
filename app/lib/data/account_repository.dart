import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class DeletionPreview {
  const DeletionPreview({
    required this.token,
    required this.destroysWorkspace,
    required this.hasApple,
    this.workspaceName,
    this.memberCount = 0,
    this.workspaces = const [],
  });
  factory DeletionPreview.fromJson(Map<String, dynamic> json) =>
      DeletionPreview(
        token: json['confirmationToken'] as String,
        workspaces: (json['workspaces'] as List? ?? [])
            .cast<Map<String, dynamic>>(),
        destroysWorkspace: json['destroysWorkspace'] == true,
        hasApple: json['hasApple'] == true,
        workspaceName: json['workspaceName'] as String?,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      );
  final String token;
  final bool destroysWorkspace, hasApple;
  final String? workspaceName;
  final int memberCount;
  final List<Map<String, dynamic>> workspaces;
}

abstract interface class AccountRepository {
  Future<DeletionPreview> previewDeletion();
  Future<String?> deleteAccount(DeletionPreview preview);
}

class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this.auth);
  final AuthRepository auth;
  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await auth.client.functions.invoke(
        'account',
        body: body,
      );
      if (response.status != 200 || response.data is! Map) {
        throw const AuthException('계정 삭제 정보를 확인하지 못했어요.');
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      final details = error.details;
      throw AuthException(
        details is Map && details['error'] is String
            ? details['error'] as String
            : '계정 삭제 연결을 확인해 주세요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  @override
  Future<DeletionPreview> previewDeletion() async =>
      DeletionPreview.fromJson(await _invoke({'action': 'preview_delete'}));

  @override
  Future<String?> deleteAccount(DeletionPreview preview) async {
    final userId = auth.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('다시 로그인해 주세요.');
    final body = <String, dynamic>{
      'action': 'delete_account',
      'confirmationToken': preview.token,
      'confirmWorkspaceDeletion': preview.destroysWorkspace,
    };
    if (preview.hasApple) {
      if (auth.native.usesNativeApple) {
        final credential = await auth.native.apple();
        body.addAll({
          'appleCode': credential.appleCode,
          'appleClient': 'native',
        });
      } else {
        final token = auth.client.auth.currentSession?.providerRefreshToken;
        if (token == null) {
          throw const AuthException('Apple로 다시 로그인한 뒤 계정 삭제를 진행해 주세요.');
        }
        body.addAll({'appleRefreshToken': token, 'appleClient': 'web'});
      }
    }
    final result = await _invoke(body);
    if (result['deleted'] != true) {
      throw const AuthException('계정 삭제가 완료되지 않았어요. 다시 시도해 주세요.');
    }
    // Clean only backups belonging to this account, including legacy scopes.
    String? warning;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      for (final key in preferences.getKeys()) {
        if ((key.startsWith('checklist-backup:') && key.endsWith('/$userId')) ||
            key == 'selected-workspace/$userId') {
          if (!await preferences.remove(key)) {
            throw StateError('Local backup cleanup failed');
          }
        }
      }
    } catch (_) {
      warning = '계정은 삭제됐어요. 기기 백업을 지우지 못해 앱 데이터도 삭제해 주세요.';
    }
    try {
      await auth.signOut();
    } catch (_) {
      // The Auth SDK clears its local session before contacting the server.
      warning ??= '계정은 삭제됐어요. 앱을 다시 열어 로그인 상태를 확인해 주세요.';
    }
    return warning;
  }
}
