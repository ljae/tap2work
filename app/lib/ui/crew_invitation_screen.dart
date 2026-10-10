import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// A roster record is selected first. Receiving an invite never invents a
/// second crew record and only the signed-in recipient can accept it.
class CrewInvitationScreen extends StatefulWidget {
  const CrewInvitationScreen({
    super.key,
    required this.ops,
    this.management = false,
    this.initialCode,
    this.onFinished,
  });
  final OperationsController ops;
  final bool management;
  final String? initialCode;
  final VoidCallback? onFinished;
  @override
  State<CrewInvitationScreen> createState() => _CrewInvitationScreenState();
}

class _CrewInvitationScreenState extends State<CrewInvitationScreen> {
  late final TextEditingController code = TextEditingController(
    text: widget.initialCode ?? '',
  );
  late final String openingActor;
  late final String? openingWorkspace;
  bool loading = false;
  String? error, selected;
  Json? preview, issued;
  List<Json> invitations = [];
  OperationsController get ops => widget.ops;
  @override
  void initState() {
    super.initState();
    openingActor = ops.actorId;
    openingWorkspace = ops.workspaceId;
    if (widget.management) {
      WidgetsBinding.instance.addPostFrameCallback((_) => load());
    }
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  bool get scopeUnchanged =>
      ops.actorId == openingActor && ops.workspaceId == openingWorkspace;
  List<Json> get eligible => ops
      .rows('tappers')
      .where(
        (row) =>
            row['active'] != false &&
            (ops.isOwner ? ['crew', 'cook', 'manager'] : ['crew', 'cook'])
                .contains(row['rank']),
      )
      .toList();
  Future<Json?> request(String action, Json values) async {
    if (loading) return null;
    if (!scopeUnchanged) {
      setState(() => error = context.t('welcome.scopeChanged'));
      return null;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      return await ops.crewInvitation(action, values);
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              e is StateError && AppStrings.of(context).languageTag == 'ko'
              ? e.message
              : context.t('invite.failed'),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> load() async {
    final result = await request('list', {});
    if (result != null && mounted) {
      setState(
        () => invitations = (result['invitations'] as List? ?? []).cast<Json>(),
      );
    }
  }

  Future<void> inspect() async {
    final result = await request('preview', {'code': code.text});
    if (result == null || !mounted) return;
    if (result['accepted'] == true) {
      finish();
      return;
    }
    setState(() => preview = result);
  }

  void finish() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else if (mounted) {
      Navigator.maybePop(context);
    }
  }

  Future<bool> confirm(String title, String body) async =>
      await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('invite.confirm')),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> unlink(Json row) async {
    if (!await confirm(
      context.t('invite.unlinkTitle'),
      context.t('invite.unlinkHelp'),
    )) {
      return;
    }
    final result = await request('unlink', {'tapperId': row['id']});
    if (result != null && mounted) {
      setState(() => issued = null);
      await load();
    }
  }

  String crewName(dynamic id) =>
      '${ops.rows('tappers').where((r) => r['id'] == id).firstOrNull?['nickname'] ?? context.t('store.crew')}';
  String expiry(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return context.t('invite.withinWeek');
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: widget.management
        ? context.t('invite.manageTitle')
        : context.t('invite.joinTitle'),
    onClose: loading ? () {} : finish,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!ops.cloud || ops.readOnly)
          Information(context.t('invite.demoOnly'))
        else if (widget.management) ...[
          Text(context.t('invite.manageHelp')),
          const SizedBox(height: 20),
          if (eligible.where((r) => r['actorId'] == null).isEmpty)
            Information(context.t('invite.registerFirst')),
          AppPicker<String>(
            label: context.t('invite.selectCrew'),
            value:
                eligible.any((r) => r['id'] == selected && r['actorId'] == null)
                ? selected
                : null,
            items: [
              for (final row in eligible.where((r) => r['actorId'] == null))
                DropdownMenuItem(
                  value: '${row['id']}',
                  child: Text('${row['nickname']}'),
                ),
            ],
            onChanged: loading ? null : (v) => setState(() => selected = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loading || selected == null || !ops.canManageCrewInvites
                ? null
                : () async {
                    final result = await request('create', {
                      'tapperId': selected,
                    });
                    if (result != null && mounted) {
                      setState(() => issued = result);
                      await load();
                    }
                  },
            child: Text(
              loading
                  ? context.t('invite.processing')
                  : context.t('invite.create'),
            ),
          ),
          if (issued != null) ...[
            const SizedBox(height: 20),
            Text(
              context.t(
                'invite.share',
                args: {'name': crewName(issued!['tapperId'])},
              ),
              style: AppText.body,
            ),
            SelectableText('${issued!['code']}', style: AppText.title),
            Text(
              context.t(
                'invite.expires',
                args: {'time': expiry(issued!['expiresAt'])},
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: '${issued!['code']}'),
                  ),
                  child: Text(context.t('invite.copyCode')),
                ),
                OutlinedButton(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: '${issued!['link']}'),
                  ),
                  child: Text(context.t('invite.copyLink')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          for (final row in eligible.where((r) => r['actorId'] != null))
            ListTile(
              title: Text('${row['nickname']}'),
              subtitle: Text(context.t('invite.linked')),
              trailing: TextButton(
                onPressed: loading ? null : () => unlink(row),
                child: Text(context.t('invite.unlink')),
              ),
            ),
          for (final invite in invitations.where(
            (i) => i['status'] == 'pending',
          ))
            ListTile(
              title: Text(crewName(invite['tapperId'])),
              subtitle: Text(context.t('invite.pending')),
              trailing: TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!await confirm(
                          context.t('invite.revokeTitle'),
                          context.t('invite.revokeHelp'),
                        )) {
                          return;
                        }
                        final result = await request('revoke', {
                          'inviteId': invite['id'],
                        });
                        if (result != null && mounted) {
                          setState(() => issued = null);
                          await load();
                        }
                      },
                child: Text(context.t('invite.revoke')),
              ),
            ),
        ] else ...[
          Text(context.t('invite.joinHelp')),
          const SizedBox(height: 20),
          TextField(
            controller: code,
            enabled: !loading,
            onChanged: (_) => setState(() => preview = null),
            autocorrect: false,
            decoration: InputDecoration(
              labelText: context.t('invite.code'),
              hintText: context.t('invite.codeHint'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : inspect,
            child: Text(
              loading
                  ? context.t('invite.checking')
                  : context.t('invite.inspect'),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 24),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${preview!['workspaceName']}', style: AppText.title),
                  Text(
                    context.t(
                      'invite.crewName',
                      args: {'name': '${preview!['crewName']}'},
                    ),
                  ),
                  Text(
                    context.t(
                      'invite.role',
                      args: {
                        'role': context.t(switch (preview!['role']) {
                          'manager' => 'store.manager',
                          'cook' => 'store.cook',
                          _ => 'store.crew',
                        }),
                      },
                    ),
                  ),
                  Text(
                    context.t(
                      'invite.expires',
                      args: {'time': expiry(preview!['expiresAt'])},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final result = await request('accept', {
                        'code': code.text,
                        'confirm': true,
                      });
                      if (result?['accepted'] == true && mounted) finish();
                    },
              child: Text(context.t('invite.accept')),
            ),
          ],
        ],
        if (error != null) ...[const SizedBox(height: 16), Information(error!)],
      ],
    ),
  );
}
