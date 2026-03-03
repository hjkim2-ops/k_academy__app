import 'package:flutter/foundation.dart';
import 'package:k_academy__app/services/dropdown_history_service.dart';
import 'package:k_academy__app/services/firestore_dropdown_service.dart';
import 'package:k_academy__app/utils/constants.dart';

class DropdownProvider with ChangeNotifier {
  final DropdownHistoryService _historyService = DropdownHistoryService();
  FirestoreDropdownService? _firestoreService;

  bool _isTrialMode = true;
  String? _userId;

  List<String> _childNames = [];
  List<String> _businessNames = [];
  List<String> _instructorNames = [];
  List<String> _customSubjects = [];
  List<String> _customDetails = [];
  List<String> _cardNames = [];
  List<String> _customPaymentMethods = [];

  List<String> _hiddenSubjects = [];
  List<String> _hiddenDetails = [];
  List<String> _hiddenPaymentMethods = [];
  List<String> _childNameOrder = [];

  List<String> get childNames {
    final names = _childNames.toSet().toList();
    if (_childNameOrder.isNotEmpty) {
      names.sort((a, b) {
        final ia = _childNameOrder.indexOf(a);
        final ib = _childNameOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return 1;
        return ia.compareTo(ib);
      });
    }
    return names;
  }

  List<String> get businessNames => _businessNames.toSet().toList();
  List<String> get instructorNames => _instructorNames.toSet().toList();
  List<String> get cardNames => _cardNames.toSet().toList();

  List<String> get allSubjects {
    final hidden = _hiddenSubjects.toSet();
    return [...defaultSubjects, ..._customSubjects]
        .toSet()
        .where((s) => !hidden.contains(s))
        .toList();
  }

  List<String> get allDetails {
    final hidden = _hiddenDetails.toSet();
    return [...defaultDetails, ..._customDetails]
        .toSet()
        .where((d) => !hidden.contains(d))
        .toList();
  }

  List<String> get allPaymentMethods {
    final hidden = _hiddenPaymentMethods.toSet();
    return [...paymentMethods, ..._customPaymentMethods]
        .toSet()
        .where((m) => !hidden.contains(m))
        .toList();
  }

  /// 인증 모드 변경 시 호출됨 (main.dart ProxyProvider에서 자동 호출)
  void onAuthChanged(bool isTrialMode, String? userId) {
    final modeChanged = _isTrialMode != isTrialMode || _userId != userId;
    if (!modeChanged) return;

    _isTrialMode = isTrialMode;
    _userId = userId;
    _firestoreService = (!isTrialMode && userId != null)
        ? FirestoreDropdownService(userId: userId)
        : null;

    Future.microtask(() => loadAllDropdownData());
  }

  /// 저장소에서 전체 드롭다운 데이터 로드 (로컬 + 클라우드 병합)
  Future<void> loadAllDropdownData() async {
    // 1. 로컬(Hive)에서 로드
    _childNames = _historyService.getChildNames();
    _businessNames = _historyService.getBusinessNames();
    _instructorNames = _historyService.getInstructorNames();
    _customSubjects = _historyService.getCustomSubjects();
    _customDetails = _historyService.getCustomDetails();
    _cardNames = _historyService.getCardNames();
    _customPaymentMethods = _historyService.getCustomPaymentMethods();
    _hiddenSubjects = _historyService.getHiddenSubjects();
    _hiddenDetails = _historyService.getHiddenDetails();
    _hiddenPaymentMethods = _historyService.getHiddenPaymentMethods();
    _childNameOrder = _historyService.getChildNameOrder();

    // 2. 로그인 상태면 클라우드에서 로드 후 병합
    if (_firestoreService != null) {
      try {
        final cloudData = await _firestoreService!.getAllDropdownData();
        _mergeCloudData(cloudData);
        await _syncToLocal();
        await _syncToCloud();
      } catch (e) {
        debugPrint('클라우드 드롭다운 동기화 실패: $e');
      }
    }

    notifyListeners();
  }

  /// 클라우드 데이터와 로컬 데이터 병합 (합집합)
  void _mergeCloudData(Map<String, List<String>> cloudData) {
    _childNames = {..._childNames, ...cloudData['childNames'] ?? []}.toList();
    _businessNames = {..._businessNames, ...cloudData['businessNames'] ?? []}.toList();
    _instructorNames = {..._instructorNames, ...cloudData['instructorNames'] ?? []}.toList();
    _customSubjects = {..._customSubjects, ...cloudData['customSubjects'] ?? []}.toList();
    _customDetails = {..._customDetails, ...cloudData['customDetails'] ?? []}.toList();
    _cardNames = {..._cardNames, ...cloudData['cardNames'] ?? []}.toList();
    _customPaymentMethods = {..._customPaymentMethods, ...cloudData['customPaymentMethods'] ?? []}.toList();
    _hiddenSubjects = {..._hiddenSubjects, ...cloudData['hiddenSubjects'] ?? []}.toList();
    _hiddenDetails = {..._hiddenDetails, ...cloudData['hiddenDetails'] ?? []}.toList();
    _hiddenPaymentMethods = {..._hiddenPaymentMethods, ...cloudData['hiddenPaymentMethods'] ?? []}.toList();
    // childNameOrder: cloud wins if local is empty
    final cloudOrder = cloudData['childNameOrder'] ?? [];
    if (_childNameOrder.isEmpty && cloudOrder.isNotEmpty) {
      _childNameOrder = cloudOrder;
    }
  }

  /// 병합된 데이터를 로컬(Hive)에 저장
  Future<void> _syncToLocal() async {
    for (final name in _childNames) {
      await _historyService.addChildName(name);
    }
    for (final name in _businessNames) {
      await _historyService.addBusinessName(name);
    }
    for (final name in _instructorNames) {
      await _historyService.addInstructorName(name);
    }
    for (final subject in _customSubjects) {
      await _historyService.addCustomSubject(subject);
    }
    for (final detail in _customDetails) {
      await _historyService.addCustomDetail(detail);
    }
    for (final name in _cardNames) {
      await _historyService.addCardName(name);
    }
    for (final method in _customPaymentMethods) {
      await _historyService.addCustomPaymentMethod(method);
    }
    for (final s in _hiddenSubjects) {
      await _historyService.addHiddenSubject(s);
    }
    for (final d in _hiddenDetails) {
      await _historyService.addHiddenDetail(d);
    }
    for (final m in _hiddenPaymentMethods) {
      await _historyService.addHiddenPaymentMethod(m);
    }
    if (_childNameOrder.isNotEmpty) {
      await _historyService.saveChildNameOrder(_childNameOrder);
    }
  }

  /// 병합된 데이터를 클라우드(Firestore)에 저장
  Future<void> _syncToCloud() async {
    if (_firestoreService == null) return;
    await _firestoreService!.saveAllDropdownData(
      childNames: _childNames,
      businessNames: _businessNames,
      instructorNames: _instructorNames,
      customSubjects: _customSubjects,
      customDetails: _customDetails,
      cardNames: _cardNames,
      customPaymentMethods: _customPaymentMethods,
      hiddenSubjects: _hiddenSubjects,
      hiddenDetails: _hiddenDetails,
      hiddenPaymentMethods: _hiddenPaymentMethods,
      childNameOrder: _childNameOrder,
    );
  }

  // --- 개별 항목 추가 (로컬 + 클라우드 동시 저장) ---

  Future<void> addChildName(String name) async {
    if (name.trim().isEmpty || _childNames.contains(name)) return;
    await _historyService.addChildName(name);
    _childNames = _historyService.getChildNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addBusinessName(String name) async {
    if (name.trim().isEmpty || _businessNames.contains(name)) return;
    await _historyService.addBusinessName(name);
    _businessNames = _historyService.getBusinessNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addInstructorName(String name) async {
    if (name.trim().isEmpty || _instructorNames.contains(name)) return;
    await _historyService.addInstructorName(name);
    _instructorNames = _historyService.getInstructorNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addCustomSubject(String subject) async {
    if (subject.trim().isEmpty ||
        defaultSubjects.contains(subject) ||
        _customSubjects.contains(subject)) {
      return;
    }
    await _historyService.addCustomSubject(subject);
    _customSubjects = _historyService.getCustomSubjects();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addCustomDetail(String detail) async {
    if (detail.trim().isEmpty ||
        defaultDetails.contains(detail) ||
        _customDetails.contains(detail)) {
      return;
    }
    await _historyService.addCustomDetail(detail);
    _customDetails = _historyService.getCustomDetails();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addCardName(String name) async {
    if (name.trim().isEmpty || _cardNames.contains(name)) return;
    await _historyService.addCardName(name);
    _cardNames = _historyService.getCardNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> addCustomPaymentMethod(String method) async {
    if (method.trim().isEmpty ||
        paymentMethods.contains(method) ||
        _customPaymentMethods.contains(method)) {
      return;
    }
    await _historyService.addCustomPaymentMethod(method);
    _customPaymentMethods = _historyService.getCustomPaymentMethods();
    await _syncToCloud();
    notifyListeners();
  }

  // --- 항목 삭제 ---

  Future<void> removeChildName(String name) async {
    await _historyService.removeChildName(name);
    _childNames = _historyService.getChildNames();
    _childNameOrder.remove(name);
    await _historyService.saveChildNameOrder(_childNameOrder);
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removeBusinessName(String name) async {
    await _historyService.removeBusinessName(name);
    _businessNames = _historyService.getBusinessNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removeInstructorName(String name) async {
    await _historyService.removeInstructorName(name);
    _instructorNames = _historyService.getInstructorNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removeSubject(String subject) async {
    if (defaultSubjects.contains(subject)) {
      // 기본항목은 숨김 처리
      _hiddenSubjects.add(subject);
      await _historyService.addHiddenSubject(subject);
    } else {
      // 커스텀항목은 삭제
      await _historyService.removeCustomSubject(subject);
      _customSubjects = _historyService.getCustomSubjects();
    }
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removeDetail(String detail) async {
    if (defaultDetails.contains(detail)) {
      _hiddenDetails.add(detail);
      await _historyService.addHiddenDetail(detail);
    } else {
      await _historyService.removeCustomDetail(detail);
      _customDetails = _historyService.getCustomDetails();
    }
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removeCardName(String name) async {
    await _historyService.removeCardName(name);
    _cardNames = _historyService.getCardNames();
    await _syncToCloud();
    notifyListeners();
  }

  Future<void> removePaymentMethod(String method) async {
    if (paymentMethods.contains(method)) {
      _hiddenPaymentMethods.add(method);
      await _historyService.addHiddenPaymentMethod(method);
    } else {
      await _historyService.removeCustomPaymentMethod(method);
      _customPaymentMethods = _historyService.getCustomPaymentMethods();
    }
    await _syncToCloud();
    notifyListeners();
  }

  // --- 자녀 순서 변경 ---

  Future<void> reorderChildNames(int oldIndex, int newIndex) async {
    final list = childNames; // already ordered
    if (oldIndex < newIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _childNameOrder = list;
    await _historyService.saveChildNameOrder(_childNameOrder);
    await _syncToCloud();
    notifyListeners();
  }

  /// 현재 존재하는 자녀 목록과 순서를 동기화 (새 자녀 추가 시 순서에 반영)
  void syncChildNameOrder(List<String> currentChildren) {
    final ordered = <String>[];
    for (final name in _childNameOrder) {
      if (currentChildren.contains(name)) {
        ordered.add(name);
      }
    }
    for (final name in currentChildren) {
      if (!ordered.contains(name)) {
        ordered.add(name);
      }
    }
    _childNameOrder = ordered;
  }
}
