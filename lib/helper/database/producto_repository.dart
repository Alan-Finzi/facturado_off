import 'package:sqflite/sqflite.dart';
import '../../models/Producto_precio_stock.dart';
import '../../models/producto.dart';
import '../../models/productos_ivas_model.dart';
import '../../util/logger.dart';
import '../database_helper.dart';

/// Repositorio específico para operaciones de base de datos relacionadas con productos
class ProductoRepository {
  /// Obtiene una referencia a la base de datos principal
  Future<Database> get database async => await DatabaseHelper.instance.database;

  /// Obtiene todos los productos de la base de datos
  Future<List<ProductoModel>> getProductos() async {
    try {
      const cacheKey = 'all_productos';
      
      // Verificar si existe en caché
      final cachedResult = DatabaseHelper.instance._getCachedResult(cacheKey);
      if (cachedResult != null) {
        log.d('ProductoRepository', 'Usando productos en caché');
        return cachedResult as List<ProductoModel>;
      }
      
      final db = await database;
      final maps = await db.query('productos');
      final result = maps.map((map) => ProductoModel.fromMap(map)).toList();
      
      // Guardar en caché
      DatabaseHelper.instance._cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      log.e('ProductoRepository', 'Error al obtener productos', e);
      return [];
    }
  }

  /// Obtiene un producto por su ID
  Future<ProductoModel?> getProductoById(int id) async {
    try {
      final db = await database;
      final maps = await db.query('productos', where: 'id = ?', whereArgs: [id]);
      return maps.isNotEmpty ? ProductoModel.fromMap(maps.first) : null;
    } catch (e) {
      log.e('ProductoRepository', 'Error al obtener producto por ID: $id', e);
      return null;
    }
  }

  /// Inserta o actualiza un producto
  Future<void> insertProducto(ProductoModel producto) async {
    try {
      final db = await database;
      await db.insert('productos', producto.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      log.i('ProductoRepository', 'Producto insertado: ${producto.id}');
    } catch (e) {
      log.e('ProductoRepository', 'Error al insertar producto', e);
      throw e;
    }
  }

  /// Inserta o actualiza una lista de productos
  Future<void> insertOrUpdateProductos(List<ProductoModel> productos) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (var producto in productos) {
          await txn.insert(
            'productos',
            producto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      log.i('ProductoRepository', '${productos.length} productos insertados/actualizados');
    } catch (e) {
      log.e('ProductoRepository', 'Error al insertar/actualizar productos', e);
      throw e;
    }
  }
  
  /// Obtiene productos con precio y stock según lista y sucursal
  Future<List<ProductoConPrecioYStock>> getProductosConPrecioYStock(int listaId, int sucursalId) async {
    try {
      final db = await database;
      
      final cacheKey = 'productos_precio_stock_$listaId\_$sucursalId';
      final cachedResult = DatabaseHelper.instance._getCachedResult(cacheKey);
      if (cachedResult != null) {
        return cachedResult as List<ProductoConPrecioYStock>;
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
      p.barcode AS barcode,
      p.id AS productId,
      p.name AS productName,
      p.tipo_producto AS productType,
      pss.stock AS stock,
      plp.precio_lista AS precioLista,
      c.name AS categoryName  
      FROM 
          productos p
      INNER JOIN 
          productos_stock_sucursales pss ON p.id = pss.product_id
      INNER JOIN 
          productos_lista_precios plp ON p.id = plp.product_id
      INNER JOIN
          categorias c ON p.category_id = c.id
      WHERE 
          pss.sucursal_id = ? 
          AND plp.lista_id = ?  
          AND pss.stock > 0
      ''', [sucursalId, listaId]);

      final result = List.generate(maps.length, (i) {
        final map = maps[i];
        return ProductoConPrecioYStock(
          producto: ProductoModel(
            id: map['productId'],
            name: map['productName'],
            tipoProducto: map['productType'],
            barcode:  map['barcode']
          ),
          precioLista: map['precioLista'] as double?,
          stock: map['stock'] is int
              ? (map['stock'] as int).toDouble()
              : map['stock'] is double
              ? map['stock'] as double
              : null,
          iva: null,
          categoria: map['categoryName']
        );
      });
      
      // Guardar en caché
      DatabaseHelper.instance._cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      log.e('ProductoRepository', 'Error al obtener productos con precio y stock', e);
      return [];
    }
  }
  
  /// Obtiene todos los valores de IVA para productos
  Future<List<ProductosIvasModel>> getProductosIvas() async {
    try {
      final db = await database;
      const cacheKey = 'productos_ivas';
      
      // Verificar si existe en caché
      final cachedResult = DatabaseHelper.instance._getCachedResult(cacheKey);
      if (cachedResult != null) {
        return cachedResult as List<ProductosIvasModel>;
      }
      
      final List<Map<String, dynamic>> maps = await db.query('productos_ivas');
      final result = List.generate(maps.length, (i) => ProductosIvasModel.fromMap(maps[i]));
      
      // Guardar en caché
      DatabaseHelper.instance._cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      log.e('ProductoRepository', 'Error al obtener productos IVAs', e);
      return [];
    }
  }
}