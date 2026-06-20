import 'package:flutter/foundation.dart';

class ScoreReminderNotifier extends ChangeNotifier {
  int _threshold = 45;
  bool _isActive = true;

  int get threshold => _threshold;
  bool get isActive => _isActive;

  void setThreshold(int value) {
    _threshold = value;
    notifyListeners();
  }

  void setActive(bool value) {
    _isActive = value;
    notifyListeners();
  }
}
