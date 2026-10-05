import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'native_auth_service.dart';

class AuthRepository {
  AuthRepository(this.client, {NativeAuthService? native})
    : native = native ?? NativeAuthService();
  final SupabaseClient client;
  final NativeAuthService native;

  Future<void> signIn(OAuthProvider provider) async {
    if (![OAuthProvider.apple, OAuthProvider.google].contains(provider)) {
      throw const AuthException('지원하지 않는 로그인 방식이에요.');
    }
    NativeCredential? credential;
    if (provider == OAuthProvider.apple && native.usesNativeApple) {
      credential = await native.apple();
    } else if (provider == OAuthProvider.google && native.usesNativeGoogle) {
      credential = await native.google();
    }
    if (credential != null) {
      await client.auth.signInWithIdToken(
        provider: provider,
        idToken: credential.idToken,
        nonce: credential.nonce,
      );
      return;
    }
    final started = await client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb
          ? 'https://tap2.work/'
          : 'com.tap2work.tap2work://login-callback',
    );
    if (!started) throw const AuthException('로그인 화면을 열지 못했어요.');
  }

  Future<void> signOut() async {
    // Clear the application session even if the platform SDK is unavailable.
    await client.auth.signOut(scope: SignOutScope.local);
    try {
      await native.signOut();
    } catch (_) {
      // Google SDK cleanup does not restore a signed-out Supabase session.
    }
  }
}
