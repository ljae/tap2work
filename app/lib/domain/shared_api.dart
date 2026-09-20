/// Resolves the shared demo API a public review build should talk to.
///
/// The public site is static; an owner can run the local console behind a
/// tunnel and share `…/app/?api=https://<tunnel-host>`. `?api=off` forgets a
/// remembered address. Only https, or http to localhost, is accepted so the
/// browser will not mix an http API into an https page.
String? resolveSharedApi({required Uri base, String? stored}) {
  final requested = base.queryParameters['api']?.trim();
  if (requested == 'off') return null;
  return normalizeSharedApi(requested) ?? normalizeSharedApi(stored);
}

bool sharedApiCleared(Uri base) => base.queryParameters['api']?.trim() == 'off';

String? normalizeSharedApi(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.isEmpty || !uri.hasAuthority) return null;
  final local = uri.host == 'localhost' || uri.host == '127.0.0.1';
  if (!(uri.scheme == 'https' || (uri.scheme == 'http' && local))) return null;
  if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
  final path = uri.path.replaceAll(RegExp(r'/+$'), '');
  return uri.replace(path: path).toString().replaceAll(RegExp(r'/+$'), '');
}
