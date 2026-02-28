import 'package:flutter/foundation.dart';

class SelectedDateProvider with ChangeNotifier {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
