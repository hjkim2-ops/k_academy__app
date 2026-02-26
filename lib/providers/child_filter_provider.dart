import 'package:flutter/foundation.dart';

class ChildFilterProvider extends ChangeNotifier {
  String? _selectedChild; // null = 전체 자녀

  String? get selectedChild => _selectedChild;

  void select(String? child) {
    if (_selectedChild == child) return;
    _selectedChild = child;
    notifyListeners();
  }
}
