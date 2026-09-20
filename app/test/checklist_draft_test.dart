import 'package:flutter_test/flutter_test.dart';
import 'support/checklist_draft_cases.dart';

void main() {
  test(
    'whole-draft validation and selected reimport preserve edits and limits',
    () {
      expect(runChecklistDraftChecks(), 17);
    },
  );
}
