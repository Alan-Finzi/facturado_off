import '../models/Producto_precio_stock.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/productos_maestro.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';
import 'firestore_service.dart';

class UserRepository {
  final _fs = FirestoreService.instance;

  Future<void> addUser(User user) async {
    if (user.username != null || user.email != null) {
      await _fs.upsertUser(user);
    }
  }

  Future<User?> authenticateUser(String username, String password) async {
    final user = await _fs.getUserByEmail(username);
    if (user != null && user.password == password) return user;
    return null;
  }

  Future<User?> fetchUserByUsername(String username) async {
    return await _fs.getUserByEmail(username);
  }

  Future<List<User>> getAllUsers() async {
    return await _fs.getUsers();
  }

  Future<List<ProductoModel>> fetchProductos() async {
    return await _fs.getProductos();
  }

  Future<void> addListaPrecio(dynamic listaPrecio) async {}

  Future<List<ProductoConPrecioYStock>> addQueryProductoCatalogo(
      {required int sucursalId, required int listaId}) async {
    return await _fs.getProductosConPrecioYStock(
        sucursalId: sucursalId, listaId: listaId);
  }

  Future<List<Lista>> fetchListaPrecios() async {
    return [];
  }

  Future<void> removeListaPrecio(int id) async {}

  Future<void> addCliente(ClientesMostrador cliente) async {
    await _fs.upsertCliente(cliente);
  }

  Future<void> updateCliente(ClientesMostrador cliente) async {
    await _fs.updateCliente(cliente);
  }

  Future<void> removeCliente(String idCliente) async {
    await _fs.deleteCliente(idCliente);
  }

  Future<List<ClientesMostrador>> fetchClientes() async {
    return await _fs.getClientes();
  }

  Future<void> addProductoStockSucursal(
      ProductosStockSucursalesModel productoStockSucursal) async {}

  Future<List<ProductosStockSucursalesModel>> fetchProductosStockSucursales(
      {required int sucursal}) async {
    return await _fs.getProductosStockSucursales(sucursal);
  }

  Future<void> addProductoIva(ProductosIvasModel productoIva) async {}

  Future<List<ProductosIvasModel>> fetchProductosIvas() async {
    return await _fs.getProductosIvas();
  }

  Future<void> addProductoListaPrecio(
      ProductosListaPreciosModel productoListaPrecio) async {}

  Future<List<ProductosListaPreciosModel>> fetchProductosListaPrecios(
      int listaId) async {
    return await _fs.getProductosListaPrecios(listaId);
  }

  Future<List<ProductoConPrecioYStock>> fetchProductosConPrecioYStock(
      {required int listaId, required int sucursalUsuario}) async {
    return await _fs.getProductosConPrecioYStock(
        sucursalId: sucursalUsuario, listaId: listaId);
  }
}
