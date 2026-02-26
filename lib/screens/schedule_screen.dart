import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/models/schedule.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';
import 'package:k_academy__app/screens/home_screen.dart';
import 'package:k_academy__app/widgets/schedule_input_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChild; // null = 전체

  static const double _pixelsPerHour = 60.0;
  static const int _startHour = 7;
  static const int _endHour = 23;
  static const double _timeColWidth = 44.0;

  static const _days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표 관리'),
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
            Tab(icon: Icon(Icons.list), text: '목록'),
          ],
        ),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final children = provider.childNames;
          final schedules = _selectedChild == null
              ? provider.activeSchedules
              : provider.schedulesForChild(_selectedChild!);

          return Column(
            children: [
              // 자녀 필터
              if (children.isNotEmpty)
                _buildChildFilter(children),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimetable(schedules),
                    _buildList(provider, schedules),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: '시간표 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChildFilter(List<String> children) {
    return Container(
      height: 44,
      color: Colors.grey[100],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _FilterChip(
            label: '전체',
            selected: _selectedChild == null,
            onTap: () => setState(() => _selectedChild = null),
          ),
          ...children.map((c) => _FilterChip(
                label: c,
                selected: _selectedChild == c,
                onTap: () => setState(() => _selectedChild = c),
              )),
        ],
      ),
    );
  }

  // ────────────────── 시간표 뷰 ──────────────────
  Widget _buildTimetable(List<Schedule> schedules) {
    if (schedules.isEmpty) return _buildEmpty();

    final totalHeight = (_endHour - _startHour) * _pixelsPerHour;

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
        // 스크롤 영역
        Expanded(
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
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
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
                            ...List.generate(_endHour - _startHour, (i) =>
                              Positioned(
                                top: i * _pixelsPerHour,
                                left: 0,
                                right: 0,
                                child: Divider(
                                    height: 0,
                                    color: Colors.grey[200]),
                              )),
                            // 요일 구분선
                            ...List.generate(7, (i) =>
                              Positioned(
                                left: i * colWidth,
                                top: 0,
                                bottom: 0,
                                child: VerticalDivider(
                                    width: 0,
                                    color: Colors.grey[200]),
                              )),
                            // 시간표 블록
                            ...schedules.map((s) {
                              final top = (s.startHour - _startHour) *
                                      _pixelsPerHour +
                                  s.startMinute * _pixelsPerHour / 60;
                              final height = max(
                                  s.durationMinutes * _pixelsPerHour / 60,
                                  18.0);
                              final left = (s.dayOfWeek - 1) * colWidth + 1;
                              return Positioned(
                                top: top,
                                left: left,
                                width: colWidth - 2,
                                height: height,
                                child: _ScheduleBlock(
                                  schedule: s,
                                  blockHeight: height,
                                  onTap: () =>
                                      _showOptions(context, s),
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
        ),
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
        title: Text('${schedule.subject} · ${schedule.dayName}요일'),
        content: Text(schedule.timeRange),
        actions: [
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
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Colors.black87,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
