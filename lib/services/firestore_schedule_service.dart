import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:k_academy__app/models/schedule.dart';

class FirestoreScheduleService {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreScheduleService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(userId).collection('schedules');

  Future<List<Schedule>> getAllSchedules() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Schedule.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _collection.doc(schedule.id).set(schedule.toMap());
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _collection.doc(schedule.id).update(schedule.toMap());
  }

  Future<void> deleteSchedule(String id) async {
    await _collection.doc(id).delete();
  }
}
