import 'package:hive/hive.dart';
import 'package:k_academy__app/models/schedule.dart';
import 'package:k_academy__app/services/storage_service.dart';

class ScheduleService {
  Box<Schedule> get _box => StorageService.scheduleBox;

  List<Schedule> getAllSchedules() => _box.values.toList();

  Future<void> addSchedule(Schedule schedule) async {
    await _box.put(schedule.id, schedule);
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _box.put(schedule.id, schedule);
  }

  Future<void> deleteSchedule(String id) async {
    await _box.delete(id);
  }
}
