import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import 'components.dart';
import 'workspace_screen.dart';

const roleLabels = {
  'all': '누구나',
  'crew': '크루',
  'cook': '조리 담당',
  'manager': '매니저',
  'owner': '사장님',
};
const slotLabels = ['오픈', '준비', '피크', '마감'];

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({
    super.key,
    required this.operations,
    required this.work,
  });
  final OperationsController operations;
  final WorkController work;
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  OperationsController get ops => widget.operations;
  int tab = 0;
  String slot = '전체';
  String role = '전체';
  String route = '재료 준비';
  final Map<String, double> cart = {};
  Json? item(String id) =>
      ops.rows('items').where((i) => i['id'] == id).firstOrNull;
  String zoneName(String id) =>
      ops.rows('zones').where((z) => z['id'] == id).firstOrNull?['name']
          as String? ??
      id;
  bool pending(String id) => ops
      .rows('orders')
      .any(
        (o) =>
            o['status'] == 'ordered' &&
            (o['lines'] as List).any((l) => l['itemId'] == id),
      );
  List<Json> get gaps => ops
      .rows('shifts')
      .where((s) => s['status'] == '휴가' && s['covering'] == null)
      .toList();
  List<Json> get lowStock => ops
      .rows('items')
      .where(
        (i) =>
            (i['quantity'] as num) <= (i['minimum'] as num) &&
            !pending(i['id']),
      )
      .toList();
  String qty(dynamic value) => value is num && value == value.roundToDouble()
      ? value.toInt().toString()
      : '$value';
  String money(num value) => value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  String time(dynamic value) {
    final date = DateTime.tryParse(
      '$value',
    )?.toUtc().add(const Duration(hours: 9));
    return date == null
        ? ''
        : '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> act(String action, Json values) async {
    final success = await ops.act(action, values);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '매장에 함께 반영했어요 🌿' : ops.error ?? '저장하지 못했어요.',
          ),
        ),
      );
    }
    return success;
  }

  void go(int value) => setState(() => tab = value);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'tap2work',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: !ops.busy,
            tooltip: '체험 역할 바꾸기 · 실제 로그인 아님',
            onSelected: (id) {
              cart.clear();
              ops.selectActor(id);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'owner', child: Text('🌻 서연 · 사장님')),
              PopupMenuItem(value: 'manager', child: Text('🌿 민지 · 매니저')),
              PopupMenuItem(value: 'cook', child: Text('🍳 현우 · 조리 담당')),
              PopupMenuItem(value: 'crew', child: Text('🐣 지우 · 크루')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${ops.actor['emoji']} ${ops.actor['label']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Icon(Icons.expand_more, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.lime.withValues(alpha: .35),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ops.readOnly
                    ? '공개 미리보기 · 샘플 데이터 · 저장·실제 발주 없음'
                    : '체험 매장 · 역할 전환은 로그인 아님 · 실제 발주 없음',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.green),
              ),
            ),
            if (ops.busy) const LinearProgressIndicator(minHeight: 2),
            if (ops.error != null)
              MaterialBanner(
                content: Text(ops.error!, style: const TextStyle(fontSize: 12)),
                actions: [
                  TextButton(
                    onPressed: ops.busy ? null : () => ops.refresh(),
                    child: const Text('새로고침'),
                  ),
                ],
              ),
            Expanded(
              child: ops.data == null
                  ? Center(
                      child: ops.error == null
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: () => ops.refresh(),
                              child: const Text('매장 다시 연결'),
                            ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ops.refresh(),
                      child: SingleChildScrollView(
                        key: ValueKey(tab),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...switch (tab) {
                                  0 => today(),
                                  1 => tasks(),
                                  2 => inventory(),
                                  3 => team(),
                                  _ => floorPlan(),
                                },
                                const SizedBox(height: 24),
                                const Text(
                                  '🌱 작은 확인이 모여, 함께 일하기 편한 하루',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: '할 일',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            label: '재고/발주',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: '우리 팀',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '매장 지도'),
        ],
      ),
    ),
  );

  Widget gap([double height = 14]) => SizedBox(height: height);
  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
  );
  Widget small(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, height: 1.65, color: AppColors.muted),
  );
  Widget badge(String text, {Color color = AppColors.lime}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.green,
      ),
    ),
  );
  Widget actionCard(
    String emoji,
    String heading,
    String detail,
    VoidCallback onTap, {
    Color color = AppColors.white,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 27)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    small(detail),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> today() {
    final unfinished = ops
        .rows('tasks')
        .where((t) => t['completedAt'] == null)
        .length;
    return [
      PageHeading(
        '작은주방 · 연남  /  ${ops.data!['day']}',
        '${ops.actor['name']}님, 좋은 하루예요 ${ops.actor['emoji']}',
        '지금 알아야 할 일만, 한눈에 확인해요.',
      ),
      Surface(
        color: AppColors.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '우리 매장, 지금은',
              style: TextStyle(color: AppColors.lime, fontSize: 12),
            ),
            gap(14),
            Text(
              gaps.isEmpty
                  ? '오늘의 빈자리를\n모두 채웠어요 🌿'
                  : '${gaps.first['time']}\n함께할 동료가 필요해요',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 23,
                height: 1.5,
              ),
            ),
            gap(10),
            Text(
              gaps.isEmpty
                  ? '근무 변경이 생기면 이곳에서 함께 확인해요.'
                  : '${gaps.first['person']}님 휴가 · 개인 사유는 공유하지 않아요',
              style: const TextStyle(color: Color(0xFFCDD9C9), fontSize: 12),
            ),
            gap(12),
            FilledButton.tonal(
              onPressed: () => go(3),
              child: Text(gaps.isEmpty ? '오늘 근무표 보기' : '공석과 대체 근무 보기 →'),
            ),
          ],
        ),
      ),
      gap(20),
      actionCard(
        '✅',
        '함께 확인할 일 $unfinished개',
        '시간대와 담당에 맞게 · 완료한 사람도 보여요',
        () => go(1),
      ),
      actionCard(
        '🥕',
        '보충을 살펴볼 재료 ${lowStock.length}개',
        '재고 확인 → 모아 발주 → 입고 확인',
        () => go(2),
        color: const Color(0xFFFFEFE4),
      ),
      actionCard(
        '🐣',
        '오늘 처음 왔나요?',
        '버디와 첫 출근 가이드 열기',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkspaceScreen(controller: widget.work),
          ),
        ),
      ),
      actionCard('🗺️', '냉장고, 창고가 어디에 있나요?', '매장 배치와 일하는 동선 알아보기', () => go(4)),
      if (ops.isOwner && ops.data!['privateSummary'] != null) ...[
        title('🔒 사장님만 보는 공간'),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge('비공개 · 예시 정보'),
              gap(10),
              Text(
                '오늘 예상 인건비 ${money(ops.data!['privateSummary']['laborEstimate'])}원',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              gap(8),
              small(ops.data!['privateSummary']['note']),
              small('급여 계산·정산 기능은 아직 연결되지 않았어요.'),
            ],
          ),
        ),
      ],
      title('💬 함께 업데이트했어요'),
      if (ops.rows('activity').isEmpty)
        const Information('아직 새 소식이 없어요. 재고나 할 일을 확인하면 누가 했는지 이곳에 남아요.'),
      for (final event in ops.rows('activity').take(4))
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌿  '),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['message'],
                      style: const TextStyle(fontSize: 13),
                    ),
                    small('${event['actor']['name']} · ${time(event['at'])}'),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> tasks() {
    final visible = ops
        .rows('tasks')
        .where(
          (t) =>
              (slot == '전체' || t['slot'] == slot) &&
              (role == '전체' || t['requiredRole'] == role),
        )
        .toList();
    final done = ops
        .rows('tasks')
        .where((t) => t['completedAt'] != null)
        .length;
    return [
      PageHeading(
        'CHECK TOGETHER',
        '하나씩, 같이 해요 ✅',
        '오늘 $done/${ops.rows('tasks').length}개 완료 · 동료가 한 일은 다시 하지 않아요.',
      ),
      Wrap(
        spacing: 7,
        runSpacing: 6,
        children: [
          for (final label in ['전체', ...slotLabels])
            ChoiceChip(
              label: Text(label),
              selected: slot == label,
              onSelected: (_) => setState(() => slot = label),
            ),
        ],
      ),
      gap(),
      DropdownButtonFormField<String>(
        initialValue: role,
        decoration: const InputDecoration(
          labelText: '담당 직급',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '전체', child: Text('모든 담당 보기')),
          for (final entry in roleLabels.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (value) => setState(() => role = value!),
      ),
      gap(18),
      if (visible.isEmpty) const Information('이 조건에 맞는 할 일이 없어요 🌱'),
      for (final task in visible) ...[
        Surface(
          padding: const EdgeInsets.all(17),
          color: task['completedAt'] != null
              ? const Color(0xFFEDF1E6)
              : AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  badge(task['slot']),
                  badge(
                    roleLabels[task['requiredRole']]!,
                    color: AppColors.paper,
                  ),
                  if (task['kind'] == 'stock')
                    badge('자동 재고 확인', color: const Color(0xFFFFE6D4)),
                ],
              ),
              gap(12),
              Text(
                '${task['emoji']} ${task['title']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              gap(7),
              small(
                '${zoneName(task['zone'])}${task['kind'] == 'stock' ? ' · 발주 후 정기 확인' : ' · 매일 반복'}',
              ),
              gap(12),
              if (task['completedAt'] != null)
                Text(
                  '✓ ${task['completedBy']['name']}님이 ${time(task['completedAt'])} 확인했어요',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: ops.busy || task['canComplete'] != true
                        ? null
                        : () => task['kind'] == 'stock'
                              ? checkStock(
                                  item(task['itemId'])!,
                                  taskId: task['id'],
                                )
                              : act('complete_task', {'taskId': task['id']}),
                    child: Text(
                      task['canComplete'] == true
                          ? task['kind'] == 'stock'
                                ? '재고 수량 확인하기'
                                : '확인했어요'
                          : '${roleLabels[task['requiredRole']]} 담당 업무',
                    ),
                  ),
                ),
            ],
          ),
        ),
        gap(10),
      ],
      if (ops.isLeader)
        OutlinedButton.icon(
          onPressed: ops.busy ? null : createTask,
          icon: const Icon(Icons.add),
          label: const Text('시간대·직급별 반복 업무 만들기'),
        ),
    ];
  }

  List<Widget> inventory() => [
    const PageHeading(
      'PANTRY & ORDERS',
      '채워 두면, 든든해요 🥕',
      '수량을 확인하고 필요한 재료를 한 번에 모아요.',
    ),
    if (ops.isLeader) ...[
      Surface(
        color: AppColors.lime.withValues(alpha: .5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보충 확인 ${lowStock.length}개 · 담은 재료 ${cart.length}개',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            gap(8),
            small('공급처별로 나눠 정리해요. 결제·문자·카카오 전송은 없는 체험이에요.'),
            gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: lowStock.isEmpty
                      ? null
                      : () => setState(() {
                          for (final i in lowStock) {
                            cart[i['id']] = (i['orderQuantity'] as num)
                                .toDouble();
                          }
                        }),
                  child: const Text('부족한 재료 담기'),
                ),
                FilledButton(
                  onPressed: cart.isEmpty || ops.busy ? null : reviewOrder,
                  child: Text('발주함 보기 (${cart.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
      gap(18),
    ] else ...[
      const Information('재고 수량 확인과 보충 요청은 누구나 할 수 있어요. 발주는 사장님·매니저가 확인해요.'),
      gap(),
    ],
    for (final i in ops.rows('items')) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(i['emoji'], style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i['name'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      small('${zoneName(i['zone'])} · ${i['supplier']}'),
                    ],
                  ),
                ),
                Text(
                  '${qty(i['quantity'])}${i['unit']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            gap(12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                badge(
                  pending(i['id'])
                      ? '입고 기다리는 중'
                      : (i['quantity'] as num) <= (i['minimum'] as num)
                      ? '보충 확인'
                      : '여유 있어요',
                  color: (i['quantity'] as num) <= (i['minimum'] as num)
                      ? const Color(0xFFFFE6D4)
                      : AppColors.lime,
                ),
                if (i['restockRequestedBy'] != null)
                  badge(
                    '${i['restockRequestedBy']['name']}님 보충 요청',
                    color: AppColors.paper,
                  ),
              ],
            ),
            gap(8),
            small(
              i['checkedBy'] == null
                  ? '아직 실물 수량을 확인하지 않았어요'
                  : '${i['checkedBy']['name']}님 · ${time(i['lastCheckedAt'])} 수량 확인',
            ),
            small(
              '기준 ${qty(i['minimum'])}${i['unit']} 이하 · 발주 ${i['reviewDays']}일 후 확인',
            ),
            if (i['lastOrderedAt'] != null)
              small(
                i['reviewState'] == 'completed'
                    ? '이번 발주 확인 완료 · ${i['reviewCompletedBy']?['name'] ?? ''}님 ${time(i['reviewCompletedAt'])}'
                    : '확인 예정 ${nextCheck(i)} · 중간에 수량을 확인해도 날짜는 유지돼요',
              ),
            gap(10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                OutlinedButton(
                  onPressed: ops.busy ? null : () => checkStock(i),
                  child: const Text('수량 확인'),
                ),
                if (ops.isLeader)
                  FilledButton.tonal(
                    onPressed: pending(i['id'])
                        ? null
                        : () => setState(() {
                            if (cart.containsKey(i['id'])) {
                              cart.remove(i['id']);
                            } else {
                              cart[i['id']] = (i['orderQuantity'] as num)
                                  .toDouble();
                            }
                          }),
                    child: Text(
                      cart.containsKey(i['id']) ? '담았어요 ✓' : '발주함 담기',
                    ),
                  )
                else
                  TextButton(
                    onPressed: ops.busy || i['restockRequestedBy'] != null
                        ? null
                        : () => act('request_restock', {'itemId': i['id']}),
                    child: const Text('보충 요청'),
                  ),
                if (ops.isLeader)
                  TextButton(
                    onPressed: ops.busy ? null : () => reviewPolicy(i),
                    child: const Text('확인 기준'),
                  ),
              ],
            ),
          ],
        ),
      ),
      gap(12),
    ],
    title('📦 발주와 입고 내역'),
    if (ops.rows('orders').isEmpty)
      const Information('아직 발주 내역이 없어요. 발주함에서 수량을 확인한 뒤 한 번에 데모 발주해 보세요.'),
    for (final order in ops.rows('orders').take(10)) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badge(order['status'] == 'ordered' ? '데모 발주 · 입고 대기' : '입고 확인 완료'),
            gap(9),
            Text(
              (order['lines'] as List)
                  .map((l) => '${l['name']} ${qty(l['quantity'])}${l['unit']}')
                  .join(' · '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            gap(8),
            small(
              '${order['placedBy']['name']}님 · ${time(order['createdAt'])}',
            ),
            if (order['total'] != null)
              small('예시 금액 ${money(order['total'])}원 · 실제 청구 없음'),
            if (order['receivedBy'] != null)
              small(
                '${order['receivedBy']['name']}님이 ${time(order['receivedAt'])} 입고 확인',
              ),
            if (ops.isLeader && order['status'] == 'ordered') ...[
              gap(10),
              OutlinedButton(
                onPressed: ops.busy ? null : () => receiveOrder(order),
                child: const Text('입고 확인하고 재고 반영'),
              ),
            ],
          ],
        ),
      ),
      gap(10),
    ],
  ];

  String nextCheck(Json i) {
    final ordered = DateTime.parse(i['lastOrderedAt']);
    return time(
      i['reviewDueAt'] ??
          ordered.add(Duration(days: i['reviewDays'] as int)).toIso8601String(),
    );
  }

  List<Widget> team() => [
    const PageHeading(
      'OUR LITTLE TEAM',
      '서로의 빈자리를 알아요 🤝',
      '근무와 공석은 함께, 개인 사유와 급여는 비공개로.',
    ),
    Surface(
      color: const Color(0xFFFFEFE4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 공석 ${gaps.length}곳',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          gap(7),
          small('대체 가능 표시만으로 근무가 확정되지는 않아요. 사장님·매니저 확인 후 함께 반영돼요.'),
        ],
      ),
    ),
    gap(18),
    for (final shift in ops.rows('shifts')) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lime.withValues(alpha: .6),
                  child: Text(shift['person'].toString().substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shift['person']} · ${shift['role']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      small(shift['time']),
                    ],
                  ),
                ),
                badge(
                  shift['status'],
                  color: shift['status'] == '휴가'
                      ? const Color(0xFFFFE6D4)
                      : AppColors.lime,
                ),
              ],
            ),
            if (shift['status'] == '휴가') ...[
              gap(12),
              small(
                shift['covering'] == null
                    ? '아직 대체 근무자가 없어요'
                    : '✓ ${shift['covering']['name']}님이 이 시간을 함께해요',
              ),
              if (shift['covering'] == null) ...[
                gap(8),
                OutlinedButton(
                  onPressed:
                      ops.busy ||
                          ops
                              .rows('coverRequests')
                              .any(
                                (r) =>
                                    r['shiftId'] == shift['id'] &&
                                    r['actor']['id'] == ops.actorId &&
                                    r['status'] == 'pending',
                              )
                      ? null
                      : () => act('offer_cover', {'shiftId': shift['id']}),
                  child: const Text('저 이 시간 가능해요 🙋'),
                ),
              ],
            ],
            if (shift['updatedBy'] != null)
              small(
                '${shift['updatedBy']['name']}님이 ${time(shift['updatedAt'])} 변경',
              ),
            if (ops.isLeader)
              TextButton(
                onPressed: ops.busy ? null : () => changeShift(shift),
                child: Text(shift['status'] == '휴가' ? '근무로 변경' : '휴가로 변경'),
              ),
          ],
        ),
      ),
      gap(10),
    ],
    if (ops.isLeader) ...[
      title('🙋 대체 근무 확인'),
      if (!ops.rows('coverRequests').any((r) => r['status'] == 'pending'))
        const Information('확인을 기다리는 신청이 없어요.'),
      for (final request
          in ops.rows('coverRequests').where((r) => r['status'] == 'pending'))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request['actor']['name']}님이 가능해요'),
                small(
                  '${ops.rows('shifts').where((s) => s['id'] == request['shiftId']).first['time']} · 근무 가능 여부를 확인해 주세요',
                ),
                gap(8),
                FilledButton(
                  onPressed: ops.busy
                      ? null
                      : () => act('assign_cover', {'requestId': request['id']}),
                  child: const Text('대체 근무 확정'),
                ),
              ],
            ),
          ),
        ),
    ],
    gap(),
    const Information(
      '함께 보기: 이름·담당·근무 시간·휴가 여부·대체 근무\n비공개: 휴가 사유·급여·사장님 메모\n지금은 샘플 근무표이며 급여·근태·법정 서류는 연동 전이에요.',
    ),
  ];

  List<Widget> floorPlan() {
    final routes = {
      '재료 준비': ['storage', 'fridge', 'prep', 'stove'],
      '설거지': ['pass', 'sink', 'storage'],
      '첫 출근': ['entrance', 'exit', 'sink', 'prep'],
    };
    final path = routes[route]!;
    return [
      const PageHeading(
        'KNOW YOUR PLACE',
        '어디에 있는지, 바로 🗺️',
        '장소를 누르면 도구와 보관 안내를 볼 수 있어요.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final key in routes.keys)
            ChoiceChip(
              label: Text(key),
              selected: key == route,
              onSelected: (_) => setState(() => route = key),
            ),
        ],
      ),
      gap(),
      Surface(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '작은주방 배치 예시 · 실제 도면 아님',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 416,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoutePainter(ops.rows('zones'), path),
                      ),
                    ),
                    for (final zone in ops.rows('zones'))
                      Positioned(
                        left:
                            constraints.maxWidth *
                            (zone['x'] as num).toDouble(),
                        top: 416 * (zone['y'] as num).toDouble(),
                        width: constraints.maxWidth * .41,
                        height: 79,
                        child: Material(
                          color: path.contains(zone['id'])
                              ? AppColors.lime
                              : AppColors.paper,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: path.contains(zone['id'])
                                  ? AppColors.green
                                  : AppColors.line,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => zoneDetails(zone),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${zone['emoji']}${path.contains(zone['id']) ? '  ${path.indexOf(zone['id']) + 1}' : ''}',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    zone['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      gap(14),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$route 순서',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            gap(8),
            for (var n = 0; n < path.length; n++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '${n + 1}. ${zoneName(path[n])}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
      gap(),
      const Information(
        '예시 동선이에요. 실제 장비 사용법과 안전·비상 동선은 현장에서 버디와 확인해 주세요. 실제 매장 도면 등록은 다음 단계예요.',
      ),
    ];
  }

  Future<void> checkStock(Json i, {String? taskId}) async {
    final controller = TextEditingController(text: qty(i['quantity']));
    final values = await formDialog(
      '실제로 몇 ${i['unit']} 있나요?',
      [
        small('${i['emoji']} ${i['name']} · ${zoneName(i['zone'])}'),
        gap(),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '현재 수량 (${i['unit']})',
            border: const OutlineInputBorder(),
          ),
        ),
        gap(),
        small('${ops.actor['name']}님이 확인한 기록으로 함께 보여요.'),
      ],
      () {
        final value = double.tryParse(controller.text);
        return value != null && value.isFinite && value >= 0 && value <= 100000
            ? {'quantity': value}
            : null;
      },
    );
    if (values != null) {
      await act(taskId == null ? 'check_stock' : 'complete_task', {
        ...values,
        if (taskId != null) 'taskId': taskId else 'itemId': i['id'],
      });
    }
    controller.dispose();
  }

  Future<void> reviewPolicy(Json i) async {
    final days = TextEditingController(text: '${i['reviewDays']}');
    final minimum = TextEditingController(text: qty(i['minimum']));
    final values = await formDialog(
      '재고 확인 기준',
      [
        small(
          '${i['name']} · 마지막 발주일에서 정해진 일수 뒤 한 번 확인해요. 중간 수량 확인은 예정일을 미루지 않아요.',
        ),
        gap(),
        TextField(
          controller: days,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '발주 며칠 후 확인할까요? (1~90일)',
          ),
        ),
        gap(),
        TextField(
          controller: minimum,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '보충 기준 (${i['unit']} 이하)'),
        ),
      ],
      () {
        final d = int.tryParse(days.text);
        final m = double.tryParse(minimum.text);
        return d != null &&
                d >= 1 &&
                d <= 90 &&
                m != null &&
                m.isFinite &&
                m >= 0 &&
                m <= 100000
            ? {'reviewDays': d, 'minimum': m}
            : null;
      },
    );
    if (values != null) {
      await act('review_policy', {'itemId': i['id'], ...values});
    }
    days.dispose();
    minimum.dispose();
  }

  Future<void> reviewOrder() async {
    final entries = cart.entries
        .where((e) => item(e.key) != null && !pending(e.key))
        .toList();
    if (entries.isEmpty) {
      setState(cart.clear);
      return;
    }
    final controllers = {
      for (final e in entries) e.key: TextEditingController(text: qty(e.value)),
    };
    final suppliers = entries
        .map((e) => item(e.key)!['supplier'] as String)
        .toSet();
    final values = await formDialog(
      '모아서 데모 발주 📦',
      [
        const Information(
          '실제 공급처로 전송하거나 결제하지 않아요. 발주 기록만 생성하며 입고 확인 전에는 재고가 늘지 않아요.',
        ),
        gap(),
        for (final supplier in suppliers) ...[
          title(supplier),
          for (final e in entries.where(
            (e) => item(e.key)!['supplier'] == supplier,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[e.key],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${item(e.key)!['name']} (${item(e.key)!['unit']})',
                  helperText: '단가 ${money(item(e.key)!['price'])}원 · 예시',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
        small('선택한 모든 공급처의 항목을 한 번에 기록해요.'),
      ],
      () {
        final lines = <Json>[];
        for (final e in entries) {
          final value = double.tryParse(controllers[e.key]!.text);
          if (value == null ||
              !value.isFinite ||
              value <= 0 ||
              value > 100000) {
            return null;
          }
          lines.add({'itemId': e.key, 'quantity': value});
        }
        return {'lines': lines};
      },
      confirm: '한 번에 데모 발주',
    );
    if (values != null && await act('place_order', values) && mounted) {
      setState(cart.clear);
    }
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  Future<void> receiveOrder(Json order) async {
    final result = await formDialog(
      '재료가 모두 도착했나요?',
      [
        small('확인하면 아래 수량이 재고에 반영돼요. 중복 입고는 처리하지 않아요.'),
        gap(),
        Text(
          (order['lines'] as List)
              .map((l) => '${l['name']} ${qty(l['quantity'])}${l['unit']}')
              .join('\n'),
        ),
      ],
      () => {'orderId': order['id']},
      confirm: '입고 확인',
    );
    if (result != null) await act('receive_order', result);
  }

  Future<void> changeShift(Json shift) async {
    final status = shift['status'] == '휴가' ? '근무' : '휴가';
    final result = await formDialog(
      '$status로 변경할까요?',
      [
        Text('${shift['person']}님 · ${shift['time']}'),
        gap(),
        small(
          '이 변경은 모두에게 보여요. 기존 대체 배정·대기 신청은 해제되므로 팀과 먼저 확인해 주세요. 개인 휴가 사유는 입력하지 않아요.',
        ),
      ],
      () => {'shiftId': shift['id'], 'status': status},
      confirm: '팀에 반영',
    );
    if (result != null) await act('update_shift', result);
  }

  Future<void> createTask() async {
    final name = TextEditingController();
    var selectedSlot = '오픈';
    var selectedRole = 'all';
    var zone = 'entrance';
    final values = await formDialog(
      '매일 함께 확인할 일',
      [
        TextField(
          controller: name,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '업무 이름'),
        ),
        gap(),
        DropdownButtonFormField<String>(
          initialValue: selectedSlot,
          decoration: const InputDecoration(labelText: '시간대'),
          items: [
            for (final s in slotLabels)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (v) => selectedSlot = v!,
        ),
        gap(),
        DropdownButtonFormField<String>(
          initialValue: selectedRole,
          decoration: const InputDecoration(labelText: '담당 직급'),
          items: [
            for (final e in roleLabels.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => selectedRole = v!,
        ),
        gap(),
        DropdownButtonFormField<String>(
          initialValue: zone,
          decoration: const InputDecoration(labelText: '장소'),
          items: [
            for (final z in ops.rows('zones'))
              DropdownMenuItem<String>(value: z['id'], child: Text(z['name'])),
          ],
          onChanged: (v) => zone = v!,
        ),
        gap(),
        small('매일 새 체크리스트로 나타나요. 사장님·매니저는 모든 담당 업무를 확인할 수 있어요.'),
      ],
      () => name.text.trim().isEmpty
          ? null
          : {
              'title': name.text.trim(),
              'slot': selectedSlot,
              'requiredRole': selectedRole,
              'zone': zone,
            },
    );
    if (values != null) await act('create_task', values);
    name.dispose();
  }

  Future<void> zoneDetails(Json zone) async {
    final name = TextEditingController(text: zone['name']);
    final description = TextEditingController(text: zone['description']);
    final values = await formDialog(
      '${zone['emoji']} ${zone['name']}',
      [
        if (ops.isLeader) ...[
          TextField(
            controller: name,
            maxLength: 30,
            decoration: const InputDecoration(labelText: '장소 이름'),
          ),
          gap(),
          TextField(
            controller: description,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(labelText: '도구·위치 안내'),
          ),
        ] else
          Text(zone['description'], style: const TextStyle(height: 1.8)),
        if (ops.rows('items').any((i) => i['zone'] == zone['id'])) ...[
          gap(),
          small(
            '보관 재료: ${ops.rows('items').where((i) => i['zone'] == zone['id']).map((i) => i['name']).join(', ')}',
          ),
        ],
      ],
      () => name.text.trim().isEmpty || description.text.trim().isEmpty
          ? null
          : {
              'zoneId': zone['id'],
              'name': name.text.trim(),
              'description': description.text.trim(),
            },
      confirm: ops.isLeader ? '안내 저장' : '확인',
    );
    if (values != null && ops.isLeader) await act('edit_zone', values);
    name.dispose();
    description.dispose();
  }

  Future<Json?> formDialog(
    String heading,
    List<Widget> children,
    Json? Function() collect, {
    String confirm = '확인하고 저장',
  }) async {
    String? validation;
    final formRevision = ops.data!['revision'];
    final dialogRoute = DialogRoute<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            heading,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...children,
                  if (validation != null) ...[
                    gap(),
                    Text(
                      validation!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: ops.readOnly
                  ? null
                  : () {
                      final values = collect();
                      if (values == null) {
                        update(() => validation = '이름이나 수량의 입력 범위를 확인해 주세요.');
                      } else {
                        Navigator.pop(context, {
                          ...values,
                          'revision': formRevision,
                        });
                      }
                    },
              child: Text(ops.readOnly ? '미리보기 · 저장 불가' : confirm),
            ),
          ],
        ),
      ),
    );
    final result = await Navigator.of(context).push(dialogRoute);
    // Keep field controllers alive until the closing transition unmounts them.
    await dialogRoute.completed;
    return result;
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.zones, this.route);
  final List<Json> zones;
  final List<String> route;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green.withValues(alpha: .35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final points = route.map((id) {
      final z = zones.firstWhere((z) => z['id'] == id);
      return Offset(
        size.width * ((z['x'] as num).toDouble() + .205),
        size.height * (z['y'] as num).toDouble() + 39,
      );
    }).toList();
    for (var n = 1; n < points.length; n++) {
      canvas.drawLine(points[n - 1], points[n], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.zones != zones;
}
