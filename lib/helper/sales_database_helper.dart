import 'package:sqflite/sqflite.dart';
import '../models/sales/sale.dart';
import '../models/sales/sale_detail.dart';
import '../models/sales/sales_queries.dart';
import 'database_helper.dart';

/// Clase que proporciona métodos para gestionar las ventas en la base de datos
class SalesDatabaseHelper {
  final DatabaseHelper _databaseHelper;

  /// Constructor
  SalesDatabaseHelper({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Obtener la base de datos
  Future<Database> get database async => await _databaseHelper.database;

  /// Guardar una venta completa con sus detalles (transacción)
  Future<int> saveSale(Sale sale) async {
    final db = await database;
    int ventaId;

    // Usar transacción para asegurar consistencia de datos
    await db.transaction((txn) async {
      try {
        // Convertir la venta a un mapa sin los detalles para insertar
        final ventaMap = sale.toMap();

        // Insertar la venta
        ventaId = await txn.insert(
          'ventas',
          ventaMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Si hay detalles, insertarlos
        if (sale.detalles != null && sale.detalles!.isNotEmpty) {
          for (var detalle in sale.detalles!) {
            // Asegurar que el detalle tenga el ID de venta correcto
            final detalleActualizado = detalle.copyWith(ventaId: ventaId);
            await txn.insert(
              'ventas_detalle',
              detalleActualizado.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      } catch (e) {
        print('Error al guardar venta: $e');
        rethrow; // La transacción se revertirá automáticamente
      }
    });

    return ventaId;
  }

  /// Actualizar una venta existente
  Future<int> updateSale(Sale sale) async {
    final db = await database;

    if (sale.id == null) {
      throw Exception('No se puede actualizar una venta sin ID');
    }

    return await db.update(
      'ventas',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  /// Obtener una venta por ID, incluyendo sus detalles
  Future<Sale?> getSaleById(int id) async {
    final db = await database;

    // Obtener la venta
    final ventaMaps = await db.query(
      'ventas',
      where: 'id = ? AND eliminado = 0',
      whereArgs: [id],
    );

    if (ventaMaps.isEmpty) {
      return null;
    }

    // Obtener los detalles de la venta
    final detallesMaps = await db.query(
      'ventas_detalle',
      where: 'venta_id = ? AND eliminado = 0',
      whereArgs: [id],
    );

    // Convertir maps a objetos SaleDetail
    final detalles = detallesMaps.map((map) => SaleDetail.fromMap(map)).toList();

    // Convertir map a objeto Sale
    final venta = Sale.fromMap(ventaMaps.first);

    // Crear una nueva venta con los detalles
    return venta.copyWith(detalles: detalles);
  }

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales() async {
    final db = await database;

    // Obtener todas las ventas
    final ventasMaps = await db.rawQuery(SalesQueries.getAllVentas);

    // Convertir maps a objetos Sale
    final ventas = <Sale>[];
    for (var ventaMap in ventasMaps) {
      final ventaId = ventaMap['id'] as int;

      // Obtener los detalles de cada venta
      final detallesMaps = await db.query(
        'ventas_detalle',
        where: 'venta_id = ? AND eliminado = 0',
        whereArgs: [ventaId],
      );

      // Convertir maps a objetos SaleDetail
      final detalles = detallesMaps.map((map) => SaleDetail.fromMap(map)).toList();

      // Convertir map a objeto Sale y agregar los detalles
      ventas.add(Sale.fromMap(ventaMap).copyWith(detalles: detalles));
    }

    return ventas;
  }

  /// Obtener ventas por cliente
  Future<List<Sale>> getSalesByClientId(int clienteId) async {
    final db = await database;

    // Obtener ventas del cliente
    final ventasMaps = await db.rawQuery(
      SalesQueries.getVentasByClienteId,
      [clienteId],
    );

    // Convertir maps a objetos Sale
    final ventas = <Sale>[];
    for (var ventaMap in ventasMaps) {
      final ventaId = ventaMap['id'] as int;

      // Obtener los detalles de cada venta
      final detallesMaps = await db.query(
        'ventas_detalle',
        where: 'venta_id = ? AND eliminado = 0',
        whereArgs: [ventaId],
      );

      // Convertir maps a objetos SaleDetail
      final detalles = detallesMaps.map((map) => SaleDetail.fromMap(map)).toList();

      // Convertir map a objeto Sale y agregar los detalles
      ventas.add(Sale.fromMap(ventaMap).copyWith(detalles: detalles));
    }

    return ventas;
  }

  /// Obtener ventas por período
  Future<List<Sale>> getSalesByPeriod(DateTime inicio, DateTime fin) async {
    final db = await database;

    // Formato para fechas ISO8601
    final inicioString = inicio.toIso8601String();
    final finString = fin.toIso8601String();

    // Obtener ventas en el período
    final ventasMaps = await db.rawQuery(
      SalesQueries.getVentasByPeriodo,
      [inicioString, finString],
    );

    // Convertir maps a objetos Sale
    final ventas = <Sale>[];
    for (var ventaMap in ventasMaps) {
      final ventaId = ventaMap['id'] as int;

      // Obtener los detalles de cada venta
      final detallesMaps = await db.query(
        'ventas_detalle',
        where: 'venta_id = ? AND eliminado = 0',
        whereArgs: [ventaId],
      );

      // Convertir maps a objetos SaleDetail
      final detalles = detallesMaps.map((map) => SaleDetail.fromMap(map)).toList();

      // Convertir map a objeto Sale y agregar los detalles
      ventas.add(Sale.fromMap(ventaMap).copyWith(detalles: detalles));
    }

    return ventas;
  }

  /// Realizar borrado lógico de una venta y sus detalles
  Future<void> softDeleteSale(int ventaId) async {
    final db = await database;

    // Usar transacción para asegurar consistencia
    await db.transaction((txn) async {
      try {
        final ahora = DateTime.now().toIso8601String();

        // Marcar la venta como eliminada
        await txn.rawUpdate(
          SalesQueries.softDeleteVenta,
          [ahora, ventaId],
        );

        // Marcar los detalles como eliminados
        await txn.rawUpdate(
          SalesQueries.softDeleteVentaDetalleByVentaId,
          [ahora, ventaId],
        );
      } catch (e) {
        print('Error al realizar borrado lógico de venta: $e');
        rethrow;
      }
    });
  }

  /// Realizar borrado físico de una venta y sus detalles
  Future<void> hardDeleteSale(int ventaId) async {
    final db = await database;

    // Usar transacción para asegurar consistencia
    await db.transaction((txn) async {
      try {
        // Eliminar los detalles primero (por restricción de clave foránea)
        await txn.rawDelete(
          SalesQueries.hardDeleteVentaDetalleByVentaId,
          [ventaId],
        );

        // Eliminar la venta
        await txn.rawDelete(
          SalesQueries.hardDeleteVenta,
          [ventaId],
        );
      } catch (e) {
        print('Error al realizar borrado físico de venta: $e');
        rethrow;
      }
    });
  }

  /// Marcar una venta y sus detalles como sincronizados
  Future<void> markSaleAsSynchronized(int ventaId) async {
    final db = await database;

    // Usar transacción para asegurar consistencia
    await db.transaction((txn) async {
      try {
        final ahora = DateTime.now().toIso8601String();

        // Marcar la venta como sincronizada
        await txn.rawUpdate(
          SalesQueries.markVentaAsSincronizada,
          [ahora, ventaId],
        );

        // Marcar los detalles como sincronizados
        await txn.rawUpdate(
          SalesQueries.markVentaDetalleAsSincronizada,
          [ahora, ventaId],
        );
      } catch (e) {
        print('Error al marcar venta como sincronizada: $e');
        rethrow;
      }
    });
  }

  /// Obtener ventas no sincronizadas
  Future<List<Sale>> getUnsynchronizedSales() async {
    final db = await database;

    // Obtener ventas no sincronizadas
    final ventasMaps = await db.rawQuery(SalesQueries.getVentasNoSincronizadas);

    // Convertir maps a objetos Sale
    final ventas = <Sale>[];
    for (var ventaMap in ventasMaps) {
      final ventaId = ventaMap['id'] as int;

      // Obtener los detalles de cada venta
      final detallesMaps = await db.query(
        'ventas_detalle',
        where: 'venta_id = ? AND eliminado = 0',
        whereArgs: [ventaId],
      );

      // Convertir maps a objetos SaleDetail
      final detalles = detallesMaps.map((map) => SaleDetail.fromMap(map)).toList();

      // Convertir map a objeto Sale y agregar los detalles
      ventas.add(Sale.fromMap(ventaMap).copyWith(detalles: detalles));
    }

    return ventas;
  }

  /// Obtener total de ventas por período
  Future<double> getTotalSalesByPeriod(DateTime inicio, DateTime fin) async {
    final db = await database;

    // Formato para fechas ISO8601
    final inicioString = inicio.toIso8601String();
    final finString = fin.toIso8601String();

    // Obtener total
    final result = await db.rawQuery(
      SalesQueries.getTotalVentasByPeriodo,
      [inicioString, finString],
    );

    // Extraer el total
    final total = result.isNotEmpty ? (result.first['total'] as num?)?.toDouble() : 0.0;
    return total ?? 0.0;
  }
}