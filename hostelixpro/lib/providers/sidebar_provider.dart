import 'package:flutter/foundation.dart';

/// Manages sidebar collapsed state globally to persist across navigation
class SidebarProvider extends ChangeNotifier {
  bool _isCollapsed = true;

  bool get isCollapsed => _isCollapsed;

  void toggle() {
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  void expand() {
    if (_isCollapsed) {
      _isCollapsed = false;
      notifyListeners();
    }
  }

  void collapse() {
    if (!_isCollapsed) {
      _isCollapsed = true;
      notifyListeners();
    }
  }
}
