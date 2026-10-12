import '../l10n/app_localizations.dart';
import '../l10n/manual_text_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../domain/lesson.dart';
import '../state/work_controller.dart';
import 'components.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.controller});
  final WorkController controller;
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int selected = 0;
  WorkController get work => widget.controller;
  static const gap = SizedBox(height: 32);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: work,
    builder: (context, _) => Scaffold(
      appBar: BrandHeader(
        action: PopupMenuButton<String>(
          popUpAnimationStyle: AppMotion.dialogStyle(context),
          key: const ValueKey('header-account-menu'),
          tooltip: context.t('ui.audit1290'),
          onSelected: _menu,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'worker',
              child: Text(context.t('ui.audit1291')),
            ),
            PopupMenuItem(
              value: 'buddy',
              child: Text(context.t('ui.audit1292')),
            ),
            PopupMenuItem(
              value: 'about',
              child: Text(context.t('ui.audit1293')),
            ),
            PopupMenuItem(
              value: 'reset',
              child: Text(context.t('ui.audit1294')),
            ),
          ],
          child: const HeaderAccountButton(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AppContentTransition(
          trigger: (selected, work.role),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                key: ValueKey('page-$selected-${work.role.name}'),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        context.t('ui.audit1295'),
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                    if (work.storageWarning != null) ...[
                      Information(work.storageWarning!),
                      gap,
                    ],
                    ...switch (selected) {
                      0 => work.role == DemoRole.buddy ? _buddy() : _today(),
                      1 => _learning(),
                      2 => _shifts(),
                      _ => _team(),
                    },
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        context.t('ui.audit1296'),
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloatingMenu(
        selectedIndex: selected,
        onSelected: (index) => setState(() => selected = index),
        items: [
          FloatingMenuItem(context.t('ui.audit1585'), CupertinoIcons.house),
          FloatingMenuItem(context.t('ui.audit1702'), CupertinoIcons.book),
          FloatingMenuItem(context.t('ui.audit1616'), CupertinoIcons.calendar),
          FloatingMenuItem(
            context.t('ui.audit1315'),
            CupertinoIcons.question_circle,
          ),
        ],
      ),
    ),
  );

  List<Widget> _today() {
    final next = work.nextLesson;
    return [
      PageHeading(
        context.t('ui.audit1297'),
        context.t('ui.audit1298'),
        context.t('ui.audit1299'),
      ),
      Surface(
        color: Color(0xFF222528),
        padding: EdgeInsets.all(17),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Brief(
              Icons.schedule,
              context.t('ui.audit1703'),
              context.t('ui.audit1704'),
            ),
            _Brief(
              Icons.place_outlined,
              context.t('ui.audit1335'),
              context.t('ui.audit1705'),
            ),
          ],
        ),
      ),
      gap,
      Surface(
        color: AppColors.lime,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(
              next == null
                  ? context.t('ui.audit1300')
                  : context.t('ui.audit1301', args: {'p0': next.minutes}),
              color: AppColors.green,
            ),
            const SizedBox(height: 22),
            Text(
              next?.title ??
                  (work.allConfirmed
                      ? context.t('ui.audit1302')
                      : context.t('ui.audit1303')),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              next == null
                  ? context.t('ui.audit1304')
                  : context.t('ui.audit1305', args: {'p0': next.subtitle}),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD1DBD5),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PressBounce(
                child: FilledButton.icon(
                  key: const Key('next-task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.green,
                  ),
                  onPressed: next == null ? _help : () => _lesson(next),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    next == null
                        ? context.t('ui.audit1306')
                        : context.t('ui.audit1307'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 23),
            Row(
              children: [
                Expanded(
                  child: AppLinearProgress(
                    value: work.approved.length / lessons.length,
                    color: AppColors.lime,
                    backgroundColor: const Color(0xFF536B5D),
                    borderRadius: BorderRadius.circular(10),
                    semanticsLabel: context.t('ui.audit1308'),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.t('ui.audit1309', args: {'p0': work.approved.length}),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD1DBD5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 23),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.t('ui.audit1310'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          PressBounce(
            child: TextButton(
              onPressed: () => setState(() => selected = 1),
              child: Text(context.t('ui.audit1311')),
            ),
          ),
        ],
      ),
      ...lessons.take(3).map(_lessonTile),
      gap,
      Surface(
        color: const Color(0xFF392E20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(context.t('ui.audit1312')),
            const SizedBox(height: 16),
            Text(
              context.t('ui.audit1313'),
              style: TextStyle(
                fontSize: 24,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Person(
              name: '민지',
              subtitle: context.t('ui.audit1314'),
              trailing: PressBounce(
                child: TextButton(
                  onPressed: _help,
                  child: Text(context.t('ui.audit1315')),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _lessonTile(Lesson item) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('lesson-${item.id}'),
        onTap: () => _lesson(item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: work.approved.contains(item.id)
              ? AppColors.lime
              : AppColors.elevated,
          child: work.approved.contains(item.id)
              ? const Icon(Icons.check, size: 18)
              : Text(
                  '${lessons.indexOf(item) + 1}',
                  style: const TextStyle(fontSize: 13),
                ),
        ),
        title: Text(
          manualDisplayText(context, item.title),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          work.status(item),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        trailing: Text(
          context.t('ui.audit920', args: {'p0': item.minutes}),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ),
    ),
  );

  List<Widget> _learning() => [
    PageHeading(
      context.t('ui.audit1316'),
      context.t('ui.audit1317'),
      context.t('ui.audit1318'),
    ),
    Information(
      context.t(
        'ui.audit1319',
        args: {'p0': work.practiced.length, 'p1': work.approved.length},
      ),
    ),
    gap,
    ...lessons.map(_lessonTile),
    gap,
    Information(context.t('ui.audit1320')),
  ];

  List<Widget> _shifts() => [
    PageHeading(
      context.t('ui.audit1321'),
      context.t('ui.audit1322'),
      context.t('ui.audit1323'),
    ),
    Information(context.t('ui.audit1324')),
    gap,
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(context.t('ui.audit1325')),
          const SizedBox(height: 14),
          const Text(
            '10:00 — 14:00',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          Text(context.t('ui.audit1326')),
          const SizedBox(height: 8),
          Text(
            context.t('ui.audit1327'),
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const Divider(height: 36),
          Person(name: '민지', subtitle: context.t('ui.audit1328')),
          gap,
          SizedBox(
            width: double.infinity,
            child: PressBounce(
              child: FilledButton(
                key: const Key('confirm-shift'),
                onPressed: work.shiftConfirmed ? null : work.confirmShift,
                child: Text(
                  work.shiftConfirmed
                      ? context.t('ui.audit1329')
                      : context.t('ui.audit1330'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    gap,
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(context.t('ui.audit1331')),
          const SizedBox(height: 13),
          Text(
            context.t('ui.audit1332'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('11:00 — 15:00', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Text(
            context.t('ui.audit1333'),
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          gap,
          PressBounce(
            child: OutlinedButton(
              onPressed: _help,
              child: Text(context.t('ui.audit1334')),
            ),
          ),
        ],
      ),
    ),
  ];

  List<Widget> _team() => [
    PageHeading(
      context.t('ui.audit1335'),
      context.t('ui.audit1336'),
      context.t('ui.audit1337'),
    ),
    Surface(
      child: Person(name: '민지', subtitle: context.t('ui.audit1328')),
    ),
    gap,
    Surface(
      color: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(context.t('ui.audit1338'), color: AppColors.green),
          const SizedBox(height: 19),
          Text(
            context.t('ui.audit1339'),
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            context.t('ui.audit1340'),
            style: TextStyle(color: Color(0xFFD1DBD5), height: 1.7),
          ),
          gap,
          PressBounce(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.green,
              ),
              onPressed: _help,
              icon: const Icon(Icons.chat_bubble_outline, size: 19),
              label: Text(context.t('ui.audit1341')),
            ),
          ),
        ],
      ),
    ),
    gap,
    Information(
      work.helpRequested
          ? context.t('ui.audit1342')
          : context.t('ui.audit1343'),
    ),
    gap,
    Surface(
      child: Person(name: '현우', subtitle: context.t('ui.audit1344')),
    ),
  ];

  List<Widget> _buddy() => [
    PageHeading(
      context.t('ui.audit1345'),
      context.t('ui.audit1346'),
      context.t('ui.audit1347'),
    ),
    Information(context.t('ui.audit1348')),
    gap,
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Person(name: '지우', subtitle: context.t('ui.audit1349')),
          gap,
          Text(
            '${work.approved.length} / 6',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Text(
            work.allConfirmed
                ? context.t('ui.audit1350')
                : context.t('ui.audit1351'),
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
    gap,
    if (work.helpRequested) ...[
      Surface(
        color: const Color(0xFF392E20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('ui.audit1352'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(context.t('ui.audit1353')),
            const SizedBox(height: 16),
            PressBounce(
              child: FilledButton(
                onPressed: work.resolveHelp,
                child: Text(context.t('ui.audit1354')),
              ),
            ),
          ],
        ),
      ),
      gap,
    ],
    Text(
      context.t('ui.audit1355'),
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    gap,
    ...lessons.map(
      (item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Surface(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manualDisplayText(context, item.title),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                work.status(item),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              PressBounce(
                child: OutlinedButton(
                  key: Key('approve-${item.id}'),
                  onPressed:
                      work.practiced.contains(item.id) &&
                          !work.approved.contains(item.id)
                      ? () => _lesson(item, approve: true)
                      : null,
                  child: Text(
                    work.approved.contains(item.id)
                        ? context.t('ui.audit1356')
                        : context.t('ui.audit1300'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  Future<void> _lesson(Lesson lesson, {bool approve = false}) async {
    var checked = false;
    final practiced = work.practiced.contains(lesson.id);
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.panelStyle(context),
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Eyebrow(
                        context.t(
                          'ui.audit1357',
                          args: {
                            'p0': lessons.indexOf(lesson) + 1,
                            'p1': lesson.minutes,
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      tooltip: context.t('ui.audit83'),
                    ),
                  ],
                ),
                Text(
                  manualDisplayText(context, lesson.title),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                gap,
                if (!approve) ...[
                  _Instruction(
                    context.t('ui.audit1358'),
                    manualDisplayText(context, lesson.watch),
                  ),
                  _Instruction(
                    context.t('ui.audit1359'),
                    manualDisplayText(context, lesson.practice),
                  ),
                ],
                _Instruction(
                  context.t('ui.audit1360'),
                  manualDisplayText(context, lesson.check),
                ),
                if (approve ||
                    (!practiced && work.role == DemoRole.worker)) ...[
                  CheckboxListTile(
                    key: const Key('practice-check'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    onChanged: (value) =>
                        setSheetState(() => checked = value ?? false),
                    title: Text(
                      approve
                          ? context.t('ui.audit1361')
                          : context.t('ui.audit1362'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: PressBounce(
                      child: FilledButton(
                        key: const Key('save-lesson'),
                        onPressed: checked
                            ? () {
                                final success = approve
                                    ? work.approve(lesson.id)
                                    : work.practice(lesson.id);
                                Navigator.pop(sheetContext);
                                if (success) {
                                  _message(
                                    approve
                                        ? context.t('ui.audit1386')
                                        : context.t('ui.audit1387'),
                                  );
                                }
                              }
                            : null,
                        child: Text(
                          approve
                              ? context.t('ui.audit1363')
                              : context.t('ui.audit1364'),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Information(
                    practiced ? work.status(lesson) : context.t('ui.audit1365'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PressBounce(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _help();
                      },
                      child: Text(context.t('ui.audit1366')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _help() async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('ui.audit1367')),
        content: Text(context.t('ui.audit1368')),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('ui.audit83')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.t('ui.audit1369')),
            ),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      work.requestHelp();
      _message(context.t('ui.audit1388'));
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _menu(String action) async {
    if (action == 'worker' || action == 'buddy') {
      setState(() => selected = 0);
      work.switchRole(action == 'buddy' ? DemoRole.buddy : DemoRole.worker);
    } else if (action == 'about') {
      await showAppDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('ui.audit1370')),
          content: Text(context.t('ui.audit1371')),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('ui.audit1372')),
              ),
            ),
          ],
        ),
      );
    } else if (action == 'reset') {
      final reset = await showAppDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('ui.audit1373')),
          content: Text(context.t('ui.audit1374')),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.t('ui.audit33')),
              ),
            ),
            PressBounce(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.t('ui.audit1375')),
              ),
            ),
          ],
        ),
      );
      if (reset == true && mounted) {
        setState(() => selected = 0);
        work.reset();
      }
    }
  }
}

class _Brief extends StatelessWidget {
  const _Brief(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 19, color: AppColors.green),
      const SizedBox(width: 9),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    ],
  );
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(title),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 16, height: 1.65)),
      ],
    ),
  );
}
