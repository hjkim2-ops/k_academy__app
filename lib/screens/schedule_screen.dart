import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/models/schedule.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';
import 'package:k_academy__app/providers/selected_date_provider.dart';
import 'package:k_academy__app/screens/home_screen.dart';
import 'package:k_academy__app/widgets/child_filter_dropdown.dart';
import 'package:k_academy__app/widgets/schedule_input_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const double _pixelsPerHour = 60.0;
  static const int _startHour = 7;
  static const int _endHour = 23;
  static const double _timeColWidth = 44.0;

  static const _days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  DateTime _getWeekStart(DateTime date) {
    // Returns the Monday of the week containing [date]
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _pickWeekDate() async {
    final dateProv = context.read<SelectedDateProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateProv.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '선택한 날짜를 포함한 주\n(월요일부터 일요일)가 선택됩니다',
    );
    if (picked != null) {
      dateProv.selectDate(picked);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final weekStartDate =
        _getWeekStart(context.watch<SelectedDateProvider>().selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표 관리'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: '시간표'),
            Tab(icon: Icon(Icons.view_week), text: '이번주'),
            Tab(icon: Icon(Icons.list), text: '목록'),
          ],
        ),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final selectedChild =
              context.watch<ChildFilterProvider>().selectedChild;
          final schedules = selectedChild == null
              ? provider.activeSchedules
              : provider.schedulesForChild(selectedChild);

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimetable(schedules),
                    _buildWeeklyTimetable(schedules, weekStartDate),
                    _buildList(provider, schedules),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'schedule_fab',
        onPressed: () => _showAddDialog(context),
        tooltip: '시간표 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ────────────────── 겹침 레이아웃 계산 ──────────────────
  /// 같은 요일에서 시간이 겹치는 블록을 찾아 column/totalColumns를 할당
  List<_OverlapInfo> _computeOverlapLayout(List<Schedule> schedules) {
    final result = <_OverlapInfo>[];

    for (int day = 1; day <= 7; day++) {
      final dayList = schedules.where((s) => s.dayOfWeek == day).toList();
      if (dayList.isEmpty) continue;

      // 시작 시간순 정렬
      dayList.sort((a, b) {
        final cmp = (a.startHour * 60 + a.startMinute)
            .compareTo(b.startHour * 60 + b.startMinute);
        if (cmp != 0) return cmp;
        return b.durationMinutes.compareTo(a.durationMinutes);
      });

      // 겹치는 클러스터 묶기
      final clusters = <List<Schedule>>[];
      for (final s in dayList) {
        final sStart = s.startHour * 60 + s.startMinute;
        if (clusters.isNotEmpty) {
          final last = clusters.last;
          final clusterEnd = last
              .map((e) => e.endHour * 60 + e.endMinute)
              .reduce(max);
          if (sStart < clusterEnd) {
            last.add(s);
            continue;
          }
        }
        clusters.add([s]);
      }

      // 클러스터별 column 할당
      for (final cluster in clusters) {
        final columns = <List<Schedule>>[];
        for (final s in cluster) {
          final sStart = s.startHour * 60 + s.startMinute;
          int? col;
          for (int c = 0; c < columns.length; c++) {
            final lastEnd = columns[c].last.endHour * 60 +
                columns[c].last.endMinute;
            if (sStart >= lastEnd) {
              col = c;
              break;
            }
          }
          if (col != null) {
            columns[col].add(s);
          } else {
            columns.add([s]);
          }
        }
        final total = columns.length;
        for (int c = 0; c < columns.length; c++) {
          for (final s in columns[c]) {
            result.add(_OverlapInfo(s, c, total));
          }
        }
      }
    }
    return result;
  }

  // ────────────────── 공통 그리드 렌더링 ──────────────────
  Widget _buildGrid(List<Schedule> schedules) {
    final totalHeight = (_endHour - _startHour) * _pixelsPerHour;
    final layoutInfos = _computeOverlapLayout(schedules);

    return Expanded(
      child: SingleChildScrollView(
        child: SizedBox(
          height: totalHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시간 레이블
              SizedBox(
                width: _timeColWidth,
                child: Stack(
                  children: List.generate(_endHour - _startHour, (i) {
                    return Positioned(
                      top: i * _pixelsPerHour - 7,
                      right: 4,
                      child: Text(
                        '${_startHour + i}',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    );
                  }),
                ),
              ),
              // 그리드 + 블록
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final colWidth = constraints.maxWidth / 7;
                    return Stack(
                      children: [
                        // 시간 구분선
                        ...List.generate(
                            _endHour - _startHour,
                            (i) => Positioned(
                                  top: i * _pixelsPerHour,
                                  left: 0,
                                  right: 0,
                                  child: Divider(
                                      height: 0, color: Colors.grey[200]),
                                )),
                        // 요일 구분선
                        ...List.generate(
                            7,
                            (i) => Positioned(
                                  left: i * colWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: VerticalDivider(
                                      width: 0, color: Colors.grey[200]),
                                )),
                        // 시간표 블록 (겹침 레이아웃 적용)
                        ...layoutInfos.map((info) {
                          final s = info.schedule;
                          final top = (s.startHour - _startHour) *
                                  _pixelsPerHour +
                              s.startMinute * _pixelsPerHour / 60;
                          final height = max(
                              s.durationMinutes * _pixelsPerHour / 60,
                              18.0);
                          final dayLeft = (s.dayOfWeek - 1) * colWidth;
                          final slotWidth =
                              (colWidth - 2) / info.totalColumns;
                          final left =
                              dayLeft + 1 + info.column * slotWidth;
                          return Positioned(
                            top: top,
                            left: left,
                            width: slotWidth,
                            height: height,
                            child: _ScheduleBlock(
                              schedule: s,
                              blockHeight: height,
                              onTap: () => _showOptions(context, s),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── 시간표 뷰 ──────────────────
  Widget _buildTimetable(List<Schedule> schedules) {
    if (schedules.isEmpty) return _buildEmpty();

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: [
            SizedBox(width: _timeColWidth),
            ..._days.map((d) => Expanded(
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Text(d,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (d == '토')
                                ? Colors.blue
                                : (d == '일')
                                    ? Colors.red
                                    : null)),
                  ),
                )),
          ],
        ),
        _buildGrid(schedules),
      ],
    );
  }

  // ────────────────── 이번주 시간표 뷰 ──────────────────
  Widget _buildWeeklyTimetable(
      List<Schedule> schedules, DateTime weekStartDate) {
    if (schedules.isEmpty) return _buildEmpty();

    // Filter: exclude schedules cancelled on this week's date
    final filtered = schedules.where((s) {
      final date = weekStartDate.add(Duration(days: s.dayOfWeek - 1));
      return !s.isCancelledOn(date);
    }).toList();

    final weekEnd = weekStartDate.add(const Duration(days: 6));
    final dateFormat = DateFormat('M/d');
    final dateProv = context.read<SelectedDateProvider>();

    return Column(
      children: [
        // 주 탐색 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => dateProv.selectDate(
                    weekStartDate.subtract(const Duration(days: 7))),
                tooltip: '이전 주',
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickWeekDate,
                  child: Text(
                    '${dateFormat.format(weekStartDate)} ~ ${dateFormat.format(weekEnd)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, size: 20),
                onPressed: _pickWeekDate,
                tooltip: '날짜 선택',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => dateProv.selectDate(
                    weekStartDate.add(const Duration(days: 7))),
                tooltip: '다음 주',
              ),
            ],
          ),
        ),
        // 요일+날짜 헤더
        Row(
          children: [
            SizedBox(width: _timeColWidth),
            ...List.generate(7, (i) {
              final date = weekStartDate.add(Duration(days: i));
              final today = _isToday(date);
              return Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: today
                        ? Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1)
                        : null,
                    border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _days[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: today
                              ? Theme.of(context).primaryColor
                              : (i == 5)
                                  ? Colors.blue
                                  : (i == 6)
                                      ? Colors.red
                                      : null,
                        ),
                      ),
                      Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: today
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        _buildGrid(filtered),
      ],
    );
  }

  // ────────────────── 목록 뷰 ──────────────────
  Widget _buildList(ScheduleProvider provider, List<Schedule> schedules) {
    if (schedules.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 7,
      itemBuilder: (context, i) {
        final daySchedules = schedules
            .where((s) => s.dayOfWeek == i + 1)
            .toList()
          ..sort((a, b) => (a.startHour * 60 + a.startMinute)
              .compareTo(b.startHour * 60 + b.startMinute));

        if (daySchedules.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_days[i]}요일',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            ...daySchedules.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: s.color,
                      radius: 18,
                      child: Text(
                        s.subject.characters.first,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    title: Text('${s.subject} · ${s.childName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    subtitle: Text(
                        '${s.academyName}  ${s.timeRange}'
                        '${s.instructor.isNotEmpty ? '  ${s.instructor}' : ''}',
                        style: const TextStyle(fontSize: 12)),
                    onTap: () => _showOptions(context, s),
                  ),
                )),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('등록된 시간표가 없습니다',
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showAddDialog(context),
            child: const Text('시간표 추가하기'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ScheduleInputDialog(),
    );
  }

  void _showOptions(BuildContext context, Schedule schedule) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${schedule.subject} · ${schedule.childName}'),
        content: Text('${schedule.dayName}요일  ${schedule.timeRange}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) =>
                      ScheduleInputDialog(existingSchedule: schedule),
                );
              }
            },
            child: const Text('수정'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                await context
                    .read<ScheduleProvider>()
                    .deleteSchedule(schedule.id);
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ────────────────── 서브 위젯 ──────────────────

class _OverlapInfo {
  final Schedule schedule;
  final int column;
  final int totalColumns;
  const _OverlapInfo(this.schedule, this.column, this.totalColumns);
}

class _ScheduleBlock extends StatelessWidget {
  final Schedule schedule;
  final double blockHeight;
  final VoidCallback onTap;

  const _ScheduleBlock({
    required this.schedule,
    required this.blockHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: schedule.color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule.academyName.isNotEmpty && blockHeight >= 28)
              Text(
                schedule.academyName,
                style: const TextStyle(color: Colors.white70, fontSize: 7),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              schedule.subject,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (blockHeight >= 36)
              Text(
                schedule.timeRange,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (schedule.classType == '라이브' && blockHeight >= 48)
              Text(
                '라이브',
                style: const TextStyle(color: Colors.white70, fontSize: 7),
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}

