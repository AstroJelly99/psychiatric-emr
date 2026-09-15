import 'package:flutter/material.dart';

class PanelProvider with ChangeNotifier {
  int _currentPage = 0; 
  bool _minimizeNav = false;
  final List<bool> _isOpenAccordion = [false, false, false];

  PanelProvider(BuildContext context);

  int get currentPage => _currentPage;
  bool get minimizeNav => _minimizeNav;
  List<bool> get isOpenAccordion => _isOpenAccordion;

  set minimizeNav(bool value) {
    _minimizeNav = value;
    notifyListeners();
  }

  void setPage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void setAccordionType(int index) {
    _isOpenAccordion[index] = !_isOpenAccordion[index];
    notifyListeners();
  }
}