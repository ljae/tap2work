import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tap2work/data/auth_repository.dart';
import 'package:tap2work/data/native_auth_service.dart';

class FakeNative extends NativeAuthService {
  bool cancel = false;
  @override
  bool get usesNativeApple => true;
  @override
  bool get usesNativeGoogle => true;
  @override
  Future<NativeCredential> apple() async {
    if (cancel) throw const SignInCancelled();
    return const NativeCredential(
      idToken: 'apple-id-token',
      nonce: 'raw-nonce',
      appleCode: 'server-only-delete-code',
    );
  }

  @override
  Future<NativeCredential> google() async =>
      const NativeCredential(idToken: 'google-id-token');
}

void main() {
  test(
    'native SDK tokens go to Supabase with Apple raw nonce and no client secret',
    () async {
      final requests = <Map<String, dynamic>>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'access_token': 'test-access',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': '10000000-0000-0000-0000-000000000001',
                'aud': 'authenticated',
                'created_at': '2026-10-05T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final native = FakeNative();
      final repo = AuthRepository(client, native: native);
      await repo.signIn(OAuthProvider.apple);
      expect(requests.single['id_token'], 'apple-id-token');
      expect(requests.single['nonce'], 'raw-nonce');
      expect(requests.single.containsKey('appleCode'), false);
      expect(requests.single.containsKey('client_secret'), false);
      await repo.signIn(OAuthProvider.google);
      expect(requests.last['provider'], 'google');
      expect(requests.last['id_token'], 'google-id-token');
      native.cancel = true;
      await expectLater(
        repo.signIn(OAuthProvider.apple),
        throwsA(isA<SignInCancelled>()),
      );
      expect(requests.length, 2);
    },
  );
}
