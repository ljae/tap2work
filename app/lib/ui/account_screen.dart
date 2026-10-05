import 'package:flutter/material.dart';
import '../data/account_repository.dart';
import '../state/account_controller.dart';
import 'components.dart';
import 'privacy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.repository,
    required this.onSignOut,
    this.email,
    this.onAppleReauthenticate,
  });
  final AccountRepository repository;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onAppleReauthenticate;
  final String? email;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final controller = AccountController(widget.repository);
  bool acknowledged = false, signingOut = false;
  String? sessionError;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    setState(() {
      signingOut = true;
      sessionError = null;
    });
    try {
      await widget.onSignOut();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => sessionError = '로그아웃하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final preview = controller.preview;
      final busy = controller.busy || signingOut;
      return PopScope(
        canPop: !busy,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 12),
                child: Row(
                  children: [
                    const Expanded(child: Text('내 계정', style: AppText.section)),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  children: [
                    if (widget.email != null) SelectableText(widget.email!),
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('개인정보처리방침'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openPrivacy(context),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : signOut,
                      child: Text(signingOut ? '로그아웃 중…' : '로그아웃'),
                    ),
                    const SizedBox(height: 32),
                    const Text('계정 삭제', style: AppText.section),
                    const SizedBox(height: 12),
                    const Text('삭제하면 로그인 계정과 연결된 개인정보가 삭제돼요. 이 작업은 되돌릴 수 없어요.'),
                    const SizedBox(height: 12),
                    const Text(
                      '다른 크루의 계정은 삭제되지 않아요. 직접 저장한 PDF·JSON 파일은 기기에서 별도로 삭제해 주세요. Apple 구독을 이용 중이라면 구독 취소도 별도로 진행해 주세요.',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 20),
                    if (preview == null)
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () {
                                setState(() => acknowledged = false);
                                controller.loadPreview();
                              },
                        child: Text(busy ? '삭제 범위 확인 중…' : '삭제 범위 확인'),
                      ),
                    if (preview != null) ...[
                      Information(
                        preview.destroysWorkspace
                            ? '이 매장의 유일한 사장님이에요. ${preview.workspaceName ?? '내 매장'}의 업무·매뉴얼·근무표·재고 등 모든 매장 데이터와 ${preview.memberCount}명 계정의 해당 매장 접근이 함께 삭제돼요.'
                            : '내 계정과 연결된 크루 정보·근무 및 급여 기록을 삭제해요. 공유 업무의 완료 기록은 개인 식별 정보를 지운 뒤 남겨요.',
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: acknowledged,
                        onChanged: busy
                            ? null
                            : (value) =>
                                  setState(() => acknowledged = value == true),
                        title: Text(
                          preview.destroysWorkspace
                              ? '매장 데이터와 접근도 함께 삭제하는 것을 확인했어요.'
                              : '삭제 범위를 확인했어요.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.paper,
                        ),
                        onPressed: busy || !acknowledged
                            ? null
                            : () async {
                                await controller.deleteConfirmed();
                                if (context.mounted && controller.deleted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        controller.completionWarning ??
                                            '계정이 삭제됐어요.',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        child: Text(busy ? '계정 삭제 중…' : '계정 영구 삭제'),
                      ),
                    ],
                    if (controller.error != null)
                      Information(controller.error!),
                    if (sessionError != null) Information(sessionError!),
                    if (widget.onAppleReauthenticate != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                try {
                                  await widget.onAppleReauthenticate!();
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () => sessionError =
                                          'Apple 로그인 화면을 열지 못했어요.',
                                    );
                                  }
                                }
                              },
                        child: const Text('삭제를 위해 Apple로 다시 로그인'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
