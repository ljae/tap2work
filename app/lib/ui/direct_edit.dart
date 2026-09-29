import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Long press and accessible actions share one explicit, permission-gated mode.
class DirectEditFrame extends StatefulWidget {
  const DirectEditFrame({
    super.key,
    required this.child,
    required this.enabled,
    required this.active,
    required this.onEnter,
    this.onRename,
    this.onDelete,
    this.onMove,
    this.onSettings,
    this.controls = true,
  });
  final Widget child;
  final bool enabled, active, controls;
  final VoidCallback onEnter;
  final VoidCallback? onRename, onDelete, onMove, onSettings;
  @override
  State<DirectEditFrame> createState() => _DirectEditFrameState();
}

class _DirectEditFrameState extends State<DirectEditFrame>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: AppMotion.editWiggle,
  );
  bool get active => widget.enabled && widget.active;
  void updateMotion() {
    if (active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!motion.isAnimating) motion.repeat(reverse: true);
    } else {
      motion.stop();
      motion.value = .5;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateMotion();
  }

  @override
  void didUpdateWidget(covariant DirectEditFrame old) {
    super.didUpdateWidget(old);
    updateMotion();
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  void enter() {
    if (widget.enabled) {
      HapticFeedback.selectionClick();
      widget.onEnter();
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    onLongPress: widget.enabled ? enter : null,
    hint: widget.enabled && !active ? '길게 눌러 편집' : null,
    child: GestureDetector(
      onLongPress: widget.enabled ? enter : null,
      onSecondaryTap: widget.enabled ? enter : null,
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, child) => Transform.rotate(
          angle: active && !MediaQuery.disableAnimationsOf(context)
              ? (motion.value - .5) * AppMotion.editWiggleRadians
              : 0,
          child: child,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: active
                ? Border.all(color: AppColors.green, width: 1.5)
                : null,
          ),
          child: !widget.controls
              ? widget.child
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.child,
                    if (active && widget.controls)
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          if (widget.onMove != null)
                            IconButton(
                              tooltip: '위치 이동',
                              onPressed: widget.onMove,
                              icon: const Icon(Icons.open_with, size: 20),
                            ),
                          if (widget.onRename != null)
                            IconButton(
                              tooltip: '이름 변경',
                              onPressed: widget.onRename,
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                          if (widget.onSettings != null)
                            IconButton(
                              tooltip: '상세 설정',
                              onPressed: widget.onSettings,
                              icon: const Icon(Icons.tune, size: 20),
                            ),
                          if (widget.onDelete != null)
                            IconButton(
                              tooltip: '삭제',
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.accent,
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class DirectEditBar extends StatelessWidget {
  const DirectEditBar({
    super.key,
    required this.active,
    required this.onDone,
    this.onAdd,
    this.addLabel = '추가',
  });
  final bool active;
  final VoidCallback onDone;
  final VoidCallback? onAdd;
  final String addLabel;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (active)
        TextButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.check),
          label: const Text('편집 완료'),
        )
      else
        const Text('길게 눌러 편집', style: AppText.caption),
      if (onAdd != null)
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
    ],
  );
}

Future<String?> directEditName(
  BuildContext context,
  String value, {
  String title = '이름 변경',
  int maxLength = 100,
}) async {
  final controller = TextEditingController(text: value);
  final result = await showAppDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        decoration: const InputDecoration(labelText: '이름'),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );
  // Route exit animation still owns the field until the next frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
  return result;
}

Future<void> directEditNode(
  BuildContext context,
  OperationsController ops,
  String action,
  Json command,
  String title,
) async {
  if (ops.readOnly) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('구조 변경은 로그인한 매장에서 저장할 수 있어요.')),
    );
    return;
  }
  final revision = ops.data?['revision'], actor = ops.actorId;
  final deleting = command['operation'] == 'delete';
  String? value;
  if (deleting) {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title 삭제'),
        content: Text(
          action == 'edit_work_node'
              ? '선택한 미완료 업무와 연결된 기본 양식에서 제거해요. 완료 기록은 유지됩니다.'
              : '기본 양식에서 제거해요. 이미 실행한 업무 기록은 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
  } else {
    value = await directEditName(
      context,
      command['operation'] == 'add' ? '' : title,
      title: command['operation'] == 'add' ? '추가' : '이름 변경',
      maxLength: command['kind'] == 'group' ? 40 : 100,
    );
    if (value == null) return;
  }
  if (!context.mounted || actor != ops.actorId || !ops.canEditTasks) return;
  final ok = await ops.act(action, {
    ...command,
    'name': ?value,
    'revision': revision,
  });
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (ops.readOnly ? '체험에 반영했어요. 저장되지는 않아요.' : '반영했어요.')
              : ops.error ?? '변경하지 못했어요.',
        ),
      ),
    );
  }
}
