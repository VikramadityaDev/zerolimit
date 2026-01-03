import 'package:flutter_riverpod/legacy.dart';

final userProvider =
StateNotifierProvider<UserNotifier, String>(
      (ref) => UserNotifier(),
);

class UserNotifier extends StateNotifier<String> {
  UserNotifier() : super('');

  String get phone => state;

  void setPhone(String newPhone) {
    state = newPhone;
  }

  void clear() {
    state = '';
  }
}