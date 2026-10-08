import '../state/operations_controller.dart';

/// Discovery metadata never changes a template's content or operating policy.
class ManualMarketCatalog {
  ManualMarketCatalog(this.data);
  final Json data;
  List<Json> get entries => (data['entries'] as List? ?? []).cast<Json>();
  List<Json> get industries =>
      (data['taxonomy']?['industries'] as List? ??
              [
                {'id': 'all', 'name': '업종 공통'},
              ])
          .cast<Json>();
  List<Json> get purposes =>
      (data['taxonomy']?['purposes'] as List? ??
              [
                {'id': 'opening', 'name': '영업·업무 준비'},
              ])
          .cast<Json>();
  List<String> industryIds(Json entry) =>
      (entry['industryIds'] as List? ?? ['all']).cast<String>();
  String scopeOf(Json entry) =>
      entry['knowledge']?['scope'] ??
      (entry['collectionId'] == 'common'
          ? 'food'
          : entry['kind'] == 'legal' || entry['collectionId'] == 'business'
          ? 'universal'
          : 'menu');
  String industryName(String id) =>
      industries.where((i) => i['id'] == id).firstOrNull?['name'] ?? '업종 공통';
  String purposeName(Json entry) =>
      purposes
          .where((p) => p['id'] == entry['purposeId'])
          .firstOrNull?['name'] ??
      '운영 업무';
  bool linked(Json entry) =>
      (entry['installed'] as List? ?? []).any((i) => i['mode'] == 'linked');
  List<Json> search({
    String query = '',
    String? industry,
    String? kind,
    String? scope,
  }) {
    String normalize(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final words = query.trim().split(RegExp(r'\s+')).map(normalize);
    return entries.where((entry) {
      if ((entry['knowledge']?['supersededBy'] as List? ?? []).isNotEmpty) {
        return false;
      }
      if (scope != null && scopeOf(entry) != scope) return false;
      final ids = industryIds(entry);
      if (industry != null && !ids.contains(industry) && !ids.contains('all')) {
        return false;
      }
      if (kind != null && (entry['kind'] ?? 'operation') != kind) return false;
      final text = normalize(
        [
          entry['title'],
          entry['collectionName'],
          entry['summary'],
          entry['applicability'],
          entry['keywords'],
          purposeName(entry),
          ...ids.map(industryName),
          for (final step in (entry['steps'] as List? ?? []))
            '${step['title']} ${step['manual']} ${step['tags']}',
        ].join(' '),
      );
      return words.every((word) {
        if (text.contains(word)) return true;
        final namedCollections = entries
            .where((e) => normalize(e['collectionName'] ?? '').contains(word))
            .toList();
        if (namedCollections.isNotEmpty) return false;
        final inferred = <String>{
          for (final i in industries)
            if ((i['keywords'] as List? ?? []).any((v) => normalize(v) == word))
              i['id'] as String,
        };
        return ids.any(inferred.contains);
      });
    }).toList();
  }
}
