import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChecklistBackupRepository {
  Future<String?> read(String scope) async =>
      (await SharedPreferences.getInstance()).getString(
        'checklist-backup:$scope',
      );
  Future<void> save(String scope, String value) async {
    if (utf8.encode(value).length > 2000000) {
      throw const FormatException('백업은 2MB 이내로 저장해 주세요.');
    }
    if (!await (await SharedPreferences.getInstance()).setString(
      'checklist-backup:$scope',
      value,
    )) {
      throw StateError('기기에 저장하지 못했어요.');
    }
  }

  Future<bool> export(String value) async {
    final result = await FilePicker.platform.saveFile(
      fileName:
          'tap2work-checklists-${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(value)),
    );
    return kIsWeb || result != null;
  }

  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > 2000000 || file.bytes == null) {
      throw const FormatException('2MB 이내의 JSON 백업을 선택해 주세요.');
    }
    return utf8.decode(file.bytes!);
  }
}
