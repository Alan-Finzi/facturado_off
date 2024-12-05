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

  Future<void> login(String? email, String? password) async {
    ApiServices apiServices = ApiServices();

    try {
      // Validación de email o password vacíos
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        print("Acceso denegado: Email o contraseña vacíos.");
        emit(const LoginState(isLogin: false, userToken: null, isPreference: false));
        return;
      }

      // Si no tenemos email y password (significa que el usuario no ha ingresado credenciales)
      if (email == null || password == null) {
        final credentialsList = await _getCredentials();

        // Verificamos si tenemos usuarios guardados en las preferencias
        if (credentialsList.isNotEmpty) {
          // Buscamos si existe el usuario con el email proporcionado
          final userCredentials = credentialsList.firstWhere(
                (user) => user['email'] == email,
            orElse: () => {}, // Devuelve un mapa vacío si no se encuentra el usuario
          );

          if (userCredentials.isNotEmpty) {
            password = userCredentials['password'];
            final savedToken = userCredentials['token'];

            // Si ya tenemos un token guardado, lo usamos directamente
            if (savedToken != null) {

              emit(LoginState(isLogin: true, userToken: savedToken,isPreference: false,user: User(username: email, password: password)));
              return;
            }
          }
        }
      }

      // Si es la primera vez (el usuario ha proporcionado email y password), llamamos a la API
      if (email != null && password != null) {
        final token = await apiServices.loginUser(email, password);
        if (token != null) {

          // Guardamos las credenciales en SharedPreferences
          await _saveCredentials(email, password, token);
          emit(LoginState(isLogin: true, userToken: token, isPreference: false));
        } else {
          // Fallo en la autenticación
          emit(const LoginState(isLogin: false, userToken: null,isPreference: false));
          print("Acceso denegado: Credenciales incorrectas.");
        }
      } else {
        // Si no hay credenciales ni en el input ni en SharedPreferences
        emit(const LoginState(isLogin: false, userToken: null,isPreference: false));
      }
    } catch (e) {
      print("Error durante el login: $e");
      emit(const LoginState(isLogin: false, userToken: null,isPreference: false)); // Emitir estado de error
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