import 'package:facturador_offline/models/producto.dart';
import 'package:sqflite/sqflite.dart';


import '../helper/database_helper.dart';
import '../models/Producto_precio_stock.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<void> addUser(User user) async {
    if(user.username != null && user.password != null){
      await _dbHelper.insertUser(user);
    }

  }
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
    final existingUser = await _dbHelper.getUser(user.username!);
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

  Future<List<ProductoConPrecioYStock>> addQueryProductoCatalogo({required int sucursalId,required int listaId}) async {
    return await _dbHelper.getProductosConPrecioYStockQuery(sucursalId: sucursalId,listaId: listaId);
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

  Future<List<ProductosStockSucursalesModel>> fetchProductosStockSucursales({required int sucursal}) async {
    return await _dbHelper.getProductosStockSucursales(sucursalId: sucursal);
  }

  // Métodos relacionados con la tabla productos_ivas
  Future<void> addProductoIva(ProductosIvasModel productoIva) async {
    await _dbHelper.insertProductoIva(productoIva);
  }

  Future<List<ProductosIvasModel>> fetchProductosIvas() async {
    return await _dbHelper.getProductosIvas();
  }

  // Método para obtener la lista de productos en una lista de precios desde la base de datos
  Future<void> addProductoListaPrecio(ProductosListaPreciosModel productoListaPrecio) async {
    await _dbHelper.insertProductosListaPrecio(productoListaPrecio);
  }

  // Método para obtener los productos de una lista de precios específica
  Future<List<ProductosListaPreciosModel>> fetchProductosListaPrecios(int listaId) async {
    return await _dbHelper.getProductosListaPrecios(listaId);
  }

  Future<List<ProductoConPrecioYStock>> fetchProductosConPrecioYStock(
      {required int listaId, required int sucursalUsuario}) async {
    final db = await _dbHelper.database;
    // Query para obtener los productos con sus precios, stock y IVA
    final result = await db.rawQuery('''
  SELECT 
    p.producto_id,
    p.name,
    p.barcode,
    p.tipo_producto,
    plp.precio_lista,
    pss.stock,
    pi.iva 
  FROM productos p
  INNER JOIN productos_lista_precios plp ON p.producto_id = plp.product_id
  INNER JOIN productos_stock_sucursales pss ON p.producto_id = pss.product_id
  LEFT JOIN productos_ivas pi ON p.producto_id = pi.product_id 
  WHERE plp.lista_id = ?
  AND pi.sucursal_id = ?
''', [listaId, sucursalUsuario]);

    print('Resultados de la consulta principal: $result');

    return result.map((map) => ProductoConPrecioYStock.fromMap(map)).toList();
  }
  Future<List<Map<String, dynamic>>> getProductosYStock(int listaId, int sucursalId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
  SELECT 
      p.id AS productId,
      p.name AS productName,
      p.tipo_producto AS productType,
      pss.stock AS stock,
      p.barcode AS productBarcode
    FROM productos p
    INNER JOIN productos_stock_sucursales pss ON p.id = pss.product_id
  ''', [listaId, sucursalId]);

    print('Lista ID: $listaId, Sucursal ID: $sucursalId');
    return result;
  }



}