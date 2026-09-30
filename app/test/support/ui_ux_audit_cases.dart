import 'package:flutter/material.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/band_work_links.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';
import 'package:tap2work/ui/time_band_editor.dart';
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/work_assignment_field.dart';
import '../settings_sheet_audit_test.dart' as baseline;

const auditLongName = '가나다라마바사아자차카타파하가나다라마바사아자차카타파하가나다라마바사아자차카타';

Json sheetData({bool longNames = false}) {
  final data = baseline.sheetData();
  data['canEditTasks'] = true;
  data['workplace'] = {
    'parts': [
      {'id': 'kitchen', 'name': '주방'},
    ],
    'days': {
      '1': [
        {'id': 'audit-open', 'name': '오픈', 'start': '09:00', 'end': '14:00'},
      ],
    },
  };
  if (longNames) {
    data['workplace']['days']['1'][0]['name'] = auditLongName;
    data['tappers'][0]['nickname'] = auditLongName;
  }
  return data;
}

Map<String, Widget> sheetCases(OperationsController ops) => {
  ...baseline.sheetCases(ops),
  'band-work-links': BandWorkLinks(
    ops: ops,
    bandId: 'audit-open',
    bandName: '오픈 시간대',
  ),
  'assignment-scheduled': TapSettingsScreen(
    ops: ops,
    initialTemplateId: 'a',
    initialTimeBandId: 'audit-open',
  ),
  'assignment-crew': AppEditorScaffold(
    title: '크루 담당',
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        WorkAssignmentField(
          ops: ops,
          value: const {
            'mode': 'crew',
            'crewIds': ['crew'],
          },
          onChanged: (_) {},
        ),
      ],
    ),
  ),
  'time-band': const TimeBandEditor(
    parts: [
      {'id': 'kitchen', 'name': '주방'},
    ],
    openDays: {1, 2, 3, 4, 5},
    initialDays: {1},
  ),
};
