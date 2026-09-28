import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  late final int revision;
  late final String actorId;
  late String cycle, size;
  late int monthDay, weekDay, rounding;
  late bool includeRest;
  bool dirty = false, saving = false;
  String? error;
  static const roundingValues = [0, 1, 5, 10, 30];
  static const days = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    final p = widget.ops.data?['payrollSettings'] as Json? ?? {};
    revision = widget.ops.data?['revision'] ?? 0;
    actorId = widget.ops.actorId;
    cycle = p['cycle'] ?? 'monthly';
    size = p['businessSize'] ?? 'unknown';
    monthDay = p['monthStartDay'] ?? 1;
    weekDay = p['weekStartDay'] ?? 1;
    rounding = p['roundingMinutes'] ?? 0;
    includeRest = p['includeWeeklyRest'] ?? true;
  }

  bool get editable =>
      widget.ops.isOwner && !widget.ops.readOnly && !saving && !widget.ops.busy;
  void change(VoidCallback fn) => setState(() {
    fn();
    dirty = true;
  });
  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 버리기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> save() async {
    if (!editable) return;
    if (widget.ops.actorId != actorId) {
      setState(() => error = '계정이 바뀌었어요. 다시 열어 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_payroll_settings', {
      'revision': revision,
      'settings': {
        'cycle': cycle,
        'monthStartDay': monthDay,
        'weekStartDay': weekDay,
        'roundingMinutes': rounding,
        'businessSize': size,
        'includeWeeklyRest': includeRest,
      },
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
      dirty = !ok;
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: '정산 설정',
      subtitle: '시급제 크루의 정산 기준을 설정해요.',
      onClose: close,
      body: !widget.ops.isOwner
          ? const Information('정산 설정은 사장님만 볼 수 있어요.')
          : AbsorbPointer(
              absorbing: saving,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 688),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      AppFormSection(
                        title: '지급 주기',
                        description: '월 고정급 계약이 아닌 시급제 정산 주기예요.',
                        children: [
                          AppChoiceGroup<String>(
                            values: const ['monthly', 'weekly'],
                            selected: cycle,
                            labelOf: (v) => v == 'monthly' ? '월급' : '주급',
                            onSelected: (v) => change(() => cycle = v),
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: '정산 시작일',
                        children: [
                          Text(
                            cycle == 'monthly'
                                ? '매월 $monthDay일'
                                : '매주 ${days[weekDay - 1]}요일',
                            style: AppText.title.copyWith(
                              color: AppColors.green,
                            ),
                          ),
                          AnimatedSize(
                            duration: AppMotion.duration(
                              context,
                              AppMotion.content,
                            ),
                            curve: AppMotion.enterCurve,
                            alignment: Alignment.topCenter,
                            child: cycle == 'monthly'
                                ? Slider(
                                    key: const ValueKey('payroll-start-day'),
                                    value: monthDay.toDouble(),
                                    min: 1,
                                    max: 31,
                                    divisions: 30,
                                    label: '$monthDay일',
                                    semanticFormatterCallback: (value) =>
                                        '매월 ${value.round()}일',
                                    onChanged: (v) =>
                                        change(() => monthDay = v.round()),
                                  )
                                : AppChoiceGroup<int>(
                                    values: const [1, 2, 3, 4, 5, 6, 7],
                                    selected: weekDay,
                                    labelOf: (v) => days[v - 1],
                                    onSelected: (v) =>
                                        change(() => weekDay = v),
                                  ),
                          ),
                          Text(
                            cycle == 'monthly'
                                ? (monthDay == 1
                                      ? '매월 1일부터 말일까지예요.'
                                      : '매월 $monthDay일부터 다음 정산 시작일 전날까지예요. 해당 날짜가 없는 달은 말일에 시작해요.')
                                : '매주 ${days[weekDay - 1]}요일부터 7일간이에요.',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: '정산 시간 반올림',
                        description: '하루의 휴게 제외 시간을 기준으로 계산해요.',
                        children: [
                          AppChoiceGroup<int>(
                            key: const ValueKey('payroll-rounding'),
                            values: roundingValues,
                            selected: rounding,
                            labelOf: (v) => v == 0 ? '없음' : '$v분',
                            onSelected: (v) => change(() => rounding = v),
                          ),
                          Text(
                            rounding == 0
                                ? '기록된 시간 그대로 계산해요.'
                                : '하루의 휴게 제외 시간을 $rounding분 단위로 반올림해 기본급에 반영해요.',
                            style: AppText.caption,
                          ),
                          const Text(
                            '원본 출퇴근 기록과 수당·주휴 요건 판정 시간은 유지해요.',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: '사업장 규모',
                        children: [
                          AppChoiceGroup<String>(
                            values: const ['under5', 'fivePlus'],
                            selected: size,
                            labelOf: (v) => v == 'under5' ? '5인 미만' : '5인 이상',
                            onSelected: (v) => change(() => size = v),
                          ),
                          Text(
                            size == 'unknown'
                                ? '상시근로자 기준 사업장 규모를 선택해 주세요.'
                                : size == 'under5'
                                ? '연장·야간·휴일근로 가산을 예상액에 넣지 않아요.'
                                : '연장·야간·휴일근로 가산을 확인한 근로조건에 따라 계산해요.',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      AppFormSection(
                        title: '주휴수당',
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('주휴수당 포함'),
                            subtitle: Text(
                              includeRest
                                  ? '발생 요건을 확인한 주휴수당을 예상 합계에 넣어요.'
                                  : '주휴 발생 주수만 세고 금액에는 넣지 않아요.',
                            ),
                            value: includeRest,
                            onChanged: (v) => change(() => includeRest = v),
                          ),
                        ],
                      ),
                      const Text(
                        '설정은 현재 예상액에 적용해요. 기존 지급 기록은 바뀌지 않으며, 포함 여부가 지급 의무를 바꾸지는 않아요.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      footer: !widget.ops.isOwner
          ? null
          : AppSheetFooter(
              children: [
                if (widget.ops.readOnly)
                  const Text('공개 미리보기에서는 저장하지 않아요.', style: AppText.caption),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$error\n입력한 내용은 유지했어요.',
                      style: AppText.caption.copyWith(color: AppColors.accent),
                    ),
                  ),
                FilledButton(
                  onPressed: editable && size != 'unknown' ? save : null,
                  child: Text(saving ? '저장 중…' : '정산 설정 저장'),
                ),
              ],
            ),
    ),
  );
}
