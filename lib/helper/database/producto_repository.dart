import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../models/productos_ivas_model.dart';
import '../../services/firestore_service.dart';

class ProductoRepository {
  final _fs = FirestoreService.instance;

  Future<List<ProductoModel>> getProductos() async {
    return await _fs.getProductos();
  }

  Future<ProductoModel?> getProductoById(int id) async {
    try {
      final all = await _fs.getProductos();
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> insertProducto(ProductoModel producto) async {}

  Future<void> insertOrUpdateProductos(List<ProductoModel> productos) async {}

  Future<List<ProductoConPrecioYStock>> getProductosConPrecioYStock(
      int listaId, int sucursalId) async {
    return await _fs.getProductosConPrecioYStock(
        sucursalId: sucursalId, listaId: listaId);
  }

  Future<List<ProductosIvasModel>> getProductosIvas() async {
    return await _fs.getProductosIvas();
  }
}
