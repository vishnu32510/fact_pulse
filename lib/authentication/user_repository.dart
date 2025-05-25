import 'dart:async';
import 'package:uuid/uuid.dart';
import 'user.dart';

class UserRepository {
  User? _user;

  Future<User?> getUser() async {
    if (_user != null) return _user;
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => _user = User(id: const Uuid().v4(), name: ''),
    );
  }
}