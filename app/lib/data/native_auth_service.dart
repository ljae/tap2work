import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInCancelled implements Exception {
  const SignInCancelled();
}

class NativeCredential {
  const NativeCredential({required this.idToken, this.nonce, this.appleCode});
  final String idToken;
  final String? nonce;
  final String? appleCode;
}

/// Platform SDKs only; session creation belongs to AuthRepository.
class NativeAuthService {
  static Future<void>? _googleInitialization;
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  bool get usesNativeApple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get usesNativeGoogle =>
      !kIsWeb &&
      [
        TargetPlatform.iOS,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform);

  Future<NativeCredential> apple() async {
    final random = Random.secure();
    final nonce = base64Url.encode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null) throw const AuthException('Apple 계정을 확인하지 못했어요.');
      return NativeCredential(
        idToken: token,
        nonce: nonce,
        appleCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  Future<NativeCredential> google() async {
    if (googleWebClientId.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            googleIosClientId.isEmpty)) {
      throw const AuthException('Google 로그인 연결을 준비 중이에요.');
    }
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? googleIosClientId
            : null,
        serverClientId: googleWebClientId,
      ));
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw const AuthException('Google 계정을 확인하지 못했어요.');
      return NativeCredential(idToken: token);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_googleInitialization != null) {
      await _googleInitialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}
