import 'package:web/web.dart' as web;

const _key = 'tap2work.pending-crew-invite';
String? readPendingCrewInvitation() {
  final uri = Uri.base;
  final incoming = uri.queryParameters['invite'];
  try {
    if (incoming != null) {
      if (RegExp(r'^[A-Fa-f0-9]{24}$').hasMatch(incoming)) {
        web.window.sessionStorage.setItem(
          _key,
          '${DateTime.now().millisecondsSinceEpoch}:$incoming',
        );
      }
      final query = {...uri.queryParameters}..remove('invite');
      web.window.history.replaceState(
        null,
        '',
        uri.replace(queryParameters: query).toString(),
      );
    }
    final stored = web.window.sessionStorage.getItem(_key);
    if (stored == null) return null;
    final parts = stored.split(':');
    final at = int.tryParse(parts.first);
    if (parts.length != 2 ||
        at == null ||
        DateTime.now().millisecondsSinceEpoch - at >
            const Duration(days: 7).inMilliseconds) {
      clearPendingCrewInvitation();
      return null;
    }
    return parts.last;
  } catch (_) {
    return incoming != null && RegExp(r'^[A-Fa-f0-9]{24}$').hasMatch(incoming)
        ? incoming
        : null;
  }
}

void clearPendingCrewInvitation() {
  try {
    web.window.sessionStorage.removeItem(_key);
  } catch (_) {
    /* Code input still works when browser storage is blocked. */
  }
}
