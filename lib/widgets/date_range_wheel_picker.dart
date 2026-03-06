import 'package:flutter/material.dart';

class DateRangeWheelPicker extends StatefulWidget {
  final DateTimeRange initialRange;
  const DateRangeWheelPicker({super.key, required this.initialRange});

  @override
  State<DateRangeWheelPicker> createState() => _DateRangeWheelPickerState();
}

class _DateRangeWheelPickerState extends State<DateRangeWheelPicker> {
  static const _minYear = 2000;
  static const _maxYear = 2100;
  static const _yearCount = _maxYear - _minYear + 1;

  late int _startYear, _startMonth, _startDay;
  late int _endYear, _endMonth, _endDay;

  late FixedExtentScrollController _startYearCtrl;
  late FixedExtentScrollController _startMonthCtrl;
  late FixedExtentScrollController _startDayCtrl;
  late FixedExtentScrollController _endYearCtrl;
  late FixedExtentScrollController _endMonthCtrl;
  late FixedExtentScrollController _endDayCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.initialRange.start;
    final e = widget.initialRange.end;
    _startYear = s.year;
    _startMonth = s.month;
    _startDay = s.day;
    _endYear = e.year;
    _endMonth = e.month;
    _endDay = e.day;

    _startYearCtrl = FixedExtentScrollController(initialItem: _startYear - _minYear);
    _startMonthCtrl = FixedExtentScrollController(initialItem: _startMonth - 1);
    _startDayCtrl = FixedExtentScrollController(initialItem: _startDay - 1);
    _endYearCtrl = FixedExtentScrollController(initialItem: _endYear - _minYear);
    _endMonthCtrl = FixedExtentScrollController(initialItem: _endMonth - 1);
    _endDayCtrl = FixedExtentScrollController(initialItem: _endDay - 1);
  }

  @override
  void dispose() {
    _startYearCtrl.dispose();
    _startMonthCtrl.dispose();
    _startDayCtrl.dispose();
    _endYearCtrl.dispose();
    _endMonthCtrl.dispose();
    _endDayCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  void _clampStartDay() {
    final maxDay = _daysInMonth(_startYear, _startMonth);
    if (_startDay > maxDay) {
      _startDay = maxDay;
      _startDayCtrl.jumpToItem(_startDay - 1);
    }
  }

  void _clampEndDay() {
    final maxDay = _daysInMonth(_endYear, _endMonth);
    if (_endDay > maxDay) {
      _endDay = maxDay;
      _endDayCtrl.jumpToItem(_endDay - 1);
    }
  }

  void _enforceStartBeforeEnd() {
    final start = DateTime(_startYear, _startMonth, _startDay);
    final end = DateTime(_endYear, _endMonth, _endDay);
    if (start.isAfter(end)) {
      _endYear = _startYear;
      _endMonth = _startMonth;
      _endDay = _startDay;
      _endYearCtrl.jumpToItem(_endYear - _minYear);
      _endMonthCtrl.jumpToItem(_endMonth - 1);
      _endDayCtrl.jumpToItem(_endDay - 1);
    }
  }

  void _enforceEndAfterStart() {
    final start = DateTime(_startYear, _startMonth, _startDay);
    final end = DateTime(_endYear, _endMonth, _endDay);
    if (end.isBefore(start)) {
      _startYear = _endYear;
      _startMonth = _endMonth;
      _startDay = _endDay;
      _startYearCtrl.jumpToItem(_startYear - _minYear);
      _startMonthCtrl.jumpToItem(_startMonth - 1);
      _startDayCtrl.jumpToItem(_startDay - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '기간 설정',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          // Start date
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '시작일',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _wheel(
                      controller: _startYearCtrl,
                      count: _yearCount,
                      selected: _startYear - _minYear,
                      label: (i) => '${_minYear + i}년',
                      onChanged: (i) => setState(() {
                        _startYear = _minYear + i;
                        _clampStartDay();
                        _enforceStartBeforeEnd();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _wheel(
                      controller: _startMonthCtrl,
                      count: 12,
                      selected: _startMonth - 1,
                      label: (i) => '${i + 1}월',
                      onChanged: (i) => setState(() {
                        _startMonth = i + 1;
                        _clampStartDay();
                        _enforceStartBeforeEnd();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _wheel(
                      controller: _startDayCtrl,
                      count: _daysInMonth(_startYear, _startMonth),
                      selected: _startDay - 1,
                      label: (i) => '${i + 1}일',
                      onChanged: (i) => setState(() {
                        _startDay = i + 1;
                        _enforceStartBeforeEnd();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),

          // End date
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '종료일',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _wheel(
                      controller: _endYearCtrl,
                      count: _yearCount,
                      selected: _endYear - _minYear,
                      label: (i) => '${_minYear + i}년',
                      onChanged: (i) => setState(() {
                        _endYear = _minYear + i;
                        _clampEndDay();
                        _enforceEndAfterStart();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _wheel(
                      controller: _endMonthCtrl,
                      count: 12,
                      selected: _endMonth - 1,
                      label: (i) => '${i + 1}월',
                      onChanged: (i) => setState(() {
                        _endMonth = i + 1;
                        _clampEndDay();
                        _enforceEndAfterStart();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _wheel(
                      controller: _endDayCtrl,
                      count: _daysInMonth(_endYear, _endMonth),
                      selected: _endDay - 1,
                      label: (i) => '${i + 1}일',
                      onChanged: (i) => setState(() {
                        _endDay = i + 1;
                        _enforceEndAfterStart();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(
                      DateTimeRange(
                        start: DateTime(_startYear, _startMonth, _startDay),
                        end: DateTime(_endYear, _endMonth, _endDay),
                      ),
                    );
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 38,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final isSel = index == selected;
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: isSel
                  ? BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Text(
                label(index),
                style: TextStyle(
                  fontSize: isSel ? 16 : 14,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
