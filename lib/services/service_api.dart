import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
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

  final String apiUrlUser = 'https://api.flamincoapp.com.ar/api/users?comercio_id=362';
  final String apiUrlClienteMostrador = 'https://api.flamincoapp.com.ar/api/clientes?casa_central_id=362&comercio_id=362';
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

  Future<String?> loginUser(String email, String password) async {
    try {
      // Crear la URL para el endpoint de login
      final Uri url = Uri.parse(apiUrlLogin);

      // Crear el cuerpo de la solicitud (JSON)
      final Map<String, String> body = {
        'email': email,
        'password': password,
      };

      // Realizar la solicitud POST con el cuerpo en formato JSON
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        tokenUser= jsonResponse['token'];
        // Retornar el token de la respuesta
        return jsonResponse['token'];
      } else {
        // Manejar errores de respuesta
        print('Error al hacer login: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Manejar errores de la solicitud
      print('Error de solicitud HTTP: $e');
      return null;
    }
  }

  Future<List<User>?> fetchUsersData(String token, String email, LoginCubit loginCubit) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrlUser),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);

        List<User> users = jsonList.map((json) => User.fromJson(json)).toList();

        for (var user in users) {
          
          if(user.email == "demo@gmail.com" ){
            user.email = "depositolasgrutas@gmail.com";
          }

          await DatabaseHelper.instance.insertUser(user);
        }

        // Buscar el usuario logueado por email
        User? loggedUser;
        try {


         // loggedUser = users.firstWhere((user) => user.email == email);
          loggedUser = users.firstWhere((user) => user.email == "depositolasgrutas@gmail.com");
        } catch (e) {
          print('Error: No se encontró ningún usuario con el email: $email');
          return null;
        }

        loginCubit.emit(LoginState(
          isLogin: true,
          userToken: token,
          user: loggedUser,
          isPreference: false,
        ));

        User.setCurrencyUser(loggedUser);

        return users;
      } else {
        print('Error al obtener los datos de los usuarios: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error de solicitud HTTP: $e');
      return null;
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

// Determinar si se usa sucursal o comercioId
      final String idBusqueda = (comercioId == "1") ? (sucursalId ?? comercioId!) : comercioId!;

// Construir la URL con el parámetro de comercio_id
      final Uri apiUrl = Uri.parse('${apiUrlProductosVer}?comercio_id=$idBusqueda');
      print('Obteniendo productos desde: $apiUrl');


        final response = await http.get(
          apiUrl, // URL ya contiene los parámetros necesarios
          headers: {
            'Authorization': 'Bearer $token', // Pasamos el token en el header
            'Content-Type': 'application/json', // Opcional según la API
          },
        );

        if (response.statusCode == 200) {
          // Decodificar los datos de la respuesta
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Procesar los datos de la página actual
          final ProductoResponse productoResponse = ProductoResponse.fromJson(responseData);

          // Validamos si alguno de los elementos en `data` cumple con la condición

            try {
              // Insertamos en la base de datos
              await DatabaseHelper.instance.insertProductoResponse(productoResponse);
              print("Inserción completada exitosamente.");

            } catch (e) {
              // Capturamos y mostramos cualquier error durante la inserción
              print("Error al insertar ProductoResponse: $e");
            }


          // Verifica si hay más páginas
          hasMorePages = responseData['next_page_url'] != null;
          currentPage++; // Incrementa para la próxima página
        } else {
          // Manejo de errores
          throw Exception('Error al cargar los datos de la API. Código: ${response.statusCode}');
        }

    } catch (e) {
      print('Error al procesar las variaciones: $e');
    }
  }


  // Función para obtener clientes de la API y guardarlos en la base de datos
  Future<void> fetchClientesMostrador(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrlClienteMostrador),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<ClientesMostrador> clientes = data.map((json) => ClientesMostrador.fromJson(json)).toList();

        // Insertar clientes en lote para mayor eficiencia
        for (var cliente in clientes) {
          await DatabaseHelper.instance.insertCliente(cliente);
        }
        
        print('Clientes sincronizados: ${clientes.length}');
      } else {
        print('Error al cargar clientes: ${response.statusCode}');
        throw Exception('Error al cargar los datos de cliente mostrador');
      }
    } catch (e) {
      print('Error en fetchClientesMostrador: $e');
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
      print('Error en fetchDatosFacturacion: $e');
      throw Exception('Error al cargar los datos de facturación.');
    }
  }

  /// Consulta a la API de métodos de pago y almacena los datos localmente
  ///
  /// Esta función recupera todos los métodos de pago desde la API, los convierte
  /// a modelos y los guarda en la base de datos local. También agrega cada método
  /// a la cola de sincronización para garantizar consistencia con el servidor.
  Future<void> fetchMetodosPago(String token, {int comercioId = 362}) async {
    try {
      // Construir la URL con el parámetro comercio_id
      final Uri url = Uri.parse('$apiUrlMetodosPago?comercio_id=$comercioId');

      // Mostrar mensaje de progreso
      print('Obteniendo métodos de pago desde: $url');

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
        // Decodificar el JSON de la respuesta
        final responseBody = response.body;

        // Log para diagnóstico
        print('Respuesta de API de métodos de pago recibida: ${responseBody.length} caracteres');

        // Intentar decodificar el JSON
        List<dynamic> providersJson;
        try {
          providersJson = jsonDecode(responseBody) as List<dynamic>;

          // Validación extra para diagnóstico
          print('JSON decodificado correctamente. Items: ${providersJson.length}');

          // Mostrar estructura del primer elemento para diagnóstico
          if (providersJson.isNotEmpty) {
            _debugPaymentProvider(providersJson[0]);
          }
        } catch (e) {
          print('Error al decodificar JSON: $e');
          print('Primeros 100 caracteres de la respuesta: ${responseBody.substring(0, min(100, responseBody.length))}');
          throw Exception('Error al procesar la respuesta de métodos de pago: ${e.toString()}');
        }

        // Insertar cada proveedor en la base de datos
        // Este proceso incrementará el progreso de sincronización en 1% por cada proveedor
        for (var providerJson in providersJson) {
          try {
            await DatabaseHelper.instance.insertPaymentProvider(providerJson);
          } catch (e) {
            print('Error al insertar proveedor: $e');
            print('Datos del proveedor con error: $providerJson');
          }
        }

        print('Sincronización de métodos de pago completada (+${providersJson.length}%)');
      } else {
        // Manejo de errores de la API
        print('Error HTTP: ${response.statusCode} - ${response.reasonPhrase}');
        print('Body de respuesta: ${response.body}');
        throw Exception('Error al cargar los métodos de pago. Código: ${response.statusCode}');
      }
    } catch (e) {
      // Capturar cualquier excepción durante el proceso
      print('Error en fetchMetodosPago: $e');
      // Propagar el error para que el llamador pueda manejarlo
      throw Exception('Error al cargar los métodos de pago: ${e.toString()}');
    }
  }

  /// Método de diagnóstico para imprimir la estructura de un proveedor de pago
  void _debugPaymentProvider(dynamic provider) {
    try {
      print('=== Debug de PaymentProvider ===');
      print('ID: ${provider['id']} (${provider['id'].runtimeType})');
      print('Nombre: ${provider['nombre']} (${provider['nombre'].runtimeType})');

      if (provider['metodos_pago'] != null) {
        print('Métodos de pago: ${(provider['metodos_pago'] as List).length}');

        if ((provider['metodos_pago'] as List).isNotEmpty) {
          final metodo = (provider['metodos_pago'] as List)[0];
          print('Primer método - ID: ${metodo['id']} (${metodo['id'].runtimeType})');
          print('Primer método - Nombre: ${metodo['nombre']} (${metodo['nombre'].runtimeType})');
          print('Primer método - Recargo: ${metodo['recargo']} (${metodo['recargo'].runtimeType})');
        }
      } else {
        print('No tiene métodos de pago');
      }
    } catch (e) {
      print('Error en debug de provider: $e');
    }
  }
}
