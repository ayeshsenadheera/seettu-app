import 'package:flutter/foundation.dart';

/// Which bottom tab (Home, Groups, Payment, Members, Profile) is showing.
/// Lets a screen like Home switch to the Payment tab without pushing a new route.
class TabState extends ChangeNotifier {
  int index = 0;
  void go(int i) {
    index = i;
    notifyListeners();
  }
}
