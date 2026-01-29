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
    } else {
      print("El usuario ya existe.");
    }
  }

  ///login
  Future<void> login(String? email, String? password) async {
    ApiServices apiServices = ApiServices();
    final dbHelper = DatabaseHelper.instance;

    // Log para diagnóstico
    final isOfflineLogin = password == null;
    final isSyncRequest = state.needsOnlineAuth;
    print('=== INICIO PROCESO DE LOGIN ===');
    print('Modo: ${isOfflineLogin ? "OFFLINE (credenciales guardadas)" : "ONLINE (API)"}');
    print('Email: ${email ?? "no proporcionado"}');
    print('Password: ${password != null ? "proporcionada" : "no proporcionada"}');
    print('Solicitud de sincronización: ${isSyncRequest ? "SÍ" : "NO"}');

    try {
      // Validación de email o password vacíos
      if ((email?.isEmpty ?? true) || (password?.isEmpty ?? true && !isOfflineLogin)) {
        print("Acceso denegado: Email o contraseña vacíos.");
        emit(LoginState(
          isLogin: false,
          userToken: null,
          isPreference: false,
          needsOnlineAuth: isSyncRequest,
        ));
        return;
      }

      // Intentamos obtener credenciales guardadas (por email si está presente)
      final credentialsList = await _getCredentials();
      final userCredentials = credentialsList.firstWhere(
            (user) => user['email'] == email,
        orElse: () => {},
      );

      // Primer flujo: Login normal (no es una solicitud de sincronización)
      if (!isSyncRequest) {
        // Si el usuario tiene credenciales guardadas, intentamos usarlas primero
        if (userCredentials.isNotEmpty && !isSyncRequest) {
          final savedToken = userCredentials['token'];
          final savedPassword = userCredentials['password'];

          // Si ya hay un token guardado y no se ingresó manualmente password, lo usamos
          if (savedToken != null && (password == null || password.isEmpty)) {
            // Verificar si ya hay datos sincronizados en la DB
            final hasData = await dbHelper.isDataSynchronized();
            print("Verificando datos sincronizados: ${hasData ? "DATOS ENCONTRADOS" : "SIN DATOS"}");

            // Para login normal sin solicitud de sincronización:
            // - Si hay datos, omitir sincronización (isPreference=true)
            // - Si no hay datos, mostrar sincronización (isPreference=false)
            emit(LoginState(
              isLogin: true,
              userToken: savedToken,
              isPreference: hasData, // Si hay datos, omitir sincronización
              user: User(username: email, password: savedPassword),
              needsOnlineAuth: false,
            ));
            return;
          }
        }
      }
      // Segundo flujo: Solicitud explícita de sincronización - siempre necesita API
      else {
        print("⚠️ Solicitud explícita de sincronización - Forzando API login");
        // No usamos credenciales guardadas, siempre forzamos login online
      }

      // Llamar a la API (login online obligatorio para sincronización explícita)
      final token = await apiServices.loginUser(email!, password!);

      if (token != null) {
        // Autenticación exitosa: Guardamos credenciales y emitimos el estado
        print("✅ Login API exitoso. Token obtenido: ${token.substring(0, 10)}...");
        await _saveCredentials(email!, password!, token);
        print("✅ Credenciales guardadas localmente para uso futuro");

        final hasData = await dbHelper.isDataSynchronized();
        print("Verificando datos sincronizados: ${hasData ? "DATOS ENCONTRADOS" : "SIN DATOS"}");

        if (isSyncRequest) {
          // Para solicitud de sincronización explícita: siempre mostrar pantalla de sincronización
          emit(LoginState(
            isLogin: true,
            userToken: token,
            isPreference: false, // Forzar sincronización
            user: User(username: email, password: password),
            needsOnlineAuth: false, // Ya no necesitamos auth
          ));
          print("✅ Login exitoso para sincronización solicitada. Mostrando pantalla de sincronización.");
        } else {
          // Para login normal:
          emit(LoginState(
            isLogin: true,
            userToken: token,
            isPreference: hasData, // Si hay datos, omitir sincronización
            user: User(username: email, password: password),
            needsOnlineAuth: false,
          ));
          print("✅ Login completado con éxito. Modo: ONLINE");
          if (hasData) {
            print("✅ Base de datos ya contiene datos. Se omitirá la sincronización.");
          }
        }
      } else {
        // Fallo en la autenticación API
        if (isSyncRequest) {
          // Para solicitud de sincronización: error, no podemos sincronizar sin token válido
          emit(LoginState(
            isLogin: false,
            userToken: null,
            isPreference: true, // Mantener en la app con datos existentes
            needsOnlineAuth: true, // Seguir solicitando auth para sincronizar
          ));
          print("❌ Error de autenticación para sincronización. Se requiere credenciales válidas.");
        } else if (userCredentials.isNotEmpty && userCredentials['token'] != null) {
          // Para login normal: usar credenciales guardadas si existen
          print("⚠️ Login API falló, usando token guardado temporalmente.");
          print("Token previamente guardado: ${userCredentials['token']?.substring(0, 10)}...");

          final hasData = await dbHelper.isDataSynchronized();
          print("Verificando datos sincronizados: ${hasData ? "DATOS ENCONTRADOS" : "SIN DATOS"}");

          emit(LoginState(
            isLogin: true,
            userToken: userCredentials['token'],
            isPreference: hasData, // Si hay datos, omitir sincronización
            user: User(username: email, password: userCredentials['password']),
            needsOnlineAuth: false,
          ));
          print("✅ Login completado con token almacenado. Modo: OFFLINE");
          if (hasData) {
            print("✅ Base de datos ya contiene datos. Se omitirá la sincronización.");
          }
        } else {
          // Sin credenciales guardadas y fallo API = error
          emit(LoginState(
            isLogin: false,
            userToken: null,
            isPreference: false,
            needsOnlineAuth: isSyncRequest, // Mantener el estado de solicitud de sincronización
          ));
          print("❌ Acceso denegado: Credenciales incorrectas. No hay token almacenado.");
        }
      }
    } catch (e) {
      print("Error durante el login: $e");

      if (isSyncRequest) {
        // Si es solicitud de sincronización, mantenemos el estado
        emit(LoginState(
          isLogin: false,
          userToken: null,
          isPreference: true, // Mantener en la app
          needsOnlineAuth: true, // Seguir solicitando auth
        ));
        print("❌ Error durante login para sincronización: $e");
      } else {
        // Para login normal, intentamos usar credenciales guardadas
        final credentialsList = await _getCredentials();
        final userCredentials = credentialsList.firstWhere(
              (user) => user['email'] == email,
          orElse: () => {},
        );

        if (userCredentials.isNotEmpty && userCredentials['token'] != null) {
          print("⚠️ Error en login, usando token guardado temporalmente.");

          final hasData = await dbHelper.isDataSynchronized();
          print("Verificando datos sincronizados: ${hasData ? "DATOS ENCONTRADOS" : "SIN DATOS"}");

          emit(LoginState(
            isLogin: true,
            userToken: userCredentials['token'],
            isPreference: hasData, // Si hay datos, omitir sincronización
            user: User(username: email, password: userCredentials['password']),
            needsOnlineAuth: false,
          ));

          if (hasData) {
            print("✅ Base de datos ya contiene datos. Se omitirá la sincronización.");
          }
        } else {
          emit(const LoginState(isLogin: false, userToken: null, isPreference: false, needsOnlineAuth: false));
        }
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