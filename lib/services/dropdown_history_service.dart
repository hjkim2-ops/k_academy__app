import 'package:k_academy__app/services/storage_service.dart';

class DropdownHistoryService {
  // Children
  List<String> getChildNames() {
    final box = StorageService.childrenBox;
    return box.values.toList();
  }

  Future<void> addChildName(String name) async {
    if (name.trim().isEmpty) return;
    final box = StorageService.childrenBox;
    if (!box.values.contains(name)) {
      await box.add(name);
    }
  }

  Future<void> removeChildName(String name) async {
    final box = StorageService.childrenBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == name,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Business names
  List<String> getBusinessNames() {
    final box = StorageService.businessNamesBox;
    return box.values.toList();
  }

  Future<void> addBusinessName(String name) async {
    if (name.trim().isEmpty) return;
    final box = StorageService.businessNamesBox;
    if (!box.values.contains(name)) {
      await box.add(name);
    }
  }

  Future<void> removeBusinessName(String name) async {
    final box = StorageService.businessNamesBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == name,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Instructors
  List<String> getInstructorNames() {
    final box = StorageService.instructorsBox;
    return box.values.toList();
  }

  Future<void> addInstructorName(String name) async {
    if (name.trim().isEmpty) return;
    final box = StorageService.instructorsBox;
    if (!box.values.contains(name)) {
      await box.add(name);
    }
  }

  Future<void> removeInstructorName(String name) async {
    final box = StorageService.instructorsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == name,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Custom subjects
  List<String> getCustomSubjects() {
    final box = StorageService.customSubjectsBox;
    return box.values.toList();
  }

  Future<void> addCustomSubject(String subject) async {
    if (subject.trim().isEmpty) return;
    final box = StorageService.customSubjectsBox;
    if (!box.values.contains(subject)) {
      await box.add(subject);
    }
  }

  Future<void> removeCustomSubject(String subject) async {
    final box = StorageService.customSubjectsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == subject,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Custom details
  List<String> getCustomDetails() {
    final box = StorageService.customDetailsBox;
    return box.values.toList();
  }

  Future<void> addCustomDetail(String detail) async {
    if (detail.trim().isEmpty) return;
    final box = StorageService.customDetailsBox;
    if (!box.values.contains(detail)) {
      await box.add(detail);
    }
  }

  Future<void> removeCustomDetail(String detail) async {
    final box = StorageService.customDetailsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == detail,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Card names
  List<String> getCardNames() {
    final box = StorageService.cardNamesBox;
    return box.values.toList();
  }

  Future<void> addCardName(String name) async {
    if (name.trim().isEmpty) return;
    final box = StorageService.cardNamesBox;
    if (!box.values.contains(name)) {
      await box.add(name);
    }
  }

  Future<void> removeCardName(String name) async {
    final box = StorageService.cardNamesBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == name,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Custom payment methods
  List<String> getCustomPaymentMethods() {
    final box = StorageService.customPaymentMethodsBox;
    return box.values.toList();
  }

  Future<void> addCustomPaymentMethod(String method) async {
    if (method.trim().isEmpty) return;
    final box = StorageService.customPaymentMethodsBox;
    if (!box.values.contains(method)) {
      await box.add(method);
    }
  }

  Future<void> removeCustomPaymentMethod(String method) async {
    final box = StorageService.customPaymentMethodsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == method,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // --- Hidden default items ---

  // Hidden subjects
  List<String> getHiddenSubjects() {
    return StorageService.hiddenSubjectsBox.values.toList();
  }

  Future<void> addHiddenSubject(String subject) async {
    final box = StorageService.hiddenSubjectsBox;
    if (!box.values.contains(subject)) {
      await box.add(subject);
    }
  }

  Future<void> removeHiddenSubject(String subject) async {
    final box = StorageService.hiddenSubjectsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == subject,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Hidden details
  List<String> getHiddenDetails() {
    return StorageService.hiddenDetailsBox.values.toList();
  }

  Future<void> addHiddenDetail(String detail) async {
    final box = StorageService.hiddenDetailsBox;
    if (!box.values.contains(detail)) {
      await box.add(detail);
    }
  }

  Future<void> removeHiddenDetail(String detail) async {
    final box = StorageService.hiddenDetailsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == detail,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Hidden payment methods
  List<String> getHiddenPaymentMethods() {
    return StorageService.hiddenPaymentMethodsBox.values.toList();
  }

  Future<void> addHiddenPaymentMethod(String method) async {
    final box = StorageService.hiddenPaymentMethodsBox;
    if (!box.values.contains(method)) {
      await box.add(method);
    }
  }

  Future<void> removeHiddenPaymentMethod(String method) async {
    final box = StorageService.hiddenPaymentMethodsBox;
    final key = box.keys.firstWhere(
      (k) => box.get(k) == method,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // --- Child name order ---

  List<String> getChildNameOrder() {
    return StorageService.childNameOrderBox.values.toList();
  }

  Future<void> saveChildNameOrder(List<String> order) async {
    final box = StorageService.childNameOrderBox;
    await box.clear();
    for (final name in order) {
      await box.add(name);
    }
  }
}
