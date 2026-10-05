import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/account_repository.dart';
import '../data/native_auth_service.dart';

class AccountController extends ChangeNotifier {
  AccountController(this.repository);
  final AccountRepository repository;
  DeletionPreview? preview;
  bool busy = false, deleted = false, _disposed = false;
  String? error;
  String? completionWarning;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadPreview() async {
    if (busy) return;
    busy = true;
    error = null;
    preview = null;
    _changed();
    try {
      preview = await repository.previewDeletion();
    } catch (e) {
      error = e is AuthException ? e.message : '삭제 범위를 확인하지 못했어요. 다시 시도해 주세요.';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> deleteConfirmed() async {
    final current = preview;
    if (busy || current == null || deleted) return;
    busy = true;
    error = null;
    _changed();
    try {
      completionWarning = await repository.deleteAccount(current);
      deleted = true;
    } on SignInCancelled {
      /* Cancellation is not a completed deletion. */
    } catch (e) {
      error = e is AuthException ? e.message : '계정 삭제를 완료하지 못했어요. 다시 시도해 주세요.';
      preview = null; // A retry must fetch fresh scope and obtain confirmation.
    } finally {
      busy = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
