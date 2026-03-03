import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore를 사용한 드롭다운 히스토리 동기화 서비스
/// 데이터 경로: users/{userId}/settings/dropdownHistory
class FirestoreDropdownService {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreDropdownService({required this.userId});

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(userId).collection('settings').doc('dropdownHistory');

  /// 클라우드에서 전체 드롭다운 데이터 로드
  Future<Map<String, List<String>>> getAllDropdownData() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return {};
    final data = snapshot.data()!;
    return {
      'childNames': List<String>.from(data['childNames'] ?? []),
      'businessNames': List<String>.from(data['businessNames'] ?? []),
      'instructorNames': List<String>.from(data['instructorNames'] ?? []),
      'customSubjects': List<String>.from(data['customSubjects'] ?? []),
      'customDetails': List<String>.from(data['customDetails'] ?? []),
      'cardNames': List<String>.from(data['cardNames'] ?? []),
      'customPaymentMethods': List<String>.from(data['customPaymentMethods'] ?? []),
      'hiddenSubjects': List<String>.from(data['hiddenSubjects'] ?? []),
      'hiddenDetails': List<String>.from(data['hiddenDetails'] ?? []),
      'hiddenPaymentMethods': List<String>.from(data['hiddenPaymentMethods'] ?? []),
      'childNameOrder': List<String>.from(data['childNameOrder'] ?? []),
    };
  }

  /// 클라우드에 전체 드롭다운 데이터 저장
  Future<void> saveAllDropdownData({
    required List<String> childNames,
    required List<String> businessNames,
    required List<String> instructorNames,
    required List<String> customSubjects,
    required List<String> customDetails,
    required List<String> cardNames,
    required List<String> customPaymentMethods,
    required List<String> hiddenSubjects,
    required List<String> hiddenDetails,
    required List<String> hiddenPaymentMethods,
    required List<String> childNameOrder,
  }) async {
    await _doc.set({
      'childNames': childNames,
      'businessNames': businessNames,
      'instructorNames': instructorNames,
      'customSubjects': customSubjects,
      'customDetails': customDetails,
      'cardNames': cardNames,
      'customPaymentMethods': customPaymentMethods,
      'hiddenSubjects': hiddenSubjects,
      'hiddenDetails': hiddenDetails,
      'hiddenPaymentMethods': hiddenPaymentMethods,
      'childNameOrder': childNameOrder,
    });
  }
}
