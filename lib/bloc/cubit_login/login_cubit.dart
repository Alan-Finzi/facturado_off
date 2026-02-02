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

            if (!hasData) {
              print("⚠️ Datos sincronizados incompletos o faltantes - forzando sincronización");

              // Para login normal sin solicitud de sincronización,
              // pero detectamos que faltan datos esenciales:
              // 1. Mantenemos al usuario logueado (isLogin=true)
              // 2. Pero forzamos la sincronización (isPreference=false)
              emit(LoginState(
                isLogin: true,
                userToken: savedToken,
                isPreference: false, // Forzar sincronización cuando faltan datos
                user: User(username: email, password: savedPassword),
                needsOnlineAuth: false,
              ));
            } else {
              // Datos sincronizados completos, necesitamos verificar si están cargados en memoria

              // NUEVO FLUJO: Verificar si están cargados en memoria
              final bool areDataLoaded = DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty &&
                                        User.currencyUser != null;

              if (!areDataLoaded) {
                print("🔍 Los datos están en la BD pero no en memoria - redirigiendo a inicialización de datos");

                // Crear usuario básico para la inicialización
                final User userBasico = User(username: email, password: savedPassword);

                // Emitir estado para ir a página de inicialización de datos
                emit(LoginState(
                  isLogin: true,
                  userToken: savedToken,
                  isPreference: false, // No omitir la inicialización
                  user: userBasico,
                  needsOnlineAuth: false,
                  needsDataInitialization: true, // Flag para ir a inicialización
                ));
                return;
              }

              // FLUJO ORIGINAL: Los datos ya están cargados en memoria
              try {
                // Buscar el usuario completo en la base de datos por email
                User? userFromDB = await dbHelper.getUserByEmail(email!);

                if (userFromDB != null) {
                  // Establecer el usuario actual en memoria para toda la sesión
                  User.setCurrencyUser(userFromDB);
                  print("✅ Usuario cargado desde BD: ${userFromDB.username} (comercioId: ${userFromDB.comercioId})");

                  // Cargar los demás modelos currency
                  await dbHelper.loadAllCurrencyModels(userFromDB);
                  print("✅ Datos currency adicionales cargados para login offline");

                  // Emitir estado con el usuario completo
                  emit(LoginState(
                    isLogin: true,
                    userToken: savedToken,
                    isPreference: true, // Omitir sincronización
                    user: userFromDB, // Usuario completo con todos sus campos
                    needsOnlineAuth: false,
                  ));
                } else {
                  print("⚠️ No se encontró el usuario en la BD, usando usuario básico");
                  // Emitir estado con usuario básico
                  emit(LoginState(
                    isLogin: true,
                    userToken: savedToken,
                    isPreference: true, // Omitir sincronización
                    user: User(username: email, password: savedPassword),
                    needsOnlineAuth: false,
                  ));
                }
              } catch (e) {
                print("❌ Error al cargar usuario desde BD: $e");
                // Si falla, usar el usuario básico
                emit(LoginState(
                  isLogin: true,
                  userToken: savedToken,
                  isPreference: true, // Omitir sincronización
                  user: User(username: email, password: savedPassword),
                  needsOnlineAuth: false,
                ));
              }
            }
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
          if (!hasData) {
            print("⚠️ Datos sincronizados incompletos o faltantes - forzando sincronización");
            // Forzar la sincronización cuando detectamos datos faltantes
            emit(LoginState(
              isLogin: true,
              userToken: token,
              isPreference: false, // Forzar sincronización
              user: User(username: email, password: password),
              needsOnlineAuth: false,
            ));
            print("✅ Login completado. Forzando sincronización por datos faltantes.");
          } else {
            // Datos sincronizados completos, continuar normalmente
            emit(LoginState(
              isLogin: true,
              userToken: token,
              isPreference: true, // Omitir sincronización
              user: User(username: email, password: password),
              needsOnlineAuth: false,
            ));
            print("✅ Login completado con éxito. Modo: ONLINE");
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

          // Buscar el usuario completo en la base de datos
          User? userFromDB = await dbHelper.getUserByEmail(email!);

          if (userFromDB != null) {
            // Establecer el usuario actual en memoria para toda la sesión
            User.setCurrencyUser(userFromDB);
            print("✅ Usuario cargado desde BD: ${userFromDB.username} (comercioId: ${userFromDB.comercioId})");

            // Cargar los demás modelos currency
            await dbHelper.loadAllCurrencyModels(userFromDB);
            print("✅ Datos currency adicionales cargados para login con token almacenado");

            // Emitir estado con el usuario completo
            emit(LoginState(
              isLogin: true,
              userToken: userCredentials['token'],
              isPreference: hasData, // Si hay datos, omitir sincronización
              user: userFromDB, // Usuario completo con todos sus campos
              needsOnlineAuth: false,
            ));
          } else {
            // Si no se encuentra el usuario en la BD, usar usuario básico
            print("⚠️ No se encontró el usuario en la BD, usando usuario básico");
            emit(LoginState(
              isLogin: true,
              userToken: userCredentials['token'],
              isPreference: hasData, // Si hay datos, omitir sincronización
              user: User(username: email, password: userCredentials['password']),
              needsOnlineAuth: false,
            ));
          }

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

          // Buscar el usuario completo en la base de datos
          User? userFromDB = await dbHelper.getUserByEmail(email!);

          if (!hasData) {
            print("⚠️ Datos sincronizados incompletos o faltantes - forzando sincronización");

            // Emitir estado, usando el usuario completo si está disponible
            emit(LoginState(
              isLogin: true,
              userToken: userCredentials['token'],
              isPreference: false, // Forzar sincronización cuando faltan datos
              user: userFromDB ?? User(username: email, password: userCredentials['password']),
              needsOnlineAuth: false,
            ));

            // Si hay usuario completo, establecerlo en memoria y cargar datos adicionales
            if (userFromDB != null) {
              User.setCurrencyUser(userFromDB);
              print("✅ Usuario de emergencia cargado desde BD: ${userFromDB.username} (comercioId: ${userFromDB.comercioId})");

              // Cargar los demás modelos currency
              await dbHelper.loadAllCurrencyModels(userFromDB);
              print("✅ Datos currency adicionales cargados para login de emergencia");
            }

            print("✅ Login de emergencia completado. Forzando sincronización por datos faltantes.");
          } else {
            // Si hay datos sincronizados, usar el usuario completo si está disponible
            if (userFromDB != null) {
              User.setCurrencyUser(userFromDB);
              print("✅ Usuario de emergencia cargado desde BD: ${userFromDB.username} (comercioId: ${userFromDB.comercioId})");

              // Cargar los demás modelos currency
              await dbHelper.loadAllCurrencyModels(userFromDB);
              print("✅ Datos currency adicionales cargados para login normal con datos");

              emit(LoginState(
                isLogin: true,
                userToken: userCredentials['token'],
                isPreference: true, // Omitir sincronización cuando hay datos
                user: userFromDB,
                needsOnlineAuth: false,
              ));
            } else {
              emit(LoginState(
                isLogin: true,
                userToken: userCredentials['token'],
                isPreference: true, // Omitir sincronización cuando hay datos
                user: User(username: email, password: userCredentials['password']),
                needsOnlineAuth: false,
              ));
            }

            print("✅ Login de emergencia completado con éxito.");
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