import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';

// Wrapper to distinguish "전체 자녀 선택" (value=null) from "메뉴 닫기" (returns null)
class _Opt {
  final String? child;
  const _Opt(this.child);
}

class ChildFilterDropdown extends StatefulWidget {
  const ChildFilterDropdown({super.key});

  @override
  State<ChildFilterDropdown> createState() => _ChildFilterDropdownState();
}

class _ChildFilterDropdownState extends State<ChildFilterDropdown> {
  final _pillKey = GlobalKey();

  Future<void> _openMenu({
    required BuildContext context,
    required List<String> children,
    required ChildFilterProvider filterProvider,
    required String? effective,
  }) async {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final top = pos.dy + size.height + 4;
    // left==right이면 Flutter가 x = left - menuWidth/2 로 계산 → 화면 정중앙 기준 가운데 정렬
    final half = screenWidth / 2;

    final result = await showMenu<_Opt>(
      context: context,
      position: RelativeRect.fromLTRB(half, top, half, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: Colors.white,
      items: [
        ...children.map(
          (name) => PopupMenuItem<_Opt>(
            value: _Opt(name),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MenuItem(label: name, isSelected: effective == name),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<_Opt>(
          value: const _Opt(null),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MenuItem(label: '전체 자녀', isSelected: effective == null),
        ),
      ],
    );

    if (result != null) {
      filterProvider.select(result.child);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final children = ({...expenseChildren, ...scheduleChildren}).toList()
      ..sort();

    if (children.isEmpty) return const SizedBox();

    if (children.length == 1) {
      return _Pill(label: children.first, showChevron: false);
    }

    final filterProvider = context.watch<ChildFilterProvider>();
    final current = filterProvider.selectedChild;
    final effective =
        (current != null && children.contains(current)) ? current : null;
    final displayName = effective ?? '전체 자녀';

    return GestureDetector(
      onTap: () => _openMenu(
        context: context,
        children: children,
        filterProvider: filterProvider,
        effective: effective,
      ),
      child: _Pill(key: _pillKey, label: displayName, showChevron: true),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _MenuItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isSelected)
          const Icon(Icons.check, size: 16, color: Colors.blue)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ],
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
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
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
              color: Colors.black87,
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
