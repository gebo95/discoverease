import 'package:flutter/foundation.dart';

/// Lets any screen under the main shell switch to the Explore tab with
/// something already chosen, for example "See all" on a home row. Going
/// through the tab keeps the bottom navigation bar on screen.
class MainShellController extends ChangeNotifier {
  int _requestId = 0;
  String? _category;
  String? _areaId;
  String? _filter;

  /// Changes with every request, so Explore starts fresh each time.
  int get requestId => _requestId;
  String? get category => _category;
  String? get areaId => _areaId;
  String? get filter => _filter;

  void openExplore({String? category, String? areaId, String? filter}) {
    _requestId++;
    _category = category;
    _areaId = areaId;
    _filter = filter;
    notifyListeners();
  }

  /// Forget the last request, such as when the traveler taps the Explore tab
  /// themselves.
  void clear() {
    _category = null;
    _areaId = null;
    _filter = null;
  }
}
