import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _phone = '';

  String get phone => _phone;

  set setphone(String newName) {
    _phone = newName;
    notifyListeners();
  }
}