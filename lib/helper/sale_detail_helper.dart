import 'package:sqflite/sqflite.dart';
import '../models/sales/sale_detail.dart';
import '../models/sales/sales_queries.dart';
import 'database_helper.dart';

/// Clase que proporciona métodos para gestionar los detalles de venta en la base de datos
class SaleDetailHelper {
  final DatabaseHelper _databaseHelper;

  /// Constructor
  SaleDetailHelper({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Obtener la base de datos
  Future<Database> get database async => await _databaseHelper.database;

  /// Agregar un detalle a una venta existente
  Future<int> addSaleDetail(SaleDetail detalle) async {
    final db = await database;

    return await db.insert(
      'ventas_detalle',
      detalle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualizar un detalle existente
  Future<int> updateSaleDetail(SaleDetail detalle) async {
    final db = await database;

    if (detalle.id == null) {
      throw Exception('No se puede actualizar un detalle sin ID');
    }

    return await db.update(
      'ventas_detalle',
      detalle.toMap(),
      where: 'id = ?',
      whereArgs: [detalle.id],
    );
  }

  /// Obtener un detalle por su ID
  Future<SaleDetail?> getSaleDetailById(int id) async {
    final db = await database;

    final maps = await db.query(
      'ventas_detalle',
      where: 'id = ? AND eliminado = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return SaleDetail.fromMap(maps.first);
  }

  /// Obtener todos los detalles de una venta
  Future<List<SaleDetail>> getSaleDetailsByVentaId(int ventaId) async {
    final db = await database;

    final maps = await db.rawQuery(
      SalesQueries.getVentaDetalleByVentaId,
      [ventaId],
    );

    return maps.map((map) => SaleDetail.fromMap(map)).toList();
  }

  /// Borrado lógico de un detalle específico
  Future<int> softDeleteSaleDetail(int detalleId) async {
    final db = await database;

    final ahora = DateTime.now().toIso8601String();

    return await db.update(
      'ventas_detalle',
      {
        'eliminado': 1,
        'updated_at': ahora,
      },
      where: 'id = ?',
      whereArgs: [detalleId],
    );
  }

  /// Borrado físico de un detalle específico
  Future<int> hardDeleteSaleDetail(int detalleId) async {
    final db = await database;

    return await db.delete(
      'ventas_detalle',
      where: 'id = ?',
      whereArgs: [detalleId],
    );
  }

  /// Marcar un detalle como sincronizado
  Future<int> markSaleDetailAsSynchronized(int detalleId) async {
    final db = await database;

    final ahora = DateTime.now().toIso8601String();

    return await db.update(
      'ventas_detalle',
      {
        'sincronizado': 1,
        'updated_at': ahora,
      },
      where: 'id = ?',
      whereArgs: [detalleId],
    );
  }

  /// Obtener detalles no sincronizados
  Future<List<SaleDetail>> getUnsynchronizedSaleDetails() async {
    final db = await database;

    final maps = await db.query(
      'ventas_detalle',
      where: 'sincronizado = 0 AND eliminado = 0',
    );

    return maps.map((map) => SaleDetail.fromMap(map)).toList();
  }

  /// Calcular subtotal de una venta
  Future<double> calculateSaleSubtotal(int ventaId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT SUM(subtotal) as total FROM ventas_detalle WHERE venta_id = ? AND eliminado = 0',
      [ventaId],
    );

    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }

  /// Calcular total de IVA de una venta
  Future<double> calculateSaleIva(int ventaId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT SUM(monto_iva) as total FROM ventas_detalle WHERE venta_id = ? AND eliminado = 0',
      [ventaId],
    );

    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }

  /// Calcular total final de una venta
  Future<double> calculateSaleTotal(int ventaId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM ventas_detalle WHERE venta_id = ? AND eliminado = 0',
      [ventaId],
    );

    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }

  /// Calcular total de descuentos de una venta
  Future<double> calculateSaleDiscounts(int ventaId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT SUM(monto_descuento) as total FROM ventas_detalle WHERE venta_id = ? AND eliminado = 0',
      [ventaId],
    );

    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }

  /// Actualizar totales de una venta basado en sus detalles
  Future<void> updateSaleTotals(int ventaId) async {
    final db = await database;

    // Calcular los totales
    final subtotal = await calculateSaleSubtotal(ventaId);
    final iva = await calculateSaleIva(ventaId);
    final total = await calculateSaleTotal(ventaId);
    final descuento = await calculateSaleDiscounts(ventaId);

    // Actualizar la venta
    await db.update(
      'ventas',
      {
        'subtotal': subtotal,
        'iva': iva,
        'total': total,
        'descuento': descuento,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [ventaId],
    );
  }

  /// Obtener la cantidad total de un producto vendido en un período
  Future<double> getProductSoldQuantity(int productoId, DateTime inicio, DateTime fin) async {
    final db = await database;

    // Formato para fechas ISO8601
    final inicioString = inicio.toIso8601String();
    final finString = fin.toIso8601String();

    final result = await db.rawQuery('''
      SELECT SUM(d.cantidad) as total
      FROM ventas_detalle d
      JOIN ventas v ON d.venta_id = v.id
      WHERE d.producto_id = ?
      AND v.fecha BETWEEN ? AND ?
      AND d.eliminado = 0
      AND v.eliminado = 0
    ''', [productoId, inicioString, finString]);

    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }

  /// Obtener los productos más vendidos en un período
  Future<List<Map<String, dynamic>>> getTopSellingProducts(
    DateTime inicio,
    DateTime fin,
    {int limit = 10}
  ) async {
    final db = await database;

    // Formato para fechas ISO8601
    final inicioString = inicio.toIso8601String();
    final finString = fin.toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        d.producto_id,
        d.nombre_producto,
        SUM(d.cantidad) as cantidad_total,
        SUM(d.total) as monto_total,
        d.categoria_nombre
      FROM ventas_detalle d
      JOIN ventas v ON d.venta_id = v.id
      WHERE v.fecha BETWEEN ? AND ?
      AND d.eliminado = 0
      AND v.eliminado = 0
      GROUP BY d.producto_id
      ORDER BY cantidad_total DESC
      LIMIT ?
    ''', [inicioString, finString, limit]);

    return result;
  }
}