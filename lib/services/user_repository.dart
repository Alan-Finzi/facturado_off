import 'package:http/http.dart' as http;
import 'dart:convert';

import '../helper/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  Future<bool> authenticate(User user) async {
    User? dbUser = await databaseHelper.getUser(user.username);

    if (dbUser != null && dbUser.password == user.password) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    return await databaseHelper.getUsers();
  }
}