import 'package:flutter/material.dart';
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
  static const gap = SizedBox(height: 20);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: work,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const BrandLogo(),
        actions: [
          PopupMenuButton<String>(
            tooltip: '체험 역할과 안내',
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'worker', child: Text('신입 · 지우로 체험')),
              PopupMenuItem(value: 'buddy', child: Text('버디 · 민지로 체험')),
              PopupMenuItem(value: 'about', child: Text('체험 버전 안내')),
              PopupMenuItem(value: 'reset', child: Text('체험 기록 초기화')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.peach,
                    child: Text(
                      work.role == DemoRole.worker ? '지' : '민',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    work.role == DemoRole.worker ? '신입' : '버디',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              key: ValueKey('page-$selected-${work.role.name}'),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '체험 버전 · 가상 매장 · 이 기기에만 저장돼요',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
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
                  const Center(
                    child: Text(
                      '한 번에 하나씩, 함께 배워요.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '일하는 법',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: '근무표',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: '도움',
          ),
        ],
      ),
    ),
  );

  List<Widget> _today() {
    final next = work.nextLesson;
    return [
      const PageHeading(
        '첫 출근, 반가워요',
        '지우님, 함께 시작해요.',
        '오늘은 주방 보조 · 한 번에 하나씩 익히면 돼요.',
      ),
      const Surface(
        color: Color(0xFFEEECE3),
        padding: EdgeInsets.all(17),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Brief(Icons.schedule, '10:00 출근', '14:00까지 · 예시'),
            _Brief(Icons.place_outlined, '작은주방 · 연남', '민지님과 함께해요'),
          ],
        ),
      ),
      gap,
      Surface(
        color: AppColors.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(
              next == null ? '함께 확인하기' : '지금 할 일 · 약 ${next.minutes}분',
              color: AppColors.lime,
            ),
            const SizedBox(height: 22),
            Text(
              next?.title ??
                  (work.allConfirmed
                      ? '첫걸음 완료.\n다음도 함께해요.'
                      : '잘 연습했어요.\n민지님과 확인해요.'),
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              next == null
                  ? '다시 해보고 싶은 것도 알려 주세요.\n다음 업무도 버디와 함께해요.'
                  : '${next.subtitle}.\n민지님이 옆에서 도와줄 거예요.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD1DBD5),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('next-task'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.green,
                ),
                onPressed: next == null ? _help : () => _lesson(next),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(next == null ? '같이 봐 달라고 하기' : '어떻게 하는지 보기'),
              ),
            ),
            const SizedBox(height: 23),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: work.approved.length / lessons.length,
                    color: AppColors.lime,
                    backgroundColor: const Color(0xFF536B5D),
                    borderRadius: BorderRadius.circular(10),
                    semanticsLabel: '함께 익힌 단계',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${work.approved.length}개 함께 익혔어요',
                  style: const TextStyle(
                    fontSize: 11,
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
          const Text(
            '오늘 배울 것',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          TextButton(
            onPressed: () => setState(() => selected = 1),
            child: const Text('전체 6단계 →'),
          ),
        ],
      ),
      ...lessons.take(3).map(_lessonTile),
      gap,
      Surface(
        color: const Color(0xFFF5E2D1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('오늘의 버디 · 예시'),
            const SizedBox(height: 16),
            const Text(
              '“빨리 하는 것보다\n같이 익히는 게 먼저예요.”',
              style: TextStyle(
                fontSize: 22,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Person(
              name: '민지',
              subtitle: '처음부터 같이 해볼게요.',
              trailing: TextButton(onPressed: _help, child: const Text('도움')),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _lessonTile(Lesson item) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: AppColors.white,
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
              : const Color(0xFFEEF0E7),
          child: work.approved.contains(item.id)
              ? const Icon(Icons.check, size: 18)
              : Text(
                  '${lessons.indexOf(item) + 1}',
                  style: const TextStyle(fontSize: 12),
                ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          work.status(item),
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        trailing: Text(
          '${item.minutes}분',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ),
    ),
  );

  List<Widget> _learning() => [
    const PageHeading(
      '보고 → 같이 해보고 → 확인받기',
      '첫 한 시간 배우기',
      '6개의 짧은 단계로 오늘의 일을 익혀요.',
    ),
    Information(
      '연습 ${work.practiced.length}/6 · 함께 확인 ${work.approved.length}/6\n시간은 안내용이에요. 이해가 안 되면 더 연습해도 괜찮아요.',
    ),
    gap,
    ...lessons.map(_lessonTile),
    gap,
    const Information(
      '매장의 실제 절차를 버디와 확인해요. 이 체험은 매장의 필수 교육이나 자격 확인을 대신하지 않아요.',
    ),
  ];

  List<Widget> _shifts() => [
    const PageHeading('일하는 날을 한눈에', '내 근무표', '확정된 시간과 함께할 버디를 확인해요.'),
    const Information('예시 일정이에요. 실제 배정이나 출퇴근 기록은 아직 연결되지 않았어요.'),
    gap,
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('첫 출근일 · 예시'),
          const SizedBox(height: 14),
          const Text(
            '10:00 — 14:00',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          const Text('작은주방 · 연남 / 주방 보조'),
          const SizedBox(height: 8),
          const Text(
            '10:00–11:00 첫 한 시간 함께 배우기',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const Divider(height: 36),
          const Person(name: '민지', subtitle: '오늘의 버디 · 주방 담당'),
          gap,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('confirm-shift'),
              onPressed: work.shiftConfirmed ? null : work.confirmShift,
              child: Text(work.shiftConfirmed ? '근무 시간 확인했어요' : '근무 시간 확인하기'),
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
          const Eyebrow('다음 근무 · 예시'),
          const SizedBox(height: 13),
          const Text(
            '첫 출근 다음 날',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('11:00 — 15:00', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 10),
          const Text(
            '시작 전 5분, 어제 어려웠던 일을 다시 확인해요.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          gap,
          OutlinedButton(onPressed: _help, child: const Text('근무 시간 상의하기')),
        ],
      ),
    ),
  ];

  List<Widget> _team() => [
    const PageHeading(
      '작은주방 · 연남',
      '혼자 고민하지 마세요.',
      '작은 질문도 괜찮아요. 가까운 버디에게 물어봐요.',
    ),
    const Surface(
      child: Person(name: '민지', subtitle: '오늘의 버디 · 주방 담당'),
    ),
    gap,
    Surface(
      color: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('도움이 필요할 때', color: AppColors.lime),
          const SizedBox(height: 19),
          const Text(
            '“여기, 같이 봐 주세요.”',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            '현장에서 민지님을 먼저 불러 주세요. 급한 위험은 앱 답장을 기다리지 않고 바로 알려요.',
            style: TextStyle(color: Color(0xFFD1DBD5), height: 1.7),
          ),
          gap,
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.green,
            ),
            onPressed: _help,
            icon: const Icon(Icons.chat_bubble_outline, size: 19),
            label: const Text('도움 요청 체험'),
          ),
        ],
      ),
    ),
    gap,
    Information(
      work.helpRequested
          ? '데모 요청이 있어요. 버디 모드에서 확인할 수 있어요. 실제 알림은 전송되지 않아요.'
          : '이 체험에서는 실제 알림이나 메시지가 전송되지 않아요.',
    ),
    gap,
    const Surface(
      child: Person(name: '현우', subtitle: '매니저 · 근무 일정 상담'),
    ),
  ];

  List<Widget> _buddy() => [
    const PageHeading('버디 체험 모드', '첫날을 함께 만들어 줘요.', '신입이 해본 일을 살펴보고 함께 확인해요.'),
    const Information('데모 역할 전환이에요. 실제 로그인이나 매장별 권한 확인은 아직 연결하지 않았어요.'),
    gap,
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Person(name: '지우', subtitle: '오늘의 신입 · 주방 준비 및 설거지'),
          gap,
          Text(
            '${work.approved.length} / 6',
            style: const TextStyle(fontSize: 39, fontWeight: FontWeight.w600),
          ),
          Text(
            work.allConfirmed ? '함께 확인했어요. 다음 업무도 옆에서 도와주세요.' : '함께 확인한 단계',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
    gap,
    if (work.helpRequested) ...[
      Surface(
        color: const Color(0xFFF5E2D1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지우님이 함께 봐 달래요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text('현장에서 상황을 확인한 뒤 눌러 주세요.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: work.resolveHelp,
              child: const Text('함께 확인했어요'),
            ),
          ],
        ),
      ),
      gap,
    ],
    const Text(
      '단계별 확인',
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
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
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                work.status(item),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: Key('approve-${item.id}'),
                onPressed:
                    work.practiced.contains(item.id) &&
                        !work.approved.contains(item.id)
                    ? () => _lesson(item, approve: true)
                    : null,
                child: Text(
                  work.approved.contains(item.id) ? '확인 완료' : '함께 확인하기',
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
                        '${lessons.indexOf(lesson) + 1} / 6 · 약 ${lesson.minutes}분',
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      tooltip: '닫기',
                    ),
                  ],
                ),
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                gap,
                if (!approve) ...[
                  _Instruction('01 보기', lesson.watch),
                  _Instruction('02 함께', lesson.practice),
                ],
                _Instruction('03 확인', lesson.check),
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
                          ? '현장에서 함께 확인하고, 더 도울 부분을 설명했어요.'
                          : '버디와 함께 직접 해봤어요.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
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
                                      ? '함께 확인한 내용을 기록했어요.'
                                      : '같이 해본 내용을 기록했어요. 버디가 함께 확인해 줄 거예요.',
                                );
                              }
                            }
                          : null,
                      child: Text(approve ? '버디 확인 완료' : '같이 해봤어요'),
                    ),
                  ),
                ] else
                  Information(
                    practiced
                        ? work.status(lesson)
                        : '버디는 시범을 보여 주고 함께 연습해 주세요. 연습 기록은 신입 모드에서 남길 수 있어요.',
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _help();
                    },
                    child: const Text('도움이 필요해요'),
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('버디와 같이 봐요.'),
        content: const Text(
          '현장에서 민지님을 먼저 불러 주세요.\n\n이 체험의 요청은 이 기기에만 저장돼요. 실제 메시지는 전송되지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('데모 요청 남기기'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      work.requestHelp();
      _message('이 기기에 요청을 남겼어요. 버디 모드에서 확인할 수 있어요.');
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
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('함께 시작하는 첫 근무'),
          content: const Text(
            'Flutter로 만든 tap2work 체험 버전이에요.\n\n가상 매장과 예시 인물이며 실제 직원 계정, 초대, 알림, 급여, 교육 영상은 아직 연결하지 않았어요. 진행 기록은 현재 기기에만 저장돼요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인했어요'),
            ),
          ],
        ),
      );
    } else if (action == 'reset') {
      final reset = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('체험 기록을 초기화할까요?'),
          content: const Text('이 기기의 연습·버디 확인·도움 요청·일정 확인 기록이 지워져요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초기화'),
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
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
