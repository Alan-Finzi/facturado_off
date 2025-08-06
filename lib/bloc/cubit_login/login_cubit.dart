import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../services/service_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'login_state.dart';


class LoginCubit extends Cubit<LoginState> {
  LoginCubit({bool isLogin = false, bool isPreference = false})
      : super(LoginState(isLogin: isLogin, userToken: null, isPreference: isPreference));

  // Método para cerrar sesión (mantener credenciales guardadas)
  void logout() {
    emit(const LoginState(isLogin: false, userToken: null, isPreference: false));
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
    } else {
      print("El usuario ya existe.");
    }
  }

  ///login
  Future<void> login(String? email, String? password) async {
    ApiServices apiServices = ApiServices();

    try {
      // Validación de email o password vacíos
      if ((email?.isEmpty ?? true) || (password?.isEmpty ?? true)) {
        print("Acceso denegado: Email o contraseña vacíos.");
        emit(const LoginState(isLogin: false, userToken: null, isPreference: false));
        return;
      }

      // Intentamos obtener credenciales guardadas (por email si está presente)
      final credentialsList = await _getCredentials();
      final userCredentials = credentialsList.firstWhere(
            (user) => user['email'] == email,
        orElse: () => {},
      );

      // Si el usuario tiene credenciales guardadas, intentamos usarlas primero
      if (userCredentials.isNotEmpty) {
        final savedToken = userCredentials['token'];
        final savedPassword = userCredentials['password'];

        // Si ya hay un token guardado y no se ingresó manualmente password, lo usamos
        if (savedToken != null && (password == null || password.isEmpty)) {
          emit(LoginState(
            isLogin: true,
            userToken: savedToken,
            isPreference: true,
            user: User(username: email, password: savedPassword),
          ));
          return;
        }
      }

      // Si tenemos email y password (ingresados manualmente o de SharedPreferences), llamamos a la API
      final token = await apiServices.loginUser(email!, password!);

      if (token != null) {
        // Autenticación exitosa: Guardamos credenciales y emitimos el estado
        await _saveCredentials(email!, password!, token);
        emit(LoginState(
          isLogin: true,
          userToken: token,
          isPreference: false,
          user: User(username: email, password: password),
        ));
      } else {
        // Fallo en la autenticación: pero si hay token viejo, lo usamos temporalmente
        if (userCredentials.isNotEmpty && userCredentials['token'] != null) {
          print("⚠️ Login API falló, usando token guardado temporalmente.");
          emit(LoginState(
            isLogin: true,
            userToken: userCredentials['token'],
            isPreference: true,
            user: User(username: email, password: userCredentials['password']),
          ));
        } else {
          emit(const LoginState(isLogin: false, userToken: null, isPreference: false));
          print("Acceso denegado: Credenciales incorrectas.");
        }
      }
    } catch (e) {
      print("Error durante el login: $e");

      // En caso de error inesperado, intentamos emitir un acceso temporal si hay token guardado
      final credentialsList = await _getCredentials();
      final userCredentials = credentialsList.firstWhere(
            (user) => user['email'] == email,
        orElse: () => {},
      );

      if (userCredentials.isNotEmpty && userCredentials['token'] != null) {
        print("⚠️ Error en login, usando token guardado temporalmente.");
        emit(LoginState(
          isLogin: true,
          userToken: userCredentials['token'],
          isPreference: true,
          user: User(username: email, password: userCredentials['password']),
        ));
      } else {
        emit(const LoginState(isLogin: false, userToken: null, isPreference: false));
      }
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