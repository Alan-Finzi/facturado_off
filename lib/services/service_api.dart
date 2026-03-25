import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../helper/database_helper.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/datos_facturacion_model.dart';
import '../models/lista_precio_model.dart';
import '../models/payment_method.dart';
import '../models/payment_provider.dart';
import '../models/producto.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_maestro.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/sync_queue.dart';
import '../models/user.dart';


class ApiServices{

  final String apiUrlUser = 'https://api.flamincoapp.com.ar/api/users';
  final String apiUrlClienteMostrador = 'https://api.flamincoapp.com.ar/api/clientes';
  final String apiUrlLogin = 'https://api.flamincoapp.com.ar/api/login';
  final String apiUrlProductosVer = 'https://api.flamincoapp.com.ar/api/productos-ver'; // Principal API para productos
  final String apiUrlProductoIva = 'https://api.flamincoapp.com.ar/api/producto-ivas';
  final String apiUrlDatosFacturacion = 'https://api.flamincoapp.com.ar/api/dato-facturacions';
  final String apiUrlCategoria = 'https://api.flamincoapp.com.ar/api/categories';
  final String apiUrlMetodosPago = 'https://api.flamincoapp.com.ar/api/metodos-pago';

  // APIs que serán eliminadas/reemplazadas por apiUrlProductosVer
  // final String apiUrlProducto = 'https://api.flamincoapp.com.ar/api/products';
  // final String apiUrlProductoListaPrecios = 'https://api.flamincoapp.com.ar/api/producto-lista-precios';
  // final String apiUrlProductoStockSucursals = 'https://api.flamincoapp.com.ar/api/producto-stock-sucursals';
  // final String apiUrlListaPrecios = 'https://api.flamincoapp.com.ar/api/lista-precios';


  late  String tokenUser = '';

  Future<void> _insertUserBatch(List<User> userBatch) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (var user in userBatch) {
        if(user.email == "demo@gmail.com") {
          user.email = "depositolasgrutas@gmail.com";
        }

        Map<String, dynamic> userMap = user.toJson();
        await txn.insert(
          'users',
          userMap,
          conflictAlgorithm: ConflictAlgorithm.replace
        );
      }
    });
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      // Crear la URL para el endpoint de login
      final Uri url = Uri.parse(apiUrlLogin);

      // Crear el cuerpo de la solicitud (JSON)
      final Map<String, String> body = {
        'email': email,
        'password': password,
      };

      // Crear un cliente con timeout explícito
      final client = http.Client();
      try {
        // Realizar la solicitud POST con el cuerpo en formato JSON y timeout
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(
          const Duration(seconds: 30), // Timeout de 30 segundos para móviles y desktop
          onTimeout: () {
            client.close();
            throw TimeoutException('La solicitud de login ha tardado demasiado');
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          final String? token = jsonResponse['token'] as String?;
          if (token == null) return null;
          tokenUser = token;

          // Intentar extraer datos del usuario si la API los devuelve en el login
          User? userFromResponse;
          try {
            if (jsonResponse.containsKey('user') && jsonResponse['user'] is Map<String, dynamic>) {
              userFromResponse = User.fromJson(jsonResponse['user'] as Map<String, dynamic>);
            }
          } catch (e) {
            // Usuario no pudo parsearse del login response
          }

          return {'token': token, 'user': userFromResponse};
        } else {
          return null;
        }
      } finally {
        // Siempre cerrar el cliente
        client.close();
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<User>?> fetchUsersData(String token, String email, LoginCubit loginCubit) async {
    try {
      // comercioId y sucursal vienen del login API (seteados en User.currencyUser por login_cubit)
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId = User.currencyUser?.sucursal?.toString() ?? User.currencyUser?.id?.toString();

      if (comercioId == null) {
        throw Exception('comercioId no disponible: el login API no devolvió datos del usuario');
      }

      final String idBusqueda = (comercioId == "1") ? (sucursalId ?? comercioId) : comercioId;
      final Uri apiUrl = Uri.parse('$apiUrlUser?comercio_id=$idBusqueda');

      // Crear un cliente con timeout explícito
      final client = http.Client();
      try {
        final response = await http.get(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 30), // Timeout de 30 segundos
          onTimeout: () {
            client.close();
            throw TimeoutException('La solicitud de usuarios ha tardado demasiado');
          },
        );

        if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        List<User> users = jsonList.map((json) => User.fromJson(json)).toList();

        final int batchSize = 50;
        List<List<User>> userBatches = [];

        for (int i = 0; i < users.length; i += batchSize) {
          final end = (i + batchSize < users.length) ? i + batchSize : users.length;
          userBatches.add(users.sublist(i, end));
        }

        await Future.wait(
          userBatches.map((batch) => _insertUserBatch(batch))
        );

        // Buscar el usuario logueado por email
        User? loggedUser;
        try {
          // Usar el email proporcionado, con una consideración especial
          // para el caso demo si la lista de usuarios contiene la dirección hardcodeada
          if (email == "demo@gmail.com") {
            try {
              loggedUser = users.firstWhere((user) =>
                user.email == "depositolasgrutas@gmail.com");
            } catch (e) {
              loggedUser = users.firstWhere((user) => user.email == email);
            }
          } else {
            loggedUser = users.firstWhere((user) => user.email == email);
          }
        } catch (e) {
          if (User.currencyUser != null) {
            loggedUser = User.currencyUser!;
            await _insertUserBatch([loggedUser]);
          } else {
            throw Exception('Usuario "$email" no encontrado en la API y no hay datos del login disponibles');
          }
        }

        // Primero setear en memoria, luego emitir el estado del cubit
        User.setCurrencyUser(loggedUser);

        loginCubit.emit(LoginState(
          isLogin: true,
          userToken: token,
          user: loggedUser,
          isPreference: false,
        ));

        return users;
      } else {
        return null;
      }
      } finally {
        // Siempre cerrar el cliente HTTP
        client.close();
      }
    } catch (e) {
      rethrow;
    }
  }


// Método eliminado - Reemplazado por fetchVariaciones
  // Future<void> fetchProductos(String token) async { ... }


  // api
  Future<void> fetchVariaciones(String token) async {
    try {
      int currentPage = 1; // Página inicial
      bool hasMorePages = true; // Indicador para continuar con la paginación
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId = User.currencyUser?.id.toString();

      if (comercioId == null) {
        throw Exception('No se pudo determinar el comercio_id del usuario para sincronizar productos');
      }

      final String idBusqueda = (comercioId == "1") ? (sucursalId ?? comercioId) : comercioId;

      // Lógica para detectar cambio de comercio
      final oldComercioId = await _getLastUsedComercioId();
      if (oldComercioId != null && oldComercioId != idBusqueda) {
        await DatabaseHelper.instance.clearProductsData();
      }

      // Guardar el comercio actual para futuras comparaciones
      await _saveCurrentComercioId(idBusqueda);

      while (hasMorePages) {
        final Uri apiUrl = Uri.parse('${apiUrlProductosVer}?comercio_id=$idBusqueda&page=$currentPage');

        final response = await http.get(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final ProductoResponse productoResponse = ProductoResponse.fromJson(responseData);

          try {
            await DatabaseHelper.instance.insertProductoResponse(productoResponse);
          } catch (e) {
            // Error al insertar página de productos
          }

          hasMorePages = responseData['next_page_url'] != null;
          currentPage++;
        } else {
          throw Exception('Error al cargar los datos de la API. Código: ${response.statusCode}');
        }
      }

    } catch (e) {
      rethrow;
    }
  }


  // Función para obtener clientes de la API y guardarlos en la base de datos
  Future<void> fetchClientesMostrador(String token) async {
    try {
      // Intentar obtener el ID de comercio del usuario actual si está disponible
      final String? comercioId = User.currencyUser?.comercioId;
      final String? sucursalId = User.currencyUser?.id.toString();

      // comercioId debe estar disponible en este punto (fetchUsersData ya lo estableció)
      if (comercioId == null) {
        throw Exception('No se pudo determinar el comercio_id para obtener clientes');
      }
      final String idBusqueda = (comercioId == "1") ? (sucursalId ?? comercioId) : comercioId;

      // Construir la URL con ambos parámetros de comercio_id y casa_central_id
      final Uri apiUrl = Uri.parse('${apiUrlClienteMostrador}?comercio_id=$idBusqueda&casa_central_id=$idBusqueda');

      // Crear un cliente con timeout explícito
      final client = http.Client();
      try {
        final response = await http.get(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 30), // Timeout de 30 segundos
          onTimeout: () {
            client.close();
            throw TimeoutException('La solicitud de clientes ha tardado demasiado');
          },
        );

        if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<ClientesMostrador> clientes = data.map((json) => ClientesMostrador.fromJson(json)).toList();

        // Insertar clientes en lote para mayor eficiencia
        for (var cliente in clientes) {
          await DatabaseHelper.instance.insertCliente(cliente);
        }
        
      } else {
        throw Exception('Error al cargar los datos de cliente mostrador');
      }
      } finally {
        // Siempre cerrar el cliente HTTP
        client.close();
      }
    } catch (e) {
      rethrow;
    }
  }

// api
  Future<void> fetchProductosIvas(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlProductoIva),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aquí haces el mapeo correcto a tu modelo, por ejemplo ProductoModel
      List<ProductosIvasModel> productosIvasModel = data.map((json) => ProductosIvasModel.fromMap(json)).toList();

      await DatabaseHelper.instance.insertProductosIvas(productosIvasModel);
    } else {
      throw Exception('Error al cargar los datos de la API');
    }
  }


// Método eliminado - Reemplazado por fetchVariaciones
  // Future<void> fetchProductosListaPrecio(String token) async { ... }

// Método eliminado - Reemplazado por fetchVariaciones
  // Future<void> fetchProductosStockSucursals(String token) async { ... }


  Future<void> fetchCategorias(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlCategoria),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Mapeo correcto a tu modelo CategoriaModel
      List<CategoriaModel> categorias = data.map((json) => CategoriaModel.fromJson(json)).toList();

      // Aquí puedes guardar las categorías en la base de datos o usarlas como necesites
      await DatabaseHelper.instance.insertCategorias(categorias);

    } else {
      throw Exception('Error al cargar los datos de la API: ${response.statusCode}');
    }
  }

  // Método eliminado - Reemplazado por fetchVariaciones
  // Future<void> fetchListaPrecio(String token) async { ... }

  Future<void> fetchDatosFacturacion(String token) async {
    try {
      // Intentar obtener el ID de comercio del usuario actual
      final String? comercioId = User.currencyUser?.comercioId;
      final String? userId = User.currencyUser?.id?.toString();

      // Determinar cuál ID usar
      String idComercioToUse;
      if (comercioId == "1" && userId != null) {
        idComercioToUse = userId;
      } else if (comercioId != null && comercioId.isNotEmpty) {
        idComercioToUse = comercioId;
      } else if (userId != null) {
        idComercioToUse = userId;
      } else {
        throw Exception('No se pudo determinar el comercio_id para datos de facturación: User.currencyUser no tiene comercioId ni id');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('datos_facturacion_comercio_id', idComercioToUse);

      final response = await http.get(
        Uri.parse(apiUrlDatosFacturacion),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Mapear la respuesta al modelo DatosFacturacionModel
        List<DatosFacturacionModel> datosFacturacion = data.map((json) => DatosFacturacionModel.fromJson(json)).toList();

        // Insertar o actualizar los datos en la base de datos
        await DatabaseHelper.instance.insertDatosFacturacionList(datosFacturacion);
      } else {
        throw Exception('Error al cargar los datos de facturación. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar los datos de facturación.');
    }
  }

  /// Consulta a la API de métodos de pago y almacena los datos localmente
  ///
  /// Esta función recupera todos los métodos de pago desde la API, los convierte
  /// a modelos y los guarda en la base de datos local. También agrega cada método
  /// a la cola de sincronización para garantizar consistencia con el servidor.
  Future<void> fetchMetodosPago(String token, {int? comercioIdParam}) async {
    try {
      // Determinar el ID a usar (parámetro proporcionado o del usuario actual)
      int idBusqueda;

      if (comercioIdParam != null) {
        // Usar el parámetro proporcionado si está disponible
        idBusqueda = comercioIdParam;
      } else {
        // Intentar obtener el ID de comercio del usuario actual
        final String? comercioIdStr = User.currencyUser?.comercioId;
        final String? sucursalId = User.currencyUser?.id.toString();

        // comercioId debe estar disponible en este punto (fetchUsersData ya lo estableció)
        if (comercioIdStr == null) {
          throw Exception('No se pudo determinar el comercio_id para obtener métodos de pago');
        }
        final String idBusquedaStr = (comercioIdStr == "1") ? (sucursalId ?? comercioIdStr) : comercioIdStr;
        idBusqueda = int.parse(idBusquedaStr);
      }

      // Construir la URL con el parámetro comercio_id
      final Uri url = Uri.parse('$apiUrlMetodosPago?comercio_id=$idBusqueda');

      // Realizar la consulta a la API
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Verificar si la respuesta fue exitosa (código 200)
      if (response.statusCode == 200) {
        final responseBody = response.body;

        List<dynamic> providersJson;
        try {
          providersJson = jsonDecode(responseBody) as List<dynamic>;
        } catch (e) {
          throw Exception('Error al procesar la respuesta de métodos de pago: ${e.toString()}');
        }

        for (var providerJson in providersJson) {
          try {
            await DatabaseHelper.instance.insertPaymentProvider(providerJson);
          } catch (e) {
            // Error al insertar proveedor individual
          }
        }
      } else {
        throw Exception('Error al cargar los métodos de pago. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar los métodos de pago: ${e.toString()}');
    }
  }

  void _debugPaymentProvider(dynamic provider) {}

  Future<void> _saveCurrentComercioId(String comercioId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_used_comercio_id', comercioId);
    } catch (e) {
      // Error al guardar comercioId
    }
  }

  Future<String?> _getLastUsedComercioId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_used_comercio_id');
    } catch (e) {
      return null;
    }
  }
}
