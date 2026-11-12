import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 我的页快捷按钮：勾选控制显示，上下箭头调顺序。
/// 关掉时把勾去掉即可，位置仍然保留，重新勾上就回到原处。
class MineButtonsDialog extends StatefulWidget {
  const MineButtonsDialog({
    super.key,
    required this.labels,
    required this.order,
    required this.shown,
  });

  final Map<String, String> labels;
  final List<String> order;
  final Set<String> shown;

  @override
  State<MineButtonsDialog> createState() => _MineButtonsDialogState();
}

class _MineButtonsDialogState extends State<MineButtonsDialog> {
  late final List<String> _order = [...widget.order];
  late final Set<String> _shown = {...widget.shown};

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _order.length) return;
    setState(() {
      final key = _order.removeAt(index);
      _order.insert(target, key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: const Text('我的页快捷按钮'),
      contentPadding: const EdgeInsets.only(top: 4),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            children: [
              for (final (index, key) in _order.indexed)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 8, right: 2),
                  leading: Checkbox(
                    value: _shown.contains(key),
                    onChanged: (value) => setState(() {
                      if (value ?? false) {
                        _shown.add(key);
                      } else {
                        _shown.remove(key);
                      }
                    }),
                  ),
                  title: Text(
                    widget.labels[key] ?? key,
                    style: _shown.contains(key)
                        ? null
                        : TextStyle(color: theme.colorScheme.outline),
                  ),
                  trailing: Row(
                    mainAxisSize: .min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: '上移',
                        onPressed: index == 0 ? null : () => _move(index, -1),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        tooltip: '下移',
                        onPressed:
                            index == _order.length - 1
                            ? null
                            : () => _move(index, 1),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text(
            '取消',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: (_order, _shown)),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
