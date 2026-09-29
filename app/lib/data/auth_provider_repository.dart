import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public Auth capabilities; no tokens, identities or secrets are returned.
Future<Set<OAuthProvider>> configuredSocialProviders() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || key.isEmpty) return {};
  final response = await http
      .get(Uri.parse('$url/auth/v1/settings'), headers: {'apikey': key})
      .timeout(const Duration(seconds: 5));
  if (response.statusCode != 200) throw StateError('Auth settings unavailable');
  final external = (jsonDecode(response.body) as Map)['external'] as Map? ?? {};
  return {
    for (final provider in [OAuthProvider.google, OAuthProvider.apple])
      if (external[provider.name] == true) provider,
  };
}
