import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../data/auth_provider_repository.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import 'components.dart';

class CloudWorkspace extends StatefulWidget {
  const CloudWorkspace({
    super.key,
    required this.work,
    required this.client,
    this.sharedApi,
  });
  final WorkController work;
  final SupabaseClient client;
  final String? sharedApi;
  @override
  State<CloudWorkspace> createState() => _CloudWorkspaceState();
}

class _CloudWorkspaceState extends State<CloudWorkspace> {
  late OperationsController ops;
  StreamSubscription<AuthState>? subscription;
  String? userId;
  bool preview = false;
  bool signingIn = false;
  String? loginError;
  Future<void> publicLogin() async {
    setState(() {
      signingIn = true;
      loginError = null;
    });
    try {
      const url = String.fromEnvironment('SUPABASE_URL');
      const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
      final response = await http
          .post(
            Uri.parse('$url/functions/v1/public-login'),
            headers: {'apikey': key, 'Content-Type': 'application/json'},
            body: '{}',
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map;
      if (response.statusCode != 200) {
        throw StateError(body['error'] as String? ?? '로그인에 실패했어요.');
      }
      await widget.client.auth.setSession(body['refresh_token'] as String);
    } catch (_) {
      if (mounted) setState(() => loginError = '로그인하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  @override
  void initState() {
    super.initState();
    userId = widget.client.auth.currentUser?.id;
    ops = controller();
    if (userId != null) ops.start();
    subscription = widget.client.auth.onAuthStateChange.listen((state) {
      final next = state.session?.user.id;
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
      onAccountPressed: (context) => openAccount(context, widget.client),
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
                          const PublicLoginFields(),
                          const SizedBox(height: 16),
                          const Text(
                            '공용 계정의 기존 매장에 접속해요. 방문자가 같은 데이터를 보고 수정하며, 변경 내용은 함께 저장됩니다.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: signingIn ? null : publicLogin,
                            child: Text(signingIn ? '로그인 중…' : '로그인'),
                          ),
                          if (loginError != null) Information(loginError!),
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
  if (client.auth.currentUser != null) {
    final logout = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('내 계정'),
        content: Text(client.auth.currentUser?.email ?? ''),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('닫기'),
            ),
          ),
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('로그아웃'),
            ),
          ),
        ],
      ),
    );
    if (logout == true) await client.auth.signOut();
  } else {
    await showAppDialog<void>(
      context: context,
      builder: (_) => _SignInDialog(client: client),
    );
  }
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog({required this.client});
  final SupabaseClient client;
  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool signup = false, busy = false, hidePassword = true;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (!email.text.contains('@') ||
        password.text.length < 8 ||
        (signup && name.text.trim().isEmpty)) {
      setState(
        () => message = '이메일과 8자 이상의 비밀번호${signup ? ', 이름' : ''}를 입력해 주세요.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (signup) {
        final result = await widget.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'display_name': name.text.trim()},
          emailRedirectTo: 'https://tap2.work/',
        );
        if (mounted && result.session == null) {
          setState(() => message = '이메일의 확인 링크를 누른 뒤 로그인해 주세요.');
        }
      } else {
        await widget.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException {
      if (mounted) {
        setState(() => message = '계정 정보를 확인해 주세요. 가입했다면 이메일 인증도 완료해 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => message = '연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(signup ? '내 매장 시작하기' : '다시 만나 반가워요'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '로그인하면 모든 매장 설정과 운영 기록을 저장할 수 있어요. 첫 로그인에서 빈 매장 또는 샘플 매장을 선택합니다.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            if (const bool.fromEnvironment('ENABLE_SSO'))
              SocialSignInButtons(
                onSignIn: (provider) =>
                    startSocialSignIn(widget.client, provider),
              ),
            const SizedBox(height: 20),
            if (signup) ...[
              TextField(
                controller: name,
                enabled: !busy,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              enabled: !busy,
              obscureText: hidePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: '비밀번호',
                suffixIcon: IconButton(
                  tooltip: hidePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                  onPressed: busy
                      ? null
                      : () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => submit(),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Information(message!),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PressBounce(
                child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: AppCircularProgress(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        busy
                            ? '연결 중…'
                            : signup
                            ? '계정 만들기'
                            : '로그인',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PressBounce(
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        signup = !signup;
                        message = null;
                      }),
                child: Text(signup ? '이미 계정이 있어요' : '처음 이용하시나요? 계정 만들기'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> startSocialSignIn(
  SupabaseClient client,
  OAuthProvider provider,
) async {
  // Web callback is fixed; never propagate ?api, return URLs or OAuth fragments.
  if (!kIsWeb) throw StateError('웹에서 계속해 주세요.');
  final started = await client.auth.signInWithOAuth(
    provider,
    redirectTo: 'https://tap2.work/',
  );
  if (!started) throw StateError('로그인 페이지를 열지 못했어요.');
}

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
          error = '로그인 연결 상태를 확인하지 못했어요. 이메일 로그인을 이용하거나 다시 열어 주세요.';
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
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              '로그인 연결을 확인해 주세요. 제공자 설정이 아직 완료되지 않았다면 이메일 로그인을 이용할 수 있어요.',
        );
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
          '소셜 로그인 연결 준비 중 · 이메일 로그인은 이용할 수 있어요.',
          style: AppText.caption,
        ),
      if (error != null) Information(error!),
    ],
  );
}

class PublicLoginFields extends StatelessWidget {
  const PublicLoginFields({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextFormField(
        initialValue: 'ljae.m10@gmail.com',
        readOnly: true,
        decoration: const InputDecoration(labelText: '공용 로그인 아이디'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: 'temporary',
        readOnly: true,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: '비밀번호',
          helperText: '직접 입력 없이 서버에서 자동 로그인합니다.',
        ),
      ),
    ],
  );
}
