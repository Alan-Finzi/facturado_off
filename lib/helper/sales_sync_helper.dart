import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/sales/sale.dart';
import '../models/sales/sale_detail.dart';
import '../models/sync_queue.dart';
import 'database_helper.dart';
import 'sales_database_helper.dart';
import 'sale_detail_helper.dart';

/// Clase que proporciona métodos para sincronización de ventas con el servidor
class SalesSyncHelper {
  final DatabaseHelper _databaseHelper;
  final SalesDatabaseHelper _salesDatabaseHelper;
  final SaleDetailHelper _saleDetailHelper;

  /// Constructor
  SalesSyncHelper({
    DatabaseHelper? databaseHelper,
    SalesDatabaseHelper? salesDatabaseHelper,
    SaleDetailHelper? saleDetailHelper,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _salesDatabaseHelper = salesDatabaseHelper ?? SalesDatabaseHelper(),
        _saleDetailHelper = saleDetailHelper ?? SaleDetailHelper();

  /// Encola una venta para sincronización
  Future<void> enqueueSaleForSync(int ventaId) async {
    final venta = await _salesDatabaseHelper.getSaleById(ventaId);
    if (venta == null) {
      throw Exception('Venta con ID $ventaId no encontrada');
    }

    final syncQueue = SyncQueue(
      resourceType: 'Sale',
      resourceId: ventaId,
      operation: 'upsert',
      payload: jsonEncode(venta.toMap()),
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    // Insertar directamente en la base de datos ya que no existe addToSyncQueue
    final db = await _databaseHelper.database;
    await db.insert(
      'sync_queue',
      syncQueue.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Procesa las ventas pendientes de sincronización
  Future<List<Map<String, dynamic>>> processSalesForSync() async {
    final unsynced = await _salesDatabaseHelper.getUnsynchronizedSales();
    final results = <Map<String, dynamic>>[];

    for (final venta in unsynced) {
      final ventaId = venta.id;
      if (ventaId != null) {
        try {
          // Crear un objeto de sincronización para la venta
          final syncVenta = {
            'id': venta.id,
            'nroVenta': venta.nroVenta,
            'idVenta': venta.idVenta,
            'fecha': venta.fecha.toIso8601String(),
            'comercioId': venta.comercioId,
            'clienteId': venta.clienteId,
            'domicilioEntrega': venta.domicilioEntrega,
            'tipoComprobante': venta.tipoComprobante,
            'datosFacturacionId': venta.datosFacturacionId,
            'subtotal': venta.subtotal,
            'iva': venta.iva,
            'total': venta.total,
            'descuento': venta.descuento,
            'recargo': venta.recargo,
            'metodoPago': venta.metodoPago,
            'metodoPagoDetalles': venta.metodoPagoDetalles,
            'estado': venta.estado,
            'userId': venta.userId,
            'canalVenta': venta.canalVenta,
            'cajaId': venta.cajaId,
            'notaInterna': venta.notaInterna,
            'observaciones': venta.observaciones,
            'createdAt': venta.createdAt.toIso8601String(),
            'updatedAt': venta.updatedAt.toIso8601String(),
            'detalles': await _prepareDetallesForSync(ventaId),
          };

          // Agregar a los resultados
          results.add({
            'ventaId': ventaId,
            'syncData': syncVenta,
          });

        } catch (e) {
          print('Error al preparar venta $ventaId para sincronización: $e');
          // Agregar el error a los resultados
          results.add({
            'ventaId': ventaId,
            'error': e.toString(),
          });
        }
      }
    }

    return results;
  }

  /// Prepara los detalles de una venta para sincronización
  Future<List<Map<String, dynamic>>> _prepareDetallesForSync(int ventaId) async {
    final detalles = await _saleDetailHelper.getSaleDetailsByVentaId(ventaId);
    final result = <Map<String, dynamic>>[];

    for (final detalle in detalles) {
      result.add({
        'id': detalle.id,
        'ventaId': detalle.ventaId,
        'productoId': detalle.productoId,
        'codigoProducto': detalle.codigoProducto,
        'nombreProducto': detalle.nombreProducto,
        'descripcion': detalle.descripcion,
        'cantidad': detalle.cantidad,
        'unidadMedida': detalle.unidadMedida,
        'precioUnitario': detalle.precioUnitario,
        'porcentajeIva': detalle.porcentajeIva,
        'montoIva': detalle.montoIva,
        'precioFinal': detalle.precioFinal,
        'subtotal': detalle.subtotal,
        'total': detalle.total,
        'descuento': detalle.descuento,
        'montoDescuento': detalle.montoDescuento,
        'notaInterna': detalle.notaInterna,
        'observaciones': detalle.observaciones,
        'categoriaId': detalle.categoriaId,
        'categoriaNombre': detalle.categoriaNombre,
        'createdAt': detalle.createdAt.toIso8601String(),
        'updatedAt': detalle.updatedAt.toIso8601String(),
      });
    }

    return result;
  }

  /// Marca una venta como sincronizada después de recibir confirmación del servidor
  Future<void> markSaleAsSynchronized(int ventaId) async {
    await _salesDatabaseHelper.markSaleAsSynchronized(ventaId);
  }

  /// Actualiza el estado de una venta según la respuesta del servidor
  Future<void> updateSaleStatus(int ventaId, String estado) async {
    final venta = await _salesDatabaseHelper.getSaleById(ventaId);
    if (venta == null) {
      throw Exception('Venta con ID $ventaId no encontrada');
    }

    final ventaActualizada = venta.copyWith(
      estado: estado,
      updatedAt: DateTime.now(),
    );

    await _salesDatabaseHelper.updateSale(ventaActualizada);
  }

  /// Obtiene un resumen de ventas pendientes de sincronización
  Future<Map<String, dynamic>> getSyncSummary() async {
    final unsynced = await _salesDatabaseHelper.getUnsynchronizedSales();

    double totalAmount = 0.0;
    int totalCount = unsynced.length;

    Map<String, int> byStatus = {};
    Map<String, int> byPaymentMethod = {};

    for (final venta in unsynced) {
      totalAmount += venta.total;

      // Conteo por estado
      if (byStatus.containsKey(venta.estado)) {
        byStatus[venta.estado] = (byStatus[venta.estado] ?? 0) + 1;
      } else {
        byStatus[venta.estado] = 1;
      }

      // Conteo por método de pago
      if (byPaymentMethod.containsKey(venta.metodoPago)) {
        byPaymentMethod[venta.metodoPago] = (byPaymentMethod[venta.metodoPago] ?? 0) + 1;
      } else {
        byPaymentMethod[venta.metodoPago] = 1;
      }
    }

    return {
      'count': totalCount,
      'totalAmount': totalAmount,
      'byStatus': byStatus,
      'byPaymentMethod': byPaymentMethod,
    };
  }

  /// Sincroniza todas las ventas pendientes
  Future<Map<String, dynamic>> syncAllSales() async {
    final unsynced = await _salesDatabaseHelper.getUnsynchronizedSales();
    final results = {
      'success': <int>[],
      'failed': <Map<String, dynamic>>[],
      'total': unsynced.length,
    };

    final successList = results['success'] as List<int>;
    final failedList = results['failed'] as List<Map<String, dynamic>>;

    for (final venta in unsynced) {
      if (venta.id != null) {
        try {
          // Encolar para sincronización
          await enqueueSaleForSync(venta.id!);
          successList.add(venta.id!);
        } catch (e) {
          failedList.add({
            'ventaId': venta.id,
            'error': e.toString(),
          });
        }
      }
    }

    return results;
  }

  /// Recupera ventas del servidor y actualiza la base de datos local
  Future<void> downloadSalesFromServer(List<Map<String, dynamic>> serverSales) async {
    for (final serverSale in serverSales) {
      try {
        // Convertir datos del servidor a objeto Sale
        final saleData = Sale.fromMap(serverSale);

        // Buscar venta local con el mismo ID externo
        final localSale = await _findLocalSaleByExternalId(saleData.idVenta);

        if (localSale != null) {
          // Actualizar venta existente
          await _salesDatabaseHelper.updateSale(
            saleData.copyWith(
              id: localSale.id,
              sincronizado: 1,
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          // Insertar nueva venta
          await _salesDatabaseHelper.saveSale(
            saleData.copyWith(
              sincronizado: 1,
              updatedAt: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        print('Error al importar venta del servidor: $e');
      }
    }
  }

  /// Encuentra una venta local por su ID externo
  Future<Sale?> _findLocalSaleByExternalId(String? idVentaExterno) async {
    if (idVentaExterno == null) return null;

    final db = await _databaseHelper.database;
    final ventaMaps = await db.query(
      'ventas',
      where: 'id_venta = ?',
      whereArgs: [idVentaExterno],
    );

    if (ventaMaps.isEmpty) {
      return null;
    }

    return Sale.fromMap(ventaMaps.first);
  }
}