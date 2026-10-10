import 'store_setup_screen.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../data/auth_provider_repository.dart';
import '../data/auth_repository.dart';
import '../data/account_repository.dart';
import '../data/workspace_selection_repository.dart';
import '../data/native_auth_service.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';
import 'login_screen.dart';
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import '../state/app_locale_controller.dart';
import 'components.dart';
import '../data/pending_crew_invitation.dart';
import 'crew_invitation_screen.dart';

class CloudWorkspace extends StatefulWidget {
  const CloudWorkspace({
    super.key,
    required this.work,
    required this.client,
    this.sharedApi,
    this.loadProviders = configuredSocialProviders,
  });
  final WorkController work;
  final SupabaseClient client;
  final String? sharedApi;
  final Future<Set<OAuthProvider>> Function() loadProviders;
  @override
  State<CloudWorkspace> createState() => _CloudWorkspaceState();
}

class _CloudWorkspaceState extends State<CloudWorkspace> {
  late OperationsController ops;
  StreamSubscription<AuthState>? subscription;
  String? userId;
  bool preview = false;
  String? localeScope, lastServerLocale;
  String? pendingInvitation;
  late final auth = AuthRepository(widget.client);
  bool isSocialUser(User? user) =>
      user?.identities?.any(
        (identity) => ['apple', 'google'].contains(identity.provider),
      ) ==
      true;

  @override
  void initState() {
    super.initState();
    pendingInvitation = readPendingCrewInvitation();
    userId = isSocialUser(widget.client.auth.currentUser)
        ? widget.client.auth.currentUser?.id
        : null;
    if (widget.client.auth.currentUser != null && userId == null) {
      unawaited(auth.signOut().catchError((Object _) {}));
    }
    ops = controller();
    ops.addListener(syncLocale);
    syncLocale();
    if (userId != null) ops.start();
    subscription = widget.client.auth.onAuthStateChange.listen((state) {
      final next = isSocialUser(state.session?.user)
          ? state.session?.user.id
          : null;
      if (next == userId || !mounted) return;
      final previous = ops;
      previous.removeListener(syncLocale);
      setState(() {
        userId = next;
        preview = false;
        ops = controller();
        ops.addListener(syncLocale);
        syncLocale();
        if (userId != null) ops.start();
      });
      previous.dispose();
    });
  }

  OperationsController controller() => userId == null
      ? OperationsController(readOnly: true)
      : OperationsController(
          readOnly: false,
          loadWorkspace: WorkspaceSelectionRepository(userId!).read,
          saveWorkspace: WorkspaceSelectionRepository(userId!).save,
          endpoint: Uri.parse(
            '${const String.fromEnvironment('SUPABASE_URL')}/functions/v1/operations',
          ),
          accessToken: () async {
            var session = widget.client.auth.currentSession;
            if (session?.isExpired == true) {
              session = (await widget.client.auth.refreshSession()).session;
            }
            return session?.accessToken;
          },
        );
  Future<void> account(BuildContext context) =>
      openAccount(context, widget.client);

  void syncLocale() {
    final current = ops;
    final scope = userId == null
        ? 'guest'
        : '$userId/${current.workspaceId ?? ''}';
    final serverLocale =
        current.data?['languageContext']?['preferredLocale'] as String?;
    if (localeScope != scope) {
      localeScope = scope;
      lastServerLocale = serverLocale;
      unawaited(
        AppLocaleController.instance.bindAccount(
          userId == null ? null : scope,
          serverLanguage: serverLocale,
          saveRemote: userId == null
              ? null
              : (tag) async {
                  if (!mounted ||
                      !identical(current, ops) ||
                      localeScope != scope ||
                      current.data == null ||
                      current.data?['needsWorkspace'] == true) {
                    return;
                  }
                  final saved = await current.act('save_language_preference', {
                    'locale': tag,
                  });
                  if (!saved) {
                    throw StateError('Language preference could not be saved');
                  }
                },
        ),
      );
    } else if (serverLocale != null && serverLocale != lastServerLocale) {
      lastServerLocale = serverLocale;
      AppLocaleController.instance.adoptServerLanguage(serverLocale);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    ops.removeListener(syncLocale);
    ops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) => Tap2workApp(
      key: ValueKey(
        userId == null
            ? (preview ? 'preview' : 'sign-in')
            : '$userId/${ops.workspaceId ?? ''}',
      ),
      controller: widget.work,
      operations: ops,
      onAccountPressed: account,
      accountEmail: widget.client.auth.currentUser?.email,
      homeOverride: userId == null && !preview
          ? Builder(
              builder: (context) => LoginScreen(
                signInButtons: SocialSignInButtons(
                  onSignIn: auth.signIn,
                  loadProviders: widget.loadProviders,
                ),
                onPrivacy: () => openPrivacy(context),
                onPreview: () {
                  setState(() => preview = true);
                  ops.start();
                },
              ),
            )
          : pendingInvitation != null
          ? Builder(
              builder: (context) => CrewInvitationScreen(
                ops: ops,
                initialCode: pendingInvitation,
                onFinished: () {
                  clearPendingCrewInvitation();
                  setState(() => pendingInvitation = null);
                },
              ),
            )
          : ops.data?['needsWorkspace'] == true
          ? Builder(
              builder: (context) => _WorkspaceSetup(
                ops: ops,
                onAccount: () => openAccount(context, widget.client),
              ),
            )
          : null,
    ),
  );
}

class _WorkspaceSetup extends StatelessWidget {
  const _WorkspaceSetup({required this.ops, required this.onAccount});
  final OperationsController ops;
  final VoidCallback onAccount;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('내 매장 시작하기'),
      actions: [
        PressBounce(
          child: TextButton(onPressed: onAccount, child: const Text('계정')),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '어떤 매장으로 시작할까요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('선택한 매장은 이 계정에 저장됩니다. 빈 매장은 내 재료와 메뉴를 직접 등록할 수 있어요.'),
              const SizedBox(height: 24),
              PressBounce(
                child: FilledButton(
                  onPressed: ops.busy
                      ? null
                      : () => openStoreSetup(context, ops),
                  child: const Text('새 매장 등록'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: ops.busy
                    ? null
                    : () => showAppSheet(
                        context,
                        builder: (_) => CrewInvitationScreen(ops: ops),
                      ),
                child: Text(context.t('invite.joinCode')),
              ),
              const SizedBox(height: 12),
              PressBounce(
                child: OutlinedButton(
                  onPressed: ops.busy
                      ? null
                      : () => ops.act('create_workspace', {
                          'mode': 'sample',
                          'revision': 0,
                        }),
                  child: const Text('샘플 매장으로 체험'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '샘플 매장에는 가상 직원·주문·재고가 들어갑니다. 실제 매장 기록으로 사용하지 마세요.',
                style: TextStyle(color: AppColors.muted),
              ),
              if (ops.error != null) ...[
                const SizedBox(height: 16),
                Information(ops.error!),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> openAccount(BuildContext context, SupabaseClient client) async {
  final auth = AuthRepository(client);
  if (client.auth.currentUser != null) {
    await showAppSheet<void>(
      context,
      builder: (_) => AccountScreen(
        repository: SupabaseAccountRepository(auth),
        email: client.auth.currentUser?.email,
        onSignOut: auth.signOut,
        onAppleReauthenticate:
            !auth.native.usesNativeApple &&
                client.auth.currentUser!.identities?.any(
                      (i) => i.provider == 'apple',
                    ) ==
                    true
            ? () => auth.signIn(OAuthProvider.apple)
            : null,
      ),
    );
  } else {
    await showAppDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('내 매장 로그인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SocialSignInButtons(onSignIn: auth.signIn),
            TextButton(
              onPressed: () => openPrivacy(c),
              child: const Text('개인정보처리방침'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

Future<void> startSocialSignIn(SupabaseClient client, OAuthProvider provider) =>
    AuthRepository(client).signIn(provider);

class SocialSignInButtons extends StatefulWidget {
  const SocialSignInButtons({
    super.key,
    required this.onSignIn,
    this.loadProviders = configuredSocialProviders,
  });
  final Future<Set<OAuthProvider>> Function() loadProviders;
  final Future<void> Function(OAuthProvider) onSignIn;
  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  Set<OAuthProvider>? providers;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (checkingProviders) return;
    setState(() {
      checkingProviders = true;
      error = null;
    });
    try {
      final value = await widget.loadProviders();
      if (mounted) setState(() => providers = value);
    } catch (_) {
      if (mounted) {
        setState(() {
          providers = {};
          error = '로그인 연결 상태를 확인하지 못했어요. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => checkingProviders = false);
    }
  }

  bool checkingProviders = false;
  bool busy = false;
  OAuthProvider? activeProvider;
  String? error;
  Future<void> signIn(OAuthProvider provider) async {
    if (busy) return;
    setState(() {
      busy = true;
      activeProvider = provider;
      error = null;
    });
    try {
      await widget.onSignIn(provider);
    } on SignInCancelled {
      // Dismissing the provider sheet leaves the user on the login screen.
    } catch (_) {
      if (mounted) {
        setState(() => error = '로그인하지 못했어요. 연결 상태를 확인한 뒤 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          activeProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final provider in [OAuthProvider.google, OAuthProvider.apple]) ...[
        PressBounce(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              backgroundColor: provider == OAuthProvider.google
                  ? AppColors.white
                  : Colors.black,
              foregroundColor: provider == OAuthProvider.google
                  ? const Color(0xFF1F1F1F)
                  : AppColors.white,
              disabledForegroundColor: AppColors.muted,
              disabledBackgroundColor: AppColors.elevated,
              side: BorderSide(
                color: provider == OAuthProvider.google
                    ? const Color(0xFF747775)
                    : AppColors.controlLine,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                busy ||
                    checkingProviders ||
                    providers?.contains(provider) != true
                ? null
                : () => signIn(provider),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: activeProvider == provider
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : provider == OAuthProvider.google
                      ? Image.asset(
                          'assets/branding/google_g.png',
                          width: 20,
                          height: 20,
                        )
                      : const Icon(Icons.apple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider == OAuthProvider.google
                        ? 'Google로 계속하기'
                        : 'Apple로 계속하기',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (checkingProviders)
        Semantics(
          liveRegion: true,
          child: const Text('로그인 연결 확인 중이에요.', style: AppText.caption),
        ),
      if (!checkingProviders &&
          providers != null &&
          providers!.length < 2 &&
          error == null)
        const Text(
          '소셜 로그인 연결 준비 중이에요. 잠시 후 다시 시도해 주세요.',
          style: AppText.caption,
        ),
      if (busy)
        Semantics(
          liveRegion: true,
          child: const Text('계정 연결을 기다리고 있어요.', style: AppText.caption),
        ),
      if (error != null)
        Semantics(liveRegion: true, child: Information(error!)),
      if (providers != null && providers!.length < 2)
        TextButton(
          onPressed: busy || checkingProviders ? null : load,
          child: const Text('연결 다시 확인'),
        ),
    ],
  );
}
