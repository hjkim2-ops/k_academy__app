import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:k_academy__app/models/schedule.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';
import 'package:k_academy__app/utils/constants.dart';
import 'package:k_academy__app/widgets/custom_dropdown_field.dart';

class ScheduleInputDialog extends StatefulWidget {
  final Schedule? existingSchedule;

  const ScheduleInputDialog({super.key, this.existingSchedule});

  @override
  State<ScheduleInputDialog> createState() => _ScheduleInputDialogState();
}

class _ScheduleInputDialogState extends State<ScheduleInputDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _childName;
  String? _academyName;
  String? _subject;
  String? _instructor;
  String _classType = classTypes[0]; // Default: 현강
  final Set<int> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _colorValue = 0xFF2196F3;
  String _memo = '';
  Set<String> _cancelledDates = {};
  List<String> _timetableLabels = ['학원', '과목', '강사', '수업 시간'];

  bool get _isEditing => widget.existingSchedule != null;

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    final s = widget.existingSchedule;
    if (s != null) {
      _childName = s.childName;
      _academyName = s.academyName;
      _subject = s.subject;
      _instructor = s.instructor.isEmpty ? null : s.instructor;
      _classType = s.classType;
      _selectedDays.add(s.dayOfWeek);
      _startTime = s.startTime;
      _endTime = s.endTime;
      _colorValue = s.colorValue;
      _memo = s.memo ?? '';
      _cancelledDates = s.cancelledDates.toSet();
      _timetableLabels = List<String>.from(s.timetableLabels);
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => _ScrollTimePicker(initial: initial),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showCancelledDatesCalendar() {
    final selectedDays = Set<int>.from(_selectedDays);
    var tempCancelled = Set<String>.from(_cancelledDates);
    final now = DateTime.now();
    var focusedDay = now;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('휴강 날짜 선택', style: TextStyle(fontSize: 16)),
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            content: SizedBox(
              width: 360,
              height: 400,
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime(now.year, now.month - 3, 1),
                lastDay: DateTime(now.year + 1, 12, 31),
                focusedDay: focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                onPageChanged: (day) {
                  setDialogState(() => focusedDay = day);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dateStr =
                        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final isSelectedDay = selectedDays.contains(day.weekday);
                    final isCancelled = tempCancelled.contains(dateStr);

                    if (!isSelectedDay) return null; // default rendering

                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (isCancelled) {
                            tempCancelled.remove(dateStr);
                          } else {
                            tempCancelled.add(dateStr);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? Colors.red.withValues(alpha: 0.15)
                              : Color(_colorValue).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCancelled
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text('${day.day}',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                    const Icon(Icons.close,
                                        color: Colors.red, size: 14),
                                  ],
                                )
                              : Text('${day.day}',
                                  style: TextStyle(
                                      color: Color(_colorValue),
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dateStr =
                        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final isSelectedDay = selectedDays.contains(day.weekday);
                    final isCancelled = tempCancelled.contains(dateStr);

                    if (!isSelectedDay) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${day.day}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (isCancelled) {
                            tempCancelled.remove(dateStr);
                          } else {
                            tempCancelled.add(dateStr);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? Colors.red.withValues(alpha: 0.15)
                              : Color(_colorValue).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.blue, width: 1.5),
                        ),
                        child: Center(
                          child: isCancelled
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text('${day.day}',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                    const Icon(Icons.close,
                                        color: Colors.red, size: 14),
                                  ],
                                )
                              : Text('${day.day}',
                                  style: TextStyle(
                                      color: Color(_colorValue),
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focused) {
                  if (!selectedDays.contains(selectedDay.weekday)) return;
                  final dateStr =
                      '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                  setDialogState(() {
                    if (tempCancelled.contains(dateStr)) {
                      tempCancelled.remove(dateStr);
                    } else {
                      tempCancelled.add(dateStr);
                    }
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _cancelledDates = tempCancelled);
                  Navigator.of(ctx).pop();
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요일을 하나 이상 선택해주세요')),
      );
      return;
    }
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간이 시작 시간보다 늦어야 합니다')),
      );
      return;
    }

    // 드롭다운 항목 저장
    final dropdownProvider = context.read<DropdownProvider>();
    if (_childName != null) await dropdownProvider.addChildName(_childName!);
    if (_instructor != null && _instructor!.isNotEmpty) {
      await dropdownProvider.addInstructorName(_instructor!);
    }
    if (_academyName != null && _academyName!.isNotEmpty) {
      await dropdownProvider.addBusinessName(_academyName!);
    }
    if (_subject != null) await dropdownProvider.addCustomSubject(_subject!);

    final provider = context.read<ScheduleProvider>();

    if (_isEditing) {
      final updated = widget.existingSchedule!.copyWith(
        childName: _childName,
        academyName: _academyName,
        subject: _subject,
        instructor: _instructor ?? '',
        classType: _classType,
        dayOfWeek: _selectedDays.first,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        colorValue: _colorValue,
        memo: _memo.isEmpty ? null : _memo,
        cancelledDates: _cancelledDates.toList(),
        timetableLabels: _timetableLabels,
      );
      provider.updateSchedule(updated);
    } else {
      for (final day in _selectedDays) {
        // Filter cancelledDates to only those matching this dayOfWeek
        final dayCancelled = _cancelledDates.where((dateStr) {
          final parsed = DateTime.tryParse(dateStr);
          return parsed != null && parsed.weekday == day;
        }).toList();
        provider.addSchedule(Schedule(
          id: const Uuid().v4(),
          childName: _childName!,
          academyName: _academyName ?? '',
          subject: _subject!,
          instructor: _instructor ?? '',
          classType: _classType,
          dayOfWeek: day,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          endHour: _endTime.hour,
          endMinute: _endTime.minute,
          colorValue: _colorValue,
          isActive: true,
          memo: _memo.isEmpty ? null : _memo,
          cancelledDates: dayCancelled,
          timetableLabels: _timetableLabels,
        ));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dropdownProvider = context.watch<DropdownProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
              child: Row(
                children: [
                  Text(
                    _isEditing ? '시간표 수정' : '시간표 입력',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 폼
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 자녀
                      CustomDropdownField(
                        label: '자녀',
                        value: _childName,
                        options: dropdownProvider.childNames,
                        onChanged: (v) => setState(() => _childName = v),
                        onValueAdded: (v) {
                          dropdownProvider.addChildName(v);
                          setState(() => _childName = v);
                        },
                        onItemDeleted: (v) {
                          dropdownProvider.removeChildName(v);
                          if (_childName == v) {
                            setState(() => _childName = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 학원명
                      CustomDropdownField(
                        label: '학원',
                        value: _academyName,
                        options: dropdownProvider.businessNames,
                        required: true,
                        onChanged: (v) => setState(() => _academyName = v),
                        onValueAdded: (v) {
                          dropdownProvider.addBusinessName(v);
                          setState(() => _academyName = v);
                        },
                        onItemDeleted: (v) {
                          dropdownProvider.removeBusinessName(v);
                          if (_academyName == v) {
                            setState(() => _academyName = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 과목
                      CustomDropdownField(
                        label: '과목',
                        value: _subject,
                        options: dropdownProvider.allSubjects,
                        onChanged: (v) => setState(() => _subject = v),
                        onValueAdded: (v) {
                          dropdownProvider.addCustomSubject(v);
                          setState(() => _subject = v);
                        },
                        onItemDeleted: (v) {
                          dropdownProvider.removeSubject(v);
                          if (_subject == v) {
                            setState(() => _subject = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 강사
                      CustomDropdownField(
                        label: '강사',
                        value: _instructor,
                        options: dropdownProvider.instructorNames,
                        required: false,
                        onChanged: (v) => setState(() => _instructor = v),
                        onValueAdded: (v) {
                          dropdownProvider.addInstructorName(v);
                          setState(() => _instructor = v);
                        },
                        onItemDeleted: (v) {
                          dropdownProvider.removeInstructorName(v);
                          if (_instructor == v) {
                            setState(() => _instructor = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 수업 형태
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '수업 형태 *',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: classTypes.map((type) {
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _classType = type;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: type,
                                        groupValue: _classType,
                                        onChanged: (value) {
                                          setState(() {
                                            _classType = value!;
                                          });
                                        },
                                      ),
                                      Text(type),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 요일
                      const Text('요일 *',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final selected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(_dayNames[i]),
                            selected: selected,
                            showCheckmark: false,
                            side: BorderSide.none,
                            backgroundColor: Colors.grey[200],
                            onSelected: _isEditing
                                ? null
                                : (v) => setState(() {
                                      if (v) {
                                        _selectedDays.add(day);
                                      } else {
                                        _selectedDays.remove(day);
                                      }
                                    }),
                            selectedColor:
                                Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // 시간
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('시작 시간 *',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                _TimeButton(
                                  time: _fmtTime(_startTime),
                                  onTap: () => _pickTime(true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('종료 시간 *',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                _TimeButton(
                                  time: _fmtTime(_endTime),
                                  onTap: () => _pickTime(false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 색상
                      const Text('색상',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: scheduleColorValues.map((cv) {
                          final selected = _colorValue == cv;
                          return GestureDetector(
                            onTap: () => setState(() => _colorValue = cv),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(cv),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: Colors.black87, width: 2.5)
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 휴강 날짜
                      Row(
                        children: [
                          const Text('휴강 날짜',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_month, size: 20),
                            onPressed: _selectedDays.isEmpty
                                ? null
                                : _showCancelledDatesCalendar,
                            tooltip: '휴강 날짜 선택',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Spacer(),
                          if (_cancelledDates.isNotEmpty)
                            Text(
                              '${_cancelledDates.length}일 선택됨',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red[400]),
                            ),
                        ],
                      ),
                      if (_selectedDays.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '요일을 먼저 선택하세요',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // 메모
                      _buildTextField(
                        label: '메모',
                        initialValue: _memo,
                        hint: '메모 입력 (선택사항)',
                        onChanged: (v) => _memo = v,
                      ),
                      const SizedBox(height: 16),

                      // 시간표에 표시할 항목
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '시간표에 표시할 항목',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          for (final row in [['학원', '과목'], ['강사', '수업 시간'], ['수업 형태']])
                            Row(
                              children: [
                                ...row.map((label) {
                                  final isSelected = _timetableLabels.contains(label);
                                  return Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _timetableLabels.remove(label);
                                          } else {
                                            _timetableLabels.add(label);
                                          }
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          IgnorePointer(
                                            child: Radio<bool>(
                                              value: true,
                                              groupValue: isSelected,
                                              onChanged: (_) {},
                                            ),
                                          ),
                                          Text(label),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                if (row.length < 2) const Expanded(child: SizedBox()),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isEditing ? '수정' : '저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? initialValue,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(time,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ScrollTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  const _ScrollTimePicker({required this.initial});

  @override
  State<_ScrollTimePicker> createState() => _ScrollTimePickerState();
}

class _ScrollTimePickerState extends State<_ScrollTimePicker> {
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      content: SizedBox(
        height: 180,
        child: Row(
          children: [
            // 시
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _hourCtrl,
                itemExtent: 38,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _hour = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (context, index) {
                    final selected = index == _hour;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: selected
                            ? BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Text(
                          '$index시',
                          style: TextStyle(
                            fontSize: selected ? 16 : 14,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
            // 분
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _minuteCtrl,
                itemExtent: 38,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _minute = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 60,
                  builder: (context, index) {
                    final selected = index == _minute;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: selected
                            ? BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Text(
                          '${index.toString().padLeft(2, '0')}분',
                          style: TextStyle(
                            fontSize: selected ? 16 : 14,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            TimeOfDay(hour: _hour, minute: _minute),
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
