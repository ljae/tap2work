import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../state/operations_controller.dart';

const printLanguages = {
  'ko': '한국어',
  'en': 'English',
  'vi': 'Tiếng Việt',
  'zh-Hans': '중국어(간체)',
  'ja': '일본어',
};
const printLabels = {
  'ko': [
    '체크리스트',
    '운영 매뉴얼',
    '날짜',
    '담당자',
    '확인',
    '메모',
    '원문',
    '번역 필요',
    '번역 재확인 필요',
    '공통·미지정',
    '파트',
    '장소',
    '폴더',
    '주의',
    '참고 자료',
  ],
  'en': [
    'Checklist',
    'Operations manual',
    'Date',
    'Name',
    'Check',
    'Notes',
    'Original',
    'Translation needed',
    'Translation needs review',
    'Common / Unassigned',
    'Part',
    'Place',
    'Folder',
    'Tip',
    'References',
  ],
  'zh-Hans': [
    '检查清单',
    '操作手册',
    '日期',
    '负责人',
    '确认',
    '备注',
    '原文',
    '需要翻译',
    '翻译需要复核',
    '通用 / 未分配',
    '部门',
    '地点',
    '文件夹',
    '提示',
    '参考资料',
  ],
  'ja': [
    'チェックリスト',
    '業務マニュアル',
    '日付',
    '担当者',
    '確認',
    'メモ',
    '原文',
    '翻訳が必要',
    '翻訳の再確認が必要',
    '共通 / 未指定',
    '部門',
    '場所',
    'フォルダー',
    '注意',
    '参考資料',
  ],
  'vi': [
    'Danh sách kiểm tra',
    'Hướng dẫn vận hành',
    'Ngày',
    'Người phụ trách',
    'Kiểm tra',
    'Ghi chú',
    'Bản gốc',
    'Cần bản dịch',
    'Cần kiểm tra lại bản dịch',
    'Chung / Chưa phân công',
    'Bộ phận',
    'Khu vực',
    'Thư mục',
    'Lưu ý',
    'Tài liệu tham khảo',
  ],
};
List<Json> printRows(dynamic value) =>
    (value as List? ?? []).whereType<Json>().toList();
List<Json> manualPrintSources(Json data) {
  if (data['manualPrintTemplates'] is List) {
    return printRows(data['manualPrintTemplates']).map((metadata) {
      final template = printRows(
        data['taskTemplates'],
      ).where((t) => t['id'] == metadata['id']).firstOrNull;
      final steps = template == null
          ? printRows(data['manualSearch'])
                .where((s) => s['templateId'] == metadata['id'])
                .map((s) => <String, dynamic>{...s, 'id': s['sourceStepId']})
                .toList()
          : printRows(template['steps'])
                .map(
                  (s) => <String, dynamic>{
                    ...s,
                    'title': s['manualTitle'] ?? s['title'],
                  },
                )
                .toList();
      return <String, dynamic>{...metadata, 'steps': steps};
    }).toList();
  }
  return printRows(data['taskTemplates'])
      .where(
        (t) =>
            t['archivedAt'] == null &&
            (t['folderId'] != 'order-work' || t['menuManualId'] != null),
      )
      .map((t) {
        final content = <String, dynamic>{
          'title': t['manualTitle'] ?? t['title'],
          'steps': printRows(t['steps'])
              .map(
                (s) => <String, dynamic>{
                  'id': s['id'],
                  'title': s['manualTitle'] ?? s['title'],
                  'manual': s['manual'] ?? '',
                  'tip': s['tip'] ?? '',
                  'sourceUrl': s['sourceUrl'] ?? '',
                  'imageUrl': s['imageUrl'] ?? '',
                  'videoUrl': s['videoUrl'] ?? '',
                },
              )
              .toList(),
        };
        return <String, dynamic>{
          'id': t['id'],
          ...content,
          'sourceHash': sha256
              .convert(utf8.encode(jsonEncode(content)))
              .toString(),
          'version': t['version'] ?? 1,
          'folderId': t['folderId'] ?? 'general',
          'folderName':
              printRows(
                data['checklistFolders'],
              ).where((f) => f['id'] == t['folderId']).firstOrNull?['name'] ??
              '기본 업무',
          'partId': t['settings']?['assignment']?['mode'] == 'scheduled'
              ? t['settings']['assignment']['partId']
              : t['partId'],
          'zoneId': t['zone'],
          'menuManualId': t['menuManualId'],
          'translations': data['manualPrintTranslations']?[t['id']] ?? {},
        };
      })
      .toList();
}

String translationState(Json source, String locale) {
  if (locale == 'ko') return 'original';
  final t = source['translations']?[locale];
  if (t == null) return 'missing';
  return t['sourceHash'] == source['sourceHash'] ? 'ready' : 'stale';
}

Json translatedPrintContent(Json source, String locale) =>
    translationState(source, locale) == 'ready'
    ? source['translations'][locale] as Json
    : source;
String printGroupId(Json source, String groupBy) =>
    '${source[groupBy == 'part'
            ? 'partId'
            : groupBy == 'zone'
            ? 'zoneId'
            : 'folderId'] ?? ''}';
String printGroupName(Json source, String groupBy, Json data, String locale) {
  final id = printGroupId(source, groupBy);
  if (id.isEmpty) return printLabels[locale]![9];
  if (groupBy == 'folder') return source['folderName'] ?? id;
  final rows = printRows(
    groupBy == 'zone' ? data['zones'] : data['workplace']?['parts'],
  );
  return rows.where((r) => r['id'] == id).firstOrNull?['name'] ?? id;
}

class ManualPrintOptions {
  const ManualPrintOptions({
    this.locale = 'ko',
    this.groupBy = 'part',
    this.format = 'both',
    this.paper = 'a4',
    this.bilingual = true,
  });
  final String locale, groupBy, format, paper;
  final bool bilingual;
}
