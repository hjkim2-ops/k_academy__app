import 'package:flutter/foundation.dart';
import 'package:k_academy__app/services/dropdown_history_service.dart';
import 'package:k_academy__app/utils/constants.dart';

class DropdownProvider with ChangeNotifier {
  final DropdownHistoryService _historyService = DropdownHistoryService();

  List<String> _childNames = [];
  List<String> _businessNames = [];
  List<String> _instructorNames = [];
  List<String> _customSubjects = [];
  List<String> _customDetails = [];
  List<String> _cardNames = [];
  List<String> _customPaymentMethods = [];

  List<String> get childNames => _childNames.toSet().toList();
  List<String> get businessNames => _businessNames.toSet().toList();
  List<String> get instructorNames => _instructorNames.toSet().toList();
  List<String> get cardNames => _cardNames.toSet().toList();

  // Get all subjects (default + custom)
  List<String> get allSubjects => [...defaultSubjects, ..._customSubjects].toSet().toList();

  // Get all details (default + custom)
  List<String> get allDetails => [...defaultDetails, ..._customDetails].toSet().toList();

  // Get all payment methods (default + custom)
  List<String> get allPaymentMethods => [...paymentMethods, ..._customPaymentMethods].toSet().toList();

  // Load all dropdown data from storage
  Future<void> loadAllDropdownData() async {
    _childNames = _historyService.getChildNames();
    _businessNames = _historyService.getBusinessNames();
    _instructorNames = _historyService.getInstructorNames();
    _customSubjects = _historyService.getCustomSubjects();
    _customDetails = _historyService.getCustomDetails();
    _cardNames = _historyService.getCardNames();
    _customPaymentMethods = _historyService.getCustomPaymentMethods();
    notifyListeners();
  }

  // Add child name
  Future<void> addChildName(String name) async {
    if (name.trim().isEmpty || _childNames.contains(name)) return;
    await _historyService.addChildName(name);
    _childNames = _historyService.getChildNames();
    notifyListeners();
  }

  // Add business name
  Future<void> addBusinessName(String name) async {
    if (name.trim().isEmpty || _businessNames.contains(name)) return;
    await _historyService.addBusinessName(name);
    _businessNames = _historyService.getBusinessNames();
    notifyListeners();
  }

  // Add instructor name
  Future<void> addInstructorName(String name) async {
    if (name.trim().isEmpty || _instructorNames.contains(name)) return;
    await _historyService.addInstructorName(name);
    _instructorNames = _historyService.getInstructorNames();
    notifyListeners();
  }

  // Add custom subject
  Future<void> addCustomSubject(String subject) async {
    if (subject.trim().isEmpty ||
        defaultSubjects.contains(subject) ||
        _customSubjects.contains(subject)) {
      return;
    }
    await _historyService.addCustomSubject(subject);
    _customSubjects = _historyService.getCustomSubjects();
    notifyListeners();
  }

  // Add custom detail
  Future<void> addCustomDetail(String detail) async {
    if (detail.trim().isEmpty ||
        defaultDetails.contains(detail) ||
        _customDetails.contains(detail)) {
      return;
    }
    await _historyService.addCustomDetail(detail);
    _customDetails = _historyService.getCustomDetails();
    notifyListeners();
  }

  // Add card name
  Future<void> addCardName(String name) async {
    if (name.trim().isEmpty || _cardNames.contains(name)) return;
    await _historyService.addCardName(name);
    _cardNames = _historyService.getCardNames();
    notifyListeners();
  }

  // Add custom payment method
  Future<void> addCustomPaymentMethod(String method) async {
    if (method.trim().isEmpty ||
        paymentMethods.contains(method) ||
        _customPaymentMethods.contains(method)) {
      return;
    }
    await _historyService.addCustomPaymentMethod(method);
    _customPaymentMethods = _historyService.getCustomPaymentMethods();
    notifyListeners();
  }
}
