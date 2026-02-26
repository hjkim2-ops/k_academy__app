import 'package:flutter/foundation.dart';
import 'package:k_academy__app/models/schedule.dart';
import 'package:k_academy__app/services/schedule_service.dart';
import 'package:k_academy__app/services/firestore_schedule_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _hiveService = ScheduleService();
  FirestoreScheduleService? _firestoreService;

  List<Schedule> _schedules = [];
  bool _isTrialMode = true;
  String? _userId;

  List<Schedule> get schedules => _schedules;
  List<Schedule> get activeSchedules =>
      _schedules.where((s) => s.isActive).toList();

  List<Schedule> schedulesForDay(int dayOfWeek) => activeSchedules
      .where((s) => s.dayOfWeek == dayOfWeek)
      .toList()
    ..sort((a, b) => (a.startHour * 60 + a.startMinute)
        .compareTo(b.startHour * 60 + b.startMinute));

  List<Schedule> schedulesForChild(String childName) =>
      activeSchedules.where((s) => s.childName == childName).toList();

  List<String> get childNames =>
      _schedules.map((s) => s.childName).toSet().toList();

  void onAuthChanged(bool isTrialMode, String? userId) {
    final modeChanged = _isTrialMode != isTrialMode || _userId != userId;
    if (!modeChanged) return;
    _isTrialMode = isTrialMode;
    _userId = userId;
    _firestoreService = (!isTrialMode && userId != null)
        ? FirestoreScheduleService(userId: userId)
        : null;
    Future.microtask(() => loadSchedules());
  }

  Future<void> loadSchedules() async {
    if (_firestoreService != null) {
      _schedules = await _firestoreService!.getAllSchedules();
    } else {
      _schedules = _hiveService.getAllSchedules();
    }
    notifyListeners();
  }

  Future<void> addSchedule(Schedule schedule) async {
    if (_firestoreService != null) {
      await _firestoreService!.addSchedule(schedule);
    } else {
      await _hiveService.addSchedule(schedule);
    }
    _schedules.add(schedule);
    notifyListeners();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    if (_firestoreService != null) {
      await _firestoreService!.updateSchedule(schedule);
    } else {
      await _hiveService.updateSchedule(schedule);
    }
    final idx = _schedules.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) _schedules[idx] = schedule;
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    if (_firestoreService != null) {
      await _firestoreService!.deleteSchedule(id);
    } else {
      await _hiveService.deleteSchedule(id);
    }
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
