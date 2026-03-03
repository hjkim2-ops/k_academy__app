import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/screens/home_screen.dart';
import 'package:k_academy__app/services/export_service.dart';
import 'package:k_academy__app/widgets/child_filter_dropdown.dart';

class ExpenseStatsScreen extends StatefulWidget {
  const ExpenseStatsScreen({super.key});

  @override
  State<ExpenseStatsScreen> createState() => _ExpenseStatsScreenState();
}

class _ExpenseStatsScreenState extends State<ExpenseStatsScreen> {
  String _period = '이번달';
  DateTimeRange? _customRange;

  static const _periods = ['이번달', '지난달', '3개월', '올해'];

  List<Expense> _filtered(List<Expense> all, String? selectedChild) {
    // Apply child filter first
    final byChild = selectedChild == null
        ? all
        : all.where((e) => e.childName == selectedChild).toList();

    // Then apply period filter
    final now = DateTime.now();
    DateTime from;
    switch (_period) {
      case '지난달':
        final last = DateTime(now.year, now.month - 1);
        from = DateTime(last.year, last.month);
        final to = DateTime(last.year, last.month + 1);
        return byChild
            .where((e) =>
                !e.paymentDate.isBefore(from) && e.paymentDate.isBefore(to))
            .toList();
      case '3개월':
        from = DateTime(now.year, now.month - 2);
        break;
      case '올해':
        from = DateTime(now.year, 1);
        break;
      case '기간 설정':
        if (_customRange == null) return byChild;
        final to = _customRange!.end.add(const Duration(days: 1));
        return byChild
            .where((e) =>
                !e.paymentDate.isBefore(_customRange!.start) &&
                e.paymentDate.isBefore(to))
            .toList();
      default: // 이번달
        from = DateTime(now.year, now.month);
    }
    return byChild
        .where((e) => !e.paymentDate.isBefore(from))
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      locale: const Locale('ko'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          datePickerTheme: const DatePickerThemeData(
            headerHeadlineStyle: TextStyle(fontSize: 16),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = '기간 설정';
      });
    }
  }

  String _customRangeLabel() {
    if (_customRange == null) return '기간 설정';
    final s = _customRange!.start;
    final e = _customRange!.end;
    return '${s.month}/${s.day}~${e.month}/${e.day}';
  }

  Map<String, int> _groupBy(List<Expense> list, String Function(Expense) key) {
    final map = <String, int>{};
    for (final e in list) {
      map[key(e)] = (map[key(e)] ?? 0) + (e.amount - e.cancellationAmount);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final selectedChild = context.watch<ChildFilterProvider>().selectedChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('지출통계'),
        centerTitle: false,
        flexibleSpace: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(child: ChildFilterDropdown()),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!auth.isTrialMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'logout') signOutAndRestart(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              ],
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final all = provider.getAllExpenses();
          final filtered = _filtered(all, selectedChild);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _buildEmpty()
                else ...[
                  _buildSummaryCards(filtered),
                  const SizedBox(height: 24),
                  _buildMonthlyChart(filtered),
                  const SizedBox(height: 24),
                  _buildSubjectChart(filtered),
                  const SizedBox(height: 24),
                  _buildChildChart(filtered),
                  const SizedBox(height: 24),
                  _buildExcelButton(filtered, selectedChild),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final isCustom = _period == '기간 설정';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._periods.map((p) {
            final selected = p == _period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) => setState(() => _period = p),
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
          // 기간 설정 버튼
          GestureDetector(
            onTap: _pickCustomRange,
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _customRangeLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCustom ? Colors.white : null,
                      fontWeight:
                          isCustom ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: isCustom ? Colors.white : Colors.grey[600],
                  ),
                ],
              ),
              backgroundColor: isCustom
                  ? Theme.of(context).primaryColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('선택한 기간에 지출 데이터가 없습니다',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Expense> list) {
    final total = list.fold(0, (s, e) => s + e.amount);
    final cancel = list.fold(0, (s, e) => s + e.cancellationAmount);
    final net = total - cancel;

    return Row(
      children: [
        _SummaryCard(label: '총 지출', amount: total, color: Colors.blue),
        const SizedBox(width: 8),
        _SummaryCard(label: '취소 금액', amount: cancel, color: Colors.red),
        const SizedBox(width: 8),
        _SummaryCard(label: '실 지출', amount: net, color: Colors.green),
      ],
    );
  }

  Widget _buildMonthlyChart(List<Expense> list) {
    // 월별로 그룹핑 (yyyy-MM 키)
    final byMonth = <String, int>{};
    for (final e in list) {
      final key = '${e.paymentDate.year}-${e.paymentDate.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + (e.amount - e.cancellationAmount);
    }
    if (byMonth.isEmpty) return const SizedBox();

    // 날짜순 정렬
    final sortedKeys = byMonth.keys.toList()..sort();
    final maxVal = byMonth.values.fold(0, max).toDouble();

    return _ChartCard(
      title: '월별 지출',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: (maxVal / 10000).ceilToDouble() * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, _, rod, __) {
                  final key = sortedKeys[group.x];
                  final month = int.parse(key.split('-')[1]);
                  return BarTooltipItem(
                    '${month}월\n${_fmt(byMonth[key]!)}원',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= sortedKeys.length) return const SizedBox();
                    final month = int.parse(sortedKeys[i].split('-')[1]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${month}월',
                          style: const TextStyle(fontSize: 11)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}만',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.black54),
                bottom: BorderSide(color: Colors.black54),
                top: BorderSide.none,
                right: BorderSide.none,
              ),
            ),
            barGroups: sortedKeys.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: byMonth[e.value]!.toDouble() / 10000,
                    color: Colors.indigo,
                    width: 28,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChildChart(List<Expense> list) {
    final byChild = _groupBy(list, (e) => e.childName);
    if (byChild.isEmpty) return const SizedBox();

    final children = byChild.keys.toList();
    final maxVal = byChild.values.fold(0, max).toDouble();
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.pink
    ];

    return _ChartCard(
      title: '자녀별 지출',
      child: SizedBox(
        height: 200,
        child: BarChart(
        BarChartData(
          maxY: (maxVal / 10000).ceilToDouble() * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${children[group.x]}\n${_fmt(byChild[children[group.x]]!)}원',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= children.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(children[i],
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}만',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.black54),
              bottom: BorderSide(color: Colors.black54),
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          barGroups: children.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: byChild[e.value]!.toDouble() / 10000,
                  color: colors[e.key % colors.length],
                  width: 28,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      ),
    );
  }

  Widget _buildSubjectChart(List<Expense> list) {
    final bySubject = _groupBy(list, (e) => e.subject);
    if (bySubject.isEmpty) return const SizedBox();

    final subjects = bySubject.keys.toList();
    final total = bySubject.values.fold(0, (a, b) => a + b);
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF009688),
      const Color(0xFFFF5722),
      const Color(0xFF607D8B),
    ];

    return _ChartCard(
      title: '과목별 지출',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: subjects.asMap().entries.map((e) {
                  final pct = bySubject[e.value]! / total * 100;
                  return PieChartSectionData(
                    value: bySubject[e.value]!.toDouble(),
                    color: colors[e.key % colors.length],
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: subjects.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.value} ${_fmt(bySubject[e.value]!)}원',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _periodLabel() {
    if (_period == '기간 설정' && _customRange != null) {
      final s = _customRange!.start;
      final e = _customRange!.end;
      return '${s.year}.${s.month.toString().padLeft(2, '0')}.${s.day.toString().padLeft(2, '0')}'
          ' ~ ${e.year}.${e.month.toString().padLeft(2, '0')}.${e.day.toString().padLeft(2, '0')}';
    }
    return _period;
  }

  Widget _buildExcelButton(List<Expense> filtered, String? selectedChild) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          ExportService.exportToExcel(
            filtered,
            childName: selectedChild,
            periodLabel: _periodLabel(),
          );
        },
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Excel 다운로드',
            style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.amount, required this.color});

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${_fmt(amount)}원',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
