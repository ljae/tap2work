import 'dart:io';
import '../test/support/checklist_draft_cases.dart';

void main() {
  final checks = runChecklistDraftChecks();
  stdout.writeln('Checklist draft rules: $checks checks passed.');
}
