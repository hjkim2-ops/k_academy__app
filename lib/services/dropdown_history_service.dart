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
}
