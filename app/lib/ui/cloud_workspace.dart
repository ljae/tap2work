import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
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
  @override
  void initState() {
    super.initState();
    userId = widget.client.auth.currentUser?.id;
    ops = controller()..start();
    subscription = widget.client.auth.onAuthStateChange.listen((state) {
      final next = state.session?.user.id;
      if (next == userId || !mounted) return;
      final previous = ops;
      setState(() {
        userId = next;
        ops = controller()..start();
      });
      previous.dispose();
    });
  }

  OperationsController controller() => userId == null
      ? OperationsController(sharedApi: widget.sharedApi)
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
  Widget build(BuildContext context) => Tap2workApp(
    key: ValueKey(userId ?? 'preview'),
    controller: widget.work,
    operations: ops,
    onAccountPressed: (context) => openAccount(context, widget.client),
    accountEmail: widget.client.auth.currentUser?.email,
  );
}

Future<void> openAccount(BuildContext context, SupabaseClient client) async {
  if (client.auth.currentUser != null) {
    final logout = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('내 계정'),
        content: Text(client.auth.currentUser?.email ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (logout == true) await client.auth.signOut();
  } else {
    await showDialog<void>(
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
  bool signup = false, busy = false;
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
              '로그인하면 업무와 배치를 저장할 수 있어요. 처음에는 가상 매장으로 시작합니다.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
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
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              enabled: !busy,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: '비밀번호'),
              onSubmitted: (_) => submit(),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message!,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : submit,
                child: Text(
                  busy
                      ? '연결 중…'
                      : signup
                      ? '계정 만들기'
                      : '로그인',
                ),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      signup = !signup;
                      message = null;
                    }),
              child: Text(signup ? '이미 계정이 있어요' : '처음 이용하시나요? 계정 만들기'),
            ),
          ],
        ),
      ),
    ),
  );
}
