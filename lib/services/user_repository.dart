import 'package:facturador_offline/models/producto.dart';
import 'package:sqflite/sqflite.dart';


import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Métodos relacionados con la tabla users
  Future<User?> authenticateUser(String username, String password) async {
    final user = await _dbHelper.getUser(username);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }
  Future<User?> authenticate(User user) async {
    // Suponiendo que el objeto `user` tiene un campo `username` y `password`
    final existingUser = await _dbHelper.getUser(user.username);
    if (existingUser != null && existingUser.password == user.password) {
      return existingUser;
    }
    return null;
  }

  Future<User?> fetchUserByUsername(String username) async {
    return await _dbHelper.getUser(username);
  }

  Future<List<User>> getAllUsers() async {
    return await _dbHelper.getUsers();
  }

  // Métodos relacionados con la tabla productos
  Future<void> addProducto(ProductoModel producto) async {
    await _dbHelper.insertProducto(producto);
  }

  Future<List<ProductoModel>> fetchProductos() async {
    return await _dbHelper.getProductos();
  }

  // Métodos relacionados con la tabla lista_precios
  Future<void> addListaPrecio(ListaPreciosModel listaPrecio) async {
    await _dbHelper.insertListaPrecio(listaPrecio);
  }

  Future<List<ListaPreciosModel>> fetchListaPrecios() async {
    return await _dbHelper.getListaPrecios();
  }

  Future<void> removeListaPrecio(int id) async {
    await _dbHelper.deleteListaPrecio(id);
  }

  // Métodos relacionados con la tabla Clientes_mostrador
  Future<void> addCliente(ClientesMostrador cliente) async {
    await _dbHelper.insertCliente(cliente);
  }

  Future<void> updateCliente(ClientesMostrador cliente) async {
    await _dbHelper.updateCliente(cliente);
  }

  Future<void> removeCliente(String idCliente) async {
    await _dbHelper.deleteCliente(idCliente);
  }

  Future<List<ClientesMostrador>> fetchClientes() async {
    return await _dbHelper.getClientesDB();
  }

  // Métodos relacionados con la tabla productos_stock_sucursales
  Future<void> addProductoStockSucursal(ProductosStockSucursalesModel productoStockSucursal) async {
    await _dbHelper.insertProductosStockSucursal(productoStockSucursal);
  }

  Future<List<ProductosStockSucursalesModel>> fetchProductosStockSucursales() async {
    return await _dbHelper.getProductosStockSucursales();
  }

  // Métodos relacionados con la tabla productos_ivas
  Future<void> addProductoIva(ProductosIvasModel productoIva) async {
    await _dbHelper.insertProductoIva(productoIva);
  }

  Future<List<ProductosIvasModel>> fetchProductosIvas() async {
    return await _dbHelper.getProductosIvas();
  }
}