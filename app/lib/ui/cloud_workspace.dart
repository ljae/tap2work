import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../data/auth_provider_repository.dart';
import '../data/auth_repository.dart';
import '../data/account_repository.dart';
import '../data/native_auth_service.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import 'components.dart';

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
  late final auth = AuthRepository(widget.client);
  bool isSocialUser(User? user) =>
      user?.identities?.any(
        (identity) => ['apple', 'google'].contains(identity.provider),
      ) ==
      true;

  @override
  void initState() {
    super.initState();
    userId = isSocialUser(widget.client.auth.currentUser)
        ? widget.client.auth.currentUser?.id
        : null;
    if (widget.client.auth.currentUser != null && userId == null) {
      unawaited(auth.signOut().catchError((Object _) {}));
    }
    ops = controller();
    if (userId != null) ops.start();
    subscription = widget.client.auth.onAuthStateChange.listen((state) {
      final next = isSocialUser(state.session?.user)
          ? state.session?.user.id
          : null;
      if (next == userId || !mounted) return;
      final previous = ops;
      setState(() {
        userId = next;
        preview = false;
        ops = controller();
        if (userId != null) ops.start();
      });
      previous.dispose();
    });
  }

  OperationsController controller() => userId == null
      ? OperationsController(readOnly: true)
      : OperationsController(
          readOnly: false,
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

  @override
  void dispose() {
    subscription?.cancel();
    ops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) => Tap2workApp(
      key: ValueKey(userId ?? (preview ? 'preview' : 'sign-in')),
      controller: widget.work,
      operations: ops,
      onAccountPressed: account,
      accountEmail: widget.client.auth.currentUser?.email,
      homeOverride: userId == null && !preview
          ? Builder(
              builder: (context) => Scaffold(
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(28),
                        children: [
                          const BrandLogo(),
                          const SizedBox(height: 40),
                          const Text(
                            '우리 매장의 하루를\n함께 관리해요',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '한 번 로그인하면 다음 방문부터 자동으로 연결돼요.',
                            style: TextStyle(
                              color: AppColors.muted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SocialSignInButtons(
                            onSignIn: auth.signIn,
                            loadProviders: widget.loadProviders,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Apple 또는 Google 계정으로 시작해요. 비밀번호는 TAP Work에 전달되지 않아요.',
                            style: AppText.caption,
                          ),
                          TextButton(
                            onPressed: () => openPrivacy(context),
                            child: const Text('개인정보처리방침'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => preview = true);
                              ops.start();
                            },
                            child: const Text('저장 없이 샘플 둘러보기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                      : () => ops.act('create_workspace', {
                          'mode': 'blank',
                          'revision': 0,
                        }),
                  child: const Text('빈 매장으로 시작'),
                ),
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
    }
  }

  bool busy = false;
  String? error;
  Future<void> signIn(OAuthProvider provider) async {
    if (busy) return;
    setState(() {
      busy = true;
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
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final provider in [OAuthProvider.google, OAuthProvider.apple]) ...[
        PressBounce(
          child: OutlinedButton(
            onPressed: busy || providers?.contains(provider) != true
                ? null
                : () => signIn(provider),
            child: Text(
              provider == OAuthProvider.google ? 'Google로 계속하기' : 'Apple로 계속하기',
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (providers != null && providers!.length < 2)
        const Text(
          '소셜 로그인 연결 준비 중이에요. 잠시 후 다시 시도해 주세요.',
          style: AppText.caption,
        ),
      if (error != null) Information(error!),
      if (providers != null && providers!.length < 2)
        TextButton(
          onPressed: busy ? null : load,
          child: const Text('연결 다시 확인'),
        ),
    ],
  );
}
