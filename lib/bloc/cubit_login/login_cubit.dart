import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';
import '../../services/firestore_service.dart';
import '../../services/service_api.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({bool isLogin = false, bool isPreference = false})
      : super(LoginState(
            isLogin: isLogin,
            userToken: null,
            isPreference: isPreference,
            needsOnlineAuth: false));

  void logout() {
    emit(const LoginState(
        isLogin: false,
        userToken: null,
        isPreference: false,
        needsOnlineAuth: false));
  }

  void requestSynchronization() {
    emit(state.copyWith(needsOnlineAuth: true, isPreference: false));
  }

  Future<void> _saveCredentials(
      String email, String password, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    final users =
        usersJson != null ? jsonDecode(usersJson) as List<dynamic> : [];

    if (!users.any((u) => u['email'] == email)) {
      users.add({'email': email, 'password': password, 'token': token});
      await prefs.setString('users', jsonEncode(users));
    }
  }

  Future<void> login(String? email, String? password) async {
    if (email?.isEmpty ?? true) {
      emit(const LoginState(
          isLogin: false,
          userToken: null,
          isPreference: false,
          needsOnlineAuth: false));
      return;
    }

    final fs = FirestoreService.instance;
    final apiServices = ApiServices();
    final isSyncRequest = state.needsOnlineAuth;

    try {
      final lastActiveEmail = await User.getLastActiveUserEmail();
      final isSameUser = lastActiveEmail == email;

      // PATH A: mismo usuario sin sync explícita → cargar desde Firestore (cache)
      if (isSameUser && !isSyncRequest) {
        final creds = await _getCredentials();
        final saved =
            creds.firstWhere((u) => u['email'] == email, orElse: () => {});
        final savedToken = saved['token'];

        if (savedToken != null) {
          final userFromFS = await fs.getUserByEmail(email!);
          if (userFromFS != null) {
            User.setCurrencyUser(userFromFS);
            final hasData = await fs.isDataSynchronized();
            emit(LoginState(
              isLogin: true,
              userToken: savedToken,
              isPreference: hasData,
              user: userFromFS,
              needsOnlineAuth: false,
              needsDataInitialization: hasData,
            ));
            return;
          }
        }
      }

      // PATH B: usuario nuevo, primer login o sync explícita
      if (lastActiveEmail != null && lastActiveEmail != email) {
        User.currencyUser = null;
      }

      if (password?.isEmpty ?? true) {
        await _loginConTokenGuardado(email!, fs);
        return;
      }

      final loginResult = await apiServices.loginUser(email!, password!);

      if (loginResult != null) {
        final token = loginResult['token'] as String;
        final userFromLogin = loginResult['user'] as User?;
        await _saveCredentials(email, password, token);

        if (userFromLogin != null) {
          User.setCurrencyUser(userFromLogin);
          await fs.upsertUser(userFromLogin);
        }

        emit(LoginState(
          isLogin: true,
          userToken: token,
          isPreference: false,
          user: userFromLogin ?? User(username: email, password: password),
          needsOnlineAuth: false,
        ));
      } else {
        await _loginConTokenGuardado(email, fs);
      }
    } catch (_) {
      await _loginConTokenGuardado(email ?? '', fs);
    }
  }

  Future<void> _loginConTokenGuardado(
      String email, FirestoreService fs) async {
    final creds = await _getCredentials();
    final saved =
        creds.firstWhere((u) => u['email'] == email, orElse: () => {});

    if (saved.isNotEmpty && saved['token'] != null) {
      final hasData = await fs.isDataSynchronized();
      final userFromFS = await fs.getUserByEmail(email);
      if (userFromFS != null) User.setCurrencyUser(userFromFS);

      emit(LoginState(
        isLogin: true,
        userToken: saved['token']!,
        isPreference: hasData,
        user: userFromFS ??
            User(username: email, password: saved['password']),
        needsOnlineAuth: false,
        needsDataInitialization: hasData,
      ));
    } else {
      emit(const LoginState(
          isLogin: false,
          userToken: null,
          isPreference: false,
          needsOnlineAuth: false));
    }
  }

  Future<List<Map<String, String>>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    if (usersJson != null) {
      final users = jsonDecode(usersJson) as List<dynamic>;
      return List<Map<String, String>>.from(
          users.map((u) => Map<String, String>.from(u)));
    }
    return [];
  }
}
