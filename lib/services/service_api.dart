import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/datos_facturacion_model.dart';
import '../models/payment_provider.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_maestro.dart';
import '../models/user.dart';
import 'firestore_service.dart';

class ApiServices {
  final String apiUrlUser = 'https://api.flamincoapp.com.ar/api/users';
  final String apiUrlClienteMostrador = 'https://api.flamincoapp.com.ar/api/clientes';
  final String apiUrlLogin = 'https://api.flamincoapp.com.ar/api/login';
  final String apiUrlProductosVer = 'https://api.flamincoapp.com.ar/api/productos-ver';
  final String apiUrlProductoIva = 'https://api.flamincoapp.com.ar/api/producto-ivas';
  final String apiUrlDatosFacturacion = 'https://api.flamincoapp.com.ar/api/dato-facturacions';
  final String apiUrlCategoria = 'https://api.flamincoapp.com.ar/api/categories';
  final String apiUrlMetodosPago = 'https://api.flamincoapp.com.ar/api/metodos-pago';

  late String tokenUser = '';

  final _fs = FirestoreService.instance;

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final client = http.Client();
      try {
        final response = await http.post(
          Uri.parse(apiUrlLogin),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          client.close();
          throw TimeoutException('Login timeout');
        });

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final token = json['token'] as String?;
          if (token == null) return null;
          tokenUser = token;

          User? userFromResponse;
          try {
            if (json['user'] is Map<String, dynamic>) {
              userFromResponse = User.fromJson(json['user'] as Map<String, dynamic>);
            }
          } catch (_) {}

          return {'token': token, 'user': userFromResponse};
        }
        return null;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  Future<List<User>?> fetchUsersData(
      String token, String email, LoginCubit loginCubit) async {
    try {
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId =
          User.currencyUser?.sucursal?.toString() ?? User.currencyUser?.id?.toString();

      if (comercioId == null) {
        throw Exception('comercioId no disponible');
      }

      final idBusqueda = (comercioId == '1') ? (sucursalId ?? comercioId) : comercioId;
      final client = http.Client();
      try {
        final response = await http.get(
          Uri.parse('$apiUrlUser?comercio_id=$idBusqueda'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          client.close();
          throw TimeoutException('Users fetch timeout');
        });

        if (response.statusCode == 200) {
          final users = (jsonDecode(response.body) as List)
              .map((j) => User.fromJson(j))
              .toList();

          // Fix demo email
          for (final u in users) {
            if (u.email == 'demo@gmail.com') {
              u.email = 'depositolasgrutas@gmail.com';
            }
          }

          // Guardar en Firestore
          await _fs.upsertUsers(users);

          User? loggedUser;
          try {
            if (email == 'demo@gmail.com') {
              loggedUser = users.firstWhere(
                  (u) => u.email == 'depositolasgrutas@gmail.com');
            } else {
              loggedUser = users.firstWhere((u) => u.email == email);
            }
          } catch (_) {
            loggedUser = User.currencyUser;
            if (loggedUser != null) await _fs.upsertUser(loggedUser);
          }

          if (loggedUser != null) {
            User.setCurrencyUser(loggedUser);
            loginCubit.emit(LoginState(
              isLogin: true,
              userToken: token,
              user: loggedUser,
              isPreference: false,
            ));
          }

          return users;
        }
        return null;
      } finally {
        client.close();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchVariaciones(String token) async {
    try {
      int currentPage = 1;
      bool hasMorePages = true;
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId = User.currencyUser?.id.toString();

      if (comercioId == null) {
        throw Exception('comercioId no disponible');
      }

      final idBusqueda =
          (comercioId == '1') ? (sucursalId ?? comercioId) : comercioId;

      final oldComercioId = await _getLastUsedComercioId();
      if (oldComercioId != null && oldComercioId != idBusqueda) {
        await _fs.clearProductos();
      }
      await _saveCurrentComercioId(idBusqueda);

      while (hasMorePages) {
        final response = await http.get(
          Uri.parse('$apiUrlProductosVer?comercio_id=$idBusqueda&page=$currentPage'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final productoResponse = ProductoResponse.fromJson(data);
          await _fs.upsertProductoResponse(productoResponse);
          hasMorePages = data['next_page_url'] != null;
          currentPage++;
        } else {
          throw Exception('Error API productos: ${response.statusCode}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchClientesMostrador(String token) async {
    try {
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId = User.currencyUser?.id.toString();

      if (comercioId == null) throw Exception('comercioId no disponible');

      final idBusqueda =
          (comercioId == '1') ? (sucursalId ?? comercioId) : comercioId;

      final client = http.Client();
      try {
        final response = await http.get(
          Uri.parse(
              '$apiUrlClienteMostrador?comercio_id=$idBusqueda&casa_central_id=$idBusqueda'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ).timeout(const Duration(seconds: 30), onTimeout: () {
          client.close();
          throw TimeoutException('Clientes fetch timeout');
        });

        if (response.statusCode == 200) {
          final clientes = (jsonDecode(response.body) as List)
              .map((j) => ClientesMostrador.fromJson(j))
              .toList();

          for (final cliente in clientes) {
            await _fs.upsertCliente(cliente);
          }
        } else {
          throw Exception('Error al cargar clientes');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchProductosIvas(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlProductoIva),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final ivas = (jsonDecode(response.body) as List)
          .map((j) => ProductosIvasModel.fromMap(j))
          .toList();
      await _fs.upsertProductosIvas(ivas);
    } else {
      throw Exception('Error al cargar productos IVAs');
    }
  }

  Future<void> fetchCategorias(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlCategoria),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final categorias = (jsonDecode(response.body) as List)
          .map((j) => CategoriaModel.fromJson(j))
          .toList();
      await _fs.upsertCategorias(categorias);
    } else {
      throw Exception('Error al cargar categorías: ${response.statusCode}');
    }
  }

  Future<void> fetchDatosFacturacion(String token) async {
    try {
      final String? comercioId = User.currencyUser?.comercioId;
      final String? userId = User.currencyUser?.id?.toString();

      String idComercioToUse;
      if (comercioId == '1' && userId != null) {
        idComercioToUse = userId;
      } else if (comercioId != null && comercioId.isNotEmpty) {
        idComercioToUse = comercioId;
      } else if (userId != null) {
        idComercioToUse = userId;
      } else {
        throw Exception('No se pudo determinar el comercio_id');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('datos_facturacion_comercio_id', idComercioToUse);

      final response = await http.get(
        Uri.parse(apiUrlDatosFacturacion),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final lista = (jsonDecode(response.body) as List)
            .map((j) => DatosFacturacionModel.fromJson(j))
            .toList();
        await _fs.upsertDatosFacturacionList(lista);
      } else {
        throw Exception(
            'Error al cargar datos de facturación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar datos de facturación: $e');
    }
  }

  Future<void> fetchMetodosPago(String token, {int? comercioIdParam}) async {
    try {
      int idBusqueda;

      if (comercioIdParam != null) {
        idBusqueda = comercioIdParam;
      } else {
        final String? comercioIdStr = User.currencyUser?.comercioId;
        final String? sucursalId = User.currencyUser?.id.toString();

        if (comercioIdStr == null) {
          throw Exception('comercioId no disponible');
        }
        final idBusquedaStr = (comercioIdStr == '1')
            ? (sucursalId ?? comercioIdStr)
            : comercioIdStr;
        idBusqueda = int.parse(idBusquedaStr);
      }

      final response = await http.get(
        Uri.parse('$apiUrlMetodosPago?comercio_id=$idBusqueda'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final providers = jsonDecode(response.body) as List;
        for (final providerJson in providers) {
          await _fs.upsertPaymentProvider(providerJson);
        }
      } else {
        throw Exception(
            'Error al cargar métodos de pago: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar métodos de pago: $e');
    }
  }

  Future<void> _saveCurrentComercioId(String comercioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_used_comercio_id', comercioId);
    } catch (_) {}
  }

  Future<String?> _getLastUsedComercioId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_used_comercio_id');
    } catch (_) {
      return null;
    }
  }
}
