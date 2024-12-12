import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../bloc/cubit_login/login_cubit.dart';
import '../helper/database_helper.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';


class ApiServices{

  final String apiUrlUser = 'https://api.flamincoapp.com.ar/api/users';
  final String apiUrlClienteMostrador = 'https://api.flamincoapp.com.ar/api/cliente-mostradors';
  final String apiUrlLogin = 'https://api.flamincoapp.com.ar/api/login';
  final String apiUrlProducto= 'https://api.flamincoapp.com.ar/api/products';
  final  String apiUrlProductoIva = 'https://api.flamincoapp.com.ar/api/producto-ivas';
  final  String apiUrlProductoListaPrecios = 'https://api.flamincoapp.com.ar/api/producto-lista-precios';
  final  String apiUrlProductoStockSucursals = 'https://api.flamincoapp.com.ar/api/producto-stock-sucursals';
  final  String apiUrlListaPrecios = 'https://api.flamincoapp.com.ar/api/lista-precios';
  final  String apiUrlCategoria = 'https://api.flamincoapp.com.ar/api/categories';
  final  String apiUrlDatosFacturacion = 'https://api.flamincoapp.com.ar/api/dato-facturacions';


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


  Future<List<User>?> fetchUsersData(String token,String email,  LoginCubit loginCubit) async {

    try {
      final response = await http.get(Uri.parse(apiUrlUser),
        headers: {
          'Authorization': 'Bearer $token', // Pasamos el token en el header
          'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
        },
      );

      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        List<dynamic> jsonList = jsonDecode(response.body);

        // Convertir cada elemento del array JSON en un objeto User
        List<User> users = jsonList.map((json) => User.fromJson(json)).toList();
        for(var user in users){
          await DatabaseHelper.instance.insertUser(user);
        }
        // Buscar el usuario logueado por email
        User? loggedUser;

        try {
          loggedUser = users.firstWhere((user) => user.email == email);
          print('Usuario encontrado: ${loggedUser.email}');
        } catch (e) {
          print('Error: No se encontró ningún usuario con el email: $email. Detalle: $e');
          loggedUser = null; // Opcional, si necesitas un valor nulo para manejarlo luego
        }

        // Emit the state with the logged user
        loginCubit.emit(LoginState(
          isLogin: true,
          userToken: token,
          user: loggedUser,
          isPreference: false,
          // Set the logged user
        ));

        User.setCurrencyUser(loggedUser!);


        return users;
      } else {
        // Manejar errores de respuesta
        print('Error al obtener los datos de los usuarios: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Manejar errores de la solicitud
      print('Error de solicitud HTTP: $e');
      return null;
    }
  }


// api
  Future<void> fetchProductos(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlProducto),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aquí haces el mapeo correcto a tu modelo, por ejemplo ProductoModel
      List<ProductoModel> productos = data.map((json) => ProductoModel.fromMap(json)).toList();

      await DatabaseHelper.instance.insertOrUpdateProductos(productos);
    } else {
      throw Exception('Error al cargar los datos de la API');
    }
  }



  // Función para obtener clientes de la API y guardarlos en la base de datos
  Future<void> fetchClientesMostrador(String token) async {
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

      for (var cliente in clientes) {
        await DatabaseHelper.instance.insertCliente(cliente);
      }
    } else {
      throw Exception('Error al cargar los datos de cliente mostrador');
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


// api
  Future<void> fetchProductosListaPrecio(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlProductoListaPrecios),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aquí haces el mapeo correcto a tu modelo, por ejemplo ProductoModel
      List<ProductosListaPreciosModel> productosListaPreciosModel = data.map((json) => ProductosListaPreciosModel.fromMap(json)).toList();
      await DatabaseHelper.instance.insertProductosListasPrecios(productosListaPreciosModel);

    } else {
      throw Exception('Error al cargar los datos de la API');
    }
  }

// api
  Future<void> fetchProductosStockSucursals(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlProductoStockSucursals),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aquí haces el mapeo correcto a tu modelo, por ejemplo ProductoModel
      List<ProductosStockSucursalesModel> productosStockSucursalesModel = data.map((json) => ProductosStockSucursalesModel.fromMap(json)).toList();
      await DatabaseHelper.instance.insertProductosStockSucursales(productosStockSucursalesModel);

    } else {
      throw Exception('Error al cargar los datos de la API');
    }
  }


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

  // api
  Future<void> fetchListaPrecio(String token) async {
    final response = await http.get(
      Uri.parse(apiUrlListaPrecios),
      headers: {
        'Authorization': 'Bearer $token', // Pasamos el token en el header
        'Content-Type': 'application/json', // Este es opcional, dependiendo de la API
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Aquí haces el mapeo correcto a tu modelo, por ejemplo ProductoModel
      List<ListaPreciosModel> listaPreciosModel = data.map((json) => ListaPreciosModel.fromMap(json)).toList();
      await DatabaseHelper.instance.insertListaPrecios(listaPreciosModel);

    } else {
      throw Exception('Error al cargar los datos de la API');
    }
  }

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
       // List<DatosFacturacionModel> datosFacturacion = data.map((json) => DatosFacturacionModel.fromMap(json)).toList();

        // Insertar o actualizar los datos en la base de datos
       // await DatabaseHelper.instance.insertOrUpdateDatosFacturacion(datosFacturacion);
      } else {
        throw Exception('Error al cargar los datos de facturación. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en fetchDatosFacturacion: $e');
      throw Exception('Error al cargar los datos de facturación.');
    }
  }

}
