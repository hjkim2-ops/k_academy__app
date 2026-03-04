import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';

class ChildFilterDropdown extends StatefulWidget {
  const ChildFilterDropdown({super.key});

  @override
  State<ChildFilterDropdown> createState() => _ChildFilterDropdownState();
}

class _ChildFilterDropdownState extends State<ChildFilterDropdown> {
  final _pillKey = GlobalKey();

  void _openDialog({
    required BuildContext context,
    required List<String> children,
    required ChildFilterProvider filterProvider,
    required DropdownProvider dropdownProvider,
    required String? effective,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _ChildReorderDialog(
        children: children,
        effective: effective,
        onApply: (orderedChildren, selected) {
          dropdownProvider.applyChildNameOrder(orderedChildren);
          filterProvider.select(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdownProvider = context.watch<DropdownProvider>();

    final expenseChildren = context
        .watch<ExpenseProvider>()
        .getAllExpenses()
        .map((e) => e.childName)
        .where((n) => n.isNotEmpty)
        .toSet();

    final scheduleChildren = context
        .watch<ScheduleProvider>()
        .activeSchedules
        .map((s) => s.childName)
        .where((n) => n.isNotEmpty)
        .toSet();

    final allChildren = {...expenseChildren, ...scheduleChildren}.toList();

    if (allChildren.isEmpty) return const SizedBox();

    // DropdownProvider 순서 동기화 후 정렬된 목록 사용
    dropdownProvider.syncChildNameOrder(allChildren);
    final children = dropdownProvider.childNames
        .where((n) => allChildren.contains(n))
        .toList();
    // allChildren에는 있지만 childNames에 없는 항목 추가
    for (final name in allChildren) {
      if (!children.contains(name)) children.add(name);
    }

    if (children.length == 1) {
      return _Pill(label: children.first, showChevron: false);
    }

    final filterProvider = context.watch<ChildFilterProvider>();
    final current = filterProvider.selectedChild;
    final effective =
        (current != null && children.contains(current)) ? current : null;
    final displayName = effective ?? '전체 자녀';

    return GestureDetector(
      onTap: () => _openDialog(
        context: context,
        children: children,
        filterProvider: filterProvider,
        dropdownProvider: dropdownProvider,
        effective: effective,
      ),
      child: _Pill(key: _pillKey, label: displayName, showChevron: true),
    );
  }
}

class _ChildReorderDialog extends StatefulWidget {
  final List<String> children;
  final String? effective;
  final void Function(List<String> orderedChildren, String? selected) onApply;

  const _ChildReorderDialog({
    required this.children,
    required this.effective,
    required this.onApply,
  });

  @override
  State<_ChildReorderDialog> createState() => _ChildReorderDialogState();
}

class _ChildReorderDialogState extends State<_ChildReorderDialog> {
  late List<String> _orderedChildren;
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _orderedChildren = List.from(widget.children);
    _selected = widget.effective;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: _orderedChildren.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex--;
                    final item = _orderedChildren.removeAt(oldIndex);
                    _orderedChildren.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final name = _orderedChildren[index];
                  final isSelected = _selected == name;
                  return Material(
                    key: ValueKey(name),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selected = name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            if (isSelected)
                              const Icon(Icons.check,
                                  size: 16, color: Color(0xFF7BA4D4))
                            else
                              const SizedBox(width: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color:
                                      isSelected ? const Color(0xFF7BA4D4) : const Color(0xFF4A4A4A),
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle,
                                  size: 20, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // 전체 자녀
            InkWell(
              onTap: () => setState(() => _selected = null),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (_selected == null)
                      const Icon(Icons.check, size: 16, color: Color(0xFF7BA4D4))
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 10),
                    Text(
                      '전체 자녀',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _selected == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selected == null
                            ? const Color(0xFF7BA4D4)
                            : const Color(0xFF4A4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // 취소 / 적용 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () {
                      widget.onApply(_orderedChildren, _selected);
                      Navigator.of(context).pop();
                    },
                    child: const Text('적용'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool showChevron;

  const _Pill({super.key, required this.label, required this.showChevron});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 29),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A4A4A),
              letterSpacing: -0.2,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 1),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 9,
              color: Colors.black54,
            ),
          ],
        ],
      ),
    );
  }
}
