import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

String _number(num value) => value.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);
String _clock(dynamic value) {
  final d = DateTime.tryParse('$value')?.toUtc().add(const Duration(hours: 9));
  return d == null
      ? '—'
      : '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class StoreDashboard extends StatefulWidget {
  const StoreDashboard({
    super.key,
    required this.operations,
    required this.onNavigate,
  });
  final OperationsController operations;
  final ValueChanged<int> onNavigate;
  @override
  State<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  int days = 1;
  String channel = '전체';
  String category = '전체';
  String query = '';
  String sort = '매출순';
  String queueStatus = '전체';
  OperationsController get ops => widget.operations;
  Widget space([double value = 16]) => SizedBox(height: value);
  Widget note(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.muted),
  );
  Widget heading(String text, String detail) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 5),
        note(detail),
      ],
    ),
  );
  Widget chips(
    List<String> values,
    String selected,
    ValueChanged<String> select,
  ) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: values
        .map(
          (value) => ChoiceChip(
            label: Text(value),
            selected: value == selected,
            onSelected: (_) => setState(() => select(value)),
            selectedColor: AppColors.lime,
            labelStyle: const TextStyle(fontSize: 12),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        )
        .toList(),
  );
  Widget adaptive(List<Widget> children, {double minWidth = 240}) =>
      LayoutBuilder(
        builder: (context, box) {
          final columns = (box.maxWidth / (box.maxWidth < 600 ? 135 : minWidth))
              .floor()
              .clamp(1, children.length);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map(
                  (child) => SizedBox(
                    width: (box.maxWidth - (columns - 1) * 12) / columns,
                    child: child,
                  ),
                )
                .toList(),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final dashboard = ops.data?['dashboard'] as Json?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          '${ops.data?['store']?['name'] ?? '작은주방 · 연남'}  /  ${ops.data?['day'] ?? ''}',
          '매장 한눈에',
          '주문이 들어오는 순간부터, 오늘의 매출과 우리 팀까지.',
        ),
        if (dashboard == null) ...[
          const Information('메뉴·매출 데이터를 아직 불러오지 못했어요. 새로고침 후 다시 확인해 주세요.'),
          TextButton.icon(
            onPressed: () => ops.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('현황 새로고침'),
          ),
        ] else
          ...sales(dashboard),
        space(24),
        heading('오늘의 운영', '기간·채널 필터와 별개로, 지금 확인할 매장 상황이에요.'),
        operations(),
      ],
    );
  }

  List<Widget> sales(Json dashboard) {
    final reports = (dashboard['reports'] as List).cast<Json>();
    final report = reports.firstWhere(
      (r) => r['days'] == days && r['channel'] == channel,
    );
    final summary = report['summary'] as Json;
    final money = dashboard['showMoney'] == true;
    final allQueue = (dashboard['queue'] as List).cast<Json>();
    return [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          chips(
            ['오늘', '최근 7일'],
            days == 1 ? '오늘' : '최근 7일',
            (value) => days = value == '오늘' ? 1 : 7,
          ),
          chips(['전체', '매장', '포장', '배달'], channel, (value) => channel = value),
        ],
      ),
      space(8),
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          note('${report['startDay']} ~ ${report['endDay']} · 한국 시간'),
          note('샘플 주문 · POS 미연동 · ${_clock(dashboard['asOf'])} 집계'),
          IconButton(
            tooltip: '현황 새로고침',
            onPressed: ops.busy ? null : () => ops.refresh(),
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      space(),
      adaptive([
        metric(
          money ? '순매출' : '전체 주문',
          money
              ? '${_number(summary['revenue'])}원'
              : '${summary['orderCount']}건',
          money ? '결제 금액 − 할인 − 환불' : '취소 주문 제외',
          dark: true,
        ),
        metric(
          '주문 건수',
          '${summary['orderCount']}건',
          '취소 ${summary['cancelledCount']}건 별도',
        ),
        metric(
          money ? '평균 결제액' : '완료 주문',
          money
              ? '${_number(summary['average'])}원'
              : '${report['statuses']['완료']}건',
          money ? '순매출 ÷ 결제 주문 ${summary['paidCount']}건' : '선택 기간·채널 기준',
        ),
        metric('처리 중 주문', '${summary['activeCount']}건', '접수 · 조리 중 · 준비 완료'),
      ], minWidth: 250),
      space(),
      if (money)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: note(
            '결제 정가 ${_number(summary['gross'])}원  −  할인 ${_number(summary['discount'])}원  −  환불 ${_number(summary['refund'])}원\n취소·미결제 제외 · 주문 접수일 기준 · 부가세/배달 수수료 정산 전 샘플 집계',
          ),
        ),
      LayoutBuilder(
        builder: (context, box) {
          final left = Column(
            children: [
              menuPanel(report, money),
              space(),
              hourPanel(report, money),
            ],
          );
          final right = queuePanel(allQueue);
          if (box.maxWidth < 950) {
            return Column(children: [left, space(), right]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: left),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: right),
            ],
          );
        },
      ),
    ];
  }

  Widget metric(
    String label,
    String value,
    String detail, {
    bool dark = false,
  }) => Surface(
    color: dark ? AppColors.green : AppColors.white,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: dark ? AppColors.lime : AppColors.muted,
          ),
        ),
        space(12),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
              color: dark ? Colors.white : AppColors.ink,
            ),
          ),
        ),
        space(8),
        Text(
          detail,
          style: TextStyle(
            fontSize: 11,
            color: dark ? const Color(0xFFDDE5D5) : AppColors.muted,
          ),
        ),
      ],
    ),
  );

  Widget menuPanel(Json report, bool money) {
    final all = (report['menus'] as List).cast<Json>();
    final categories = [
      '전체',
      ...all.map((m) => m['category'] as String).toSet(),
    ];
    final menus = all
        .where(
          (m) =>
              (category == '전체' || m['category'] == category) &&
              (m['name'] as String).contains(query.trim()),
        )
        .toList();
    final field = money && sort == '매출순' ? 'revenue' : 'orderedQuantity';
    menus.sort((a, b) {
      final byValue = (b[field] as num).compareTo(a[field] as num);
      return byValue != 0
          ? byValue
          : (a['name'] as String).compareTo(b['name']);
    });
    final maximum = all.fold<num>(
      0,
      (v, m) => (m[field] as num) > v ? m[field] as num : v,
    );
    final total = report['summary']['revenue'] as num? ?? 0;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            money ? '메뉴별 매출 · 주문' : '메뉴별 주문',
            '전체 ${all.length}개 메뉴 · 주문 없는 메뉴도 함께 보여요.',
          ),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: '메뉴 이름 검색',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              isDense: true,
            ),
          ),
          space(8),
          chips(categories, category, (value) => category = value),
          if (money)
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: sort,
                underline: const SizedBox(),
                items: ['매출순', '주문수량순']
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => sort = value!),
              ),
            ),
          if (menus.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: note('검색 조건에 맞는 메뉴가 없어요.'),
            ),
          for (final (index, menu) in menus.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          menu['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        money
                            ? '${_number(menu['revenue'])}원'
                            : '${menu['orderedQuantity']}개',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  space(7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maximum == 0 ? 0 : (menu[field] as num) / maximum,
                      minHeight: 5,
                      color: index == 0
                          ? AppColors.green
                          : const Color(0xFF93AB77),
                      backgroundColor: AppColors.paper,
                    ),
                  ),
                  space(6),
                  note(
                    '주문 ${menu['orderedQuantity']}개 · 처리 중 ${menu['pendingQuantity']}개${money ? ' · 매출 비중 ${total == 0 ? '0' : ((menu['revenue'] as num) / total * 100).toStringAsFixed(1)}%' : ''}',
                  ),
                ],
              ),
            ),
          note('주문 수량은 취소 제외, 미결제 포함${money ? '. 매출은 할인·환불 반영' : ''}.'),
        ],
      ),
    );
  }

  Widget queuePanel(List<Json> all) {
    final visible = all
        .where((o) => queueStatus == '전체' || o['status'] == queueStatus)
        .toList();
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('지금 처리할 주문', '전체 채널 ${all.length}건 · 오래된 주문부터 · 기간 필터와 무관'),
          chips(
            ['전체', '접수', '조리 중', '준비 완료'],
            queueStatus,
            (value) => queueStatus = value,
          ),
          space(12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: note('이 상태에서 처리할 주문이 없어요.'),
            ),
      for (final order in visible)
        Container(
          width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '#${order['number']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order['status'] == '준비 완료'
                              ? AppColors.lime
                              : const Color(0xFFF8DEC6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order['status'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  space(7),
                  note(
                    '${order['channel']}${order['table'] == null ? '' : ' · ${order['table']}'} · 접수 후 ${order['elapsedMinutes']}분',
                  ),
                  space(8),
                  for (final line in order['lines'] as List)
                    Text(
                      '${line['name']} × ${line['quantity']}',
                      style: const TextStyle(fontSize: 13, height: 1.8),
                    ),
                  space(6),
                  note('${_clock(order['createdAt'])} 접수'),
                ],
              ),
            ),
          note('샘플 주문 상태예요. 실제 주문 접수·주방 전송은 아직 연결되지 않았어요.'),
        ],
      ),
    );
  }

  Widget hourPanel(Json report, bool money) {
    final hours = (report['hours'] as List).cast<Json>();
    final field = money ? 'revenue' : 'count';
    final maximum = hours.fold<num>(
      0,
      (v, h) => (h[field] as num) > v ? h[field] as num : v,
    );
    final peak = hours.reduce(
      (a, b) => (a[field] as num) >= (b[field] as num) ? a : b,
    );
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            money ? '시간대별 매출' : '시간대별 주문',
            maximum == 0
                ? '선택한 기간에 집계된 주문이 없어요.'
                : '${peak['hour']}시에 가장 많았어요 · ${days == 1 ? '오늘' : '7일 합산'}',
          ),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final hour in hours)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${hour['hour']}시 · ${money ? '${_number(hour[field])}원' : '${hour[field]}건'}',
                      child: Semantics(
                        label:
                            '${hour['hour']}시 ${_number(hour[field])}${money ? '원' : '건'}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: maximum == 0
                                ? 2
                                : 2 + (hour[field] as num) / maximum * 110,
                            decoration: BoxDecoration(
                              color: hour == peak && maximum > 0
                                  ? AppColors.green
                                  : const Color(0xFFB6C991),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          space(8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00시'),
              Text('06시'),
              Text('12시'),
              Text('18시'),
              Text('23시'),
            ],
          ),
          space(8),
          note('한국 시간 · 주문 접수 시각 기준'),
        ],
      ),
    );
  }

  Widget operations() {
    final tasks = ops.rows('tasks');
    final done = tasks.where((t) => t['completedAt'] != null).length;
    final low = ops
        .rows('items')
        .where((i) => (i['quantity'] as num) <= (i['minimum'] as num))
        .toList();
    final orders = ops
        .rows('orders')
        .where((o) => o['status'] == 'ordered')
        .length;
    final shifts = ops.rows('shifts');
    final gaps = shifts
        .where((s) => s['status'] == '휴가' && s['covering'] == null)
        .length;
    final work = shifts
        .where((s) => s['status'] == '근무' || s['covering'] != null)
        .length;
    Widget tile(
      IconData icon,
      String title,
      String value,
      String detail,
      int destination,
    ) => Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onNavigate(destination),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 13)),
                  ),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
              space(12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              space(8),
              note(detail),
            ],
          ),
        ),
      ),
    );
    return adaptive([
      tile(
        Icons.checklist,
        '공유 체크리스트',
        '$done / ${tasks.length} 완료',
        '남은 확인 ${tasks.length - done}개',
        1,
      ),
      tile(
        Icons.inventory_2_outlined,
        '부족 재료',
        '${low.length}개',
        low.isEmpty ? '최소 수량 이하 재료 없음' : low.map((i) => i['name']).join(' · '),
        2,
      ),
      tile(
        Icons.local_shipping_outlined,
        '발주 · 입고',
        '$orders건 입고 대기',
        '입고 확인 후 재고에 반영',
        2,
      ),
      tile(
        Icons.people_outline,
        '오늘 근무표',
        '$work명 근무 예정',
        '대체 근무 미정 $gaps건 · 실시간 출근 정보 아님',
        3,
      ),
    ], minWidth: 250);
  }
}
