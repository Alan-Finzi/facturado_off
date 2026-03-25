import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../helper/database_helper.dart';
import '../../services/service_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'login_state.dart';


class LoginCubit extends Cubit<LoginState> {
  LoginCubit({bool isLogin = false, bool isPreference = false})
      : super(LoginState(isLogin: isLogin, userToken: null, isPreference: isPreference, needsOnlineAuth: false));

  // Método para cerrar sesión (mantener credenciales guardadas)
  void logout() {
    emit(const LoginState(isLogin: false, userToken: null, isPreference: false, needsOnlineAuth: false));
  }

  // Método para solicitar sincronización explícita
  void requestSynchronization() {
    emit(state.copyWith(needsOnlineAuth: true, isPreference: false));
  }

  Future<void> _saveCredentials(String email, String password, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Obtener la lista de usuarios almacenada previamente
    String? usersJson = prefs.getString('users');
    List<dynamic> users = usersJson != null ? jsonDecode(usersJson) : [];

    // Verificar si ya existe un usuario con el mismo email
    bool exists = users.any((user) => user['email'] == email);

    if (!exists) {
      // Agregar el nuevo usuario
      Map<String, String> newUser = {
        'email': email,
        'password': password,
        'token': token,
      };
      users.add(newUser);

      // Guardar la lista actualizada de usuarios
      await prefs.setString('users', jsonEncode(users));
    }
  }

  ///login
  Future<void> login(String? email, String? password) async {
    if (email?.isEmpty ?? true) {
      emit(const LoginState(isLogin: false, userToken: null, isPreference: false, needsOnlineAuth: false));
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final apiServices = ApiServices();
    final bool isSyncRequest = state.needsOnlineAuth;

    try {
      final String? lastActiveUserEmail = await User.getLastActiveUserEmail();
      final bool isSameUser = (lastActiveUserEmail == email);

      // ─── PATH A: Mismo usuario, sin sync explícita ──────────────────────────
      // Email coincide con el guardado en preferencias → cargar desde BD directamente
      if (isSameUser && !isSyncRequest) {
        final credentialsList = await _getCredentials();
        final savedCreds = credentialsList.firstWhere(
          (u) => u['email'] == email, orElse: () => {});
        final String? savedToken = savedCreds['token'];

        if (savedToken != null) {
          final User? userFromDB = await dbHelper.getUserByEmail(email!);
          if (userFromDB != null) {
            User.setCurrencyUser(userFromDB);
            final bool hasData = await dbHelper.isDataSynchronized();
            emit(LoginState(
              isLogin: true,
              userToken: savedToken,
              isPreference: hasData,
              user: userFromDB,
              needsOnlineAuth: false,
              needsDataInitialization: hasData,
            ));
            return;
          }
          // Usuario no encontrado en BD → continuar con PATH B;
        }
      }

      // ─── PATH B: Nuevo usuario, primer login, sync explícita o sin datos ────
      // Si el usuario cambió, limpiar la BD del usuario anterior
      if (lastActiveUserEmail != null && lastActiveUserEmail != email) {
        await dbHelper.deleteDatabaseIfExists();
        User.currencyUser = null;
      }

      // Sin password → modo offline con token guardado
      if (password?.isEmpty ?? true) {
        await _loginConTokenGuardado(email!, dbHelper);
        return;
      }

      // Llamar a la API de login para obtener el token
      final loginResult = await apiServices.loginUser(email!, password!);

      if (loginResult != null) {
        final String token = loginResult['token'] as String;
        final User? userFromLogin = loginResult['user'] as User?;
        await _saveCredentials(email, password, token);

        // Si la API de login devuelve el usuario, setearlo provisionalmente
        // (será confirmado/reemplazado por fetchUsersData durante la sync)
        if (userFromLogin != null) {
          User.setCurrencyUser(userFromLogin);
        }

        emit(LoginState(
          isLogin: true,
          userToken: token,
          isPreference: false,
          user: userFromLogin ?? User(username: email, password: password),
          needsOnlineAuth: false,
        ));
      } else {
        await _loginConTokenGuardado(email, dbHelper);
      }
    } catch (e) {
      await _loginConTokenGuardado(email ?? '', dbHelper);
    }
  }

  /// Fallback offline: usa el token guardado y carga el usuario desde BD
  Future<void> _loginConTokenGuardado(String email, DatabaseHelper dbHelper) async {
    final credentialsList = await _getCredentials();
    final savedCreds = credentialsList.firstWhere(
      (u) => u['email'] == email, orElse: () => {});

    if (savedCreds.isNotEmpty && savedCreds['token'] != null) {
      final bool hasData = await dbHelper.isDataSynchronized();
      final User? userFromDB = await dbHelper.getUserByEmail(email);
      if (userFromDB != null) {
        User.setCurrencyUser(userFromDB);
      }
      emit(LoginState(
        isLogin: true,
        userToken: savedCreds['token']!,
        isPreference: hasData,
        user: userFromDB ?? User(username: email, password: savedCreds['password']),
        needsOnlineAuth: false,
        needsDataInitialization: hasData,
      ));
    } else {
      emit(const LoginState(isLogin: false, userToken: null, isPreference: false, needsOnlineAuth: false));
    }
  }


  Future<List<Map<String, String>>> _getCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Obtener la lista almacenada como JSON
    String? usersJson = prefs.getString('users');

    if (usersJson != null) {
      // Decodificar la lista de usuarios desde el string JSON
      List<dynamic> users = jsonDecode(usersJson);

      // Convertir la lista dinámica en una lista de mapas con tipo adecuado
      return List<Map<String, String>>.from(users.map((user) => Map<String, String>.from(user)));
    }

    // Si no hay usuarios almacenados, devolver una lista vacía
    return [];
  }

}