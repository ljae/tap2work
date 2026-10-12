import '../l10n/app_localizations.dart';
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
      if (mounted) setState(() => sessionError = context.t('ui.audit1481'));
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
                    Expanded(
                      child: Text(
                        context.t('ui.audit644'),
                        style: AppText.section,
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('ui.audit83'),
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
                      title: Text(context.t('ui.audit168')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openPrivacy(context),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : signOut,
                      child: Text(
                        signingOut
                            ? context.t('ui.audit645')
                            : context.t('ui.audit646'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(context.t('ui.audit169'), style: AppText.section),
                    const SizedBox(height: 12),
                    Text(context.t('ui.audit170')),
                    const SizedBox(height: 12),
                    Text(context.t('ui.audit171'), style: AppText.caption),
                    const SizedBox(height: 20),
                    if (preview == null)
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () {
                                setState(() => acknowledged = false);
                                controller.loadPreview();
                              },
                        child: Text(
                          busy
                              ? context.t('ui.audit647')
                              : context.t('ui.audit648'),
                        ),
                      ),
                    if (preview != null) ...[
                      if (preview.workspaces.length > 1)
                        Information(
                          preview.workspaces
                              .map(
                                (store) =>
                                    '${store['name']}: ${store['destroysWorkspace'] == true ? '매장 데이터와 전체 크루의 매장 접근 삭제' : '매장 유지 · 내 개인정보와 근무·급여 기록 삭제'}',
                              )
                              .join('\n'),
                        ),
                      Information(
                        preview.destroysWorkspace
                            ? context.t(
                                'ui.audit649',
                                args: {
                                  'p0':
                                      preview.workspaceName ??
                                      context.t('ui.audit1120'),
                                  'p1': preview.memberCount,
                                },
                              )
                            : context.t('ui.audit650'),
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
                              ? context.t('ui.audit651')
                              : context.t('ui.audit652'),
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
                                            context.t('ui.audit653'),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        child: Text(
                          busy
                              ? context.t('ui.audit654')
                              : context.t('ui.audit655'),
                        ),
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
                                      () => sessionError = context.t(
                                        'ui.audit1484',
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(context.t('ui.audit172')),
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
