import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Producto_precio_stock.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/datos_facturacion_model.dart';
import '../models/payment_method.dart';
import '../models/payment_provider.dart';
import '../models/producto.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_maestro.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/sales/sale.dart';
import '../models/sales/sale_detail.dart';
import '../models/user.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Helpers de colecciones ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _clientes =>
      _db.collection('clientes');

  CollectionReference<Map<String, dynamic>> get _productos =>
      _db.collection('productos');

  CollectionReference<Map<String, dynamic>> get _categorias =>
      _db.collection('categorias');

  CollectionReference<Map<String, dynamic>> get _datosFacturacion =>
      _db.collection('datos_facturacion');

  CollectionReference<Map<String, dynamic>> get _paymentProviders =>
      _db.collection('payment_providers');

  CollectionReference<Map<String, dynamic>> get _paymentMethods =>
      _db.collection('payment_methods');

  CollectionReference<Map<String, dynamic>> get _productosIvas =>
      _db.collection('productos_ivas');

  CollectionReference<Map<String, dynamic>> get _ventas =>
      _db.collection('ventas');

  String get _currentComercioId => User.currencyUser?.comercioId ?? '0';

  // ── USUARIOS ──────────────────────────────────────────────────────────────

  Future<void> upsertUser(User user) async {
    if (user.email == null && user.username == null) return;
    final docId = user.email ?? user.username!;
    await _users.doc(docId).set(user.toJson(), SetOptions(merge: true));
  }

  Future<void> upsertUsers(List<User> users) async {
    final batch = _db.batch();
    for (final user in users) {
      if (user.email == null && user.username == null) continue;
      final docId = user.email ?? user.username!;
      batch.set(_users.doc(docId), user.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final doc = await _users.doc(email).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      // Fallback: search by username
      final snap = await _users.where('username', isEqualTo: email).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return User.fromJson(snap.docs.first.data());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final snap = await _users
          .where('comercio_id', isEqualTo: _currentComercioId)
          .get();
      return snap.docs.map((d) => User.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  // ── CLIENTES ──────────────────────────────────────────────────────────────

  Future<void> upsertCliente(ClientesMostrador cliente) async {
    if (cliente.idCliente == null) return;
    final map = cliente.toMap()..remove('id'); // Remove SQLite local id
    await _clientes.doc(cliente.idCliente).set(map, SetOptions(merge: true));
  }

  Future<bool> clienteExiste(String idCliente) async {
    final doc = await _clientes.doc(idCliente).get();
    return doc.exists;
  }

  Future<List<ClientesMostrador>> getClientes() async {
    try {
      final comercioId = _currentComercioId;
      final snap = await _clientes
          .where('comercio_id', isEqualTo: int.tryParse(comercioId) ?? 0)
          .get();
      return snap.docs
          .map((d) => ClientesMostrador.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateCliente(ClientesMostrador cliente) async {
    if (cliente.idCliente == null) return;
    final map = cliente.toMap()..remove('id');
    await _clientes.doc(cliente.idCliente).set(map, SetOptions(merge: true));
  }

  Future<void> deleteCliente(String idCliente) async {
    await _clientes.doc(idCliente).delete();
  }

  Future<List<ClientesMostrador>> getClientesModificados() async {
    try {
      final snap = await _clientes
          .where('modificado', isEqualTo: 1)
          .where('comercio_id',
              isEqualTo: int.tryParse(_currentComercioId) ?? 0)
          .get();
      return snap.docs
          .map((d) => ClientesMostrador.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> marcarClienteSincronizado(String? idCliente) async {
    if (idCliente == null) return;
    await _clientes.doc(idCliente).update({'modificado': 0});
  }

  // ── PRODUCTOS ─────────────────────────────────────────────────────────────

  Future<void> upsertProductoResponse(ProductoResponse response) async {
    if (response.data == null) return;
    final batch = _db.batch();

    for (final datum in response.data!) {
      if (datum.id == null) continue;
      final docId = datum.id.toString();
      final map = <String, dynamic>{
        'id': datum.id,
        'nombre': datum.nombre,
        'barcode': datum.barcode,
        'tipo_producto': productoTipoValues.reverse[datum.productoTipo],
        'producto_tipo': productoTipoValues.reverse[datum.productoTipo],
        'category_id': datum.categoryId,
        'marca_id': datum.marcaId,
        'proveedor_id': datum.proveedorId,
        'comercio_id': int.tryParse(datum.comercioId ?? ''),
        'eliminado': 0,
        'listas_precios': datum.listasPrecios
                ?.map((lp) => lp.toJson())
                .toList() ??
            [],
        'stocks':
            datum.stocks?.map((s) => s.toJson()).toList() ?? [],
        'variaciones': datum.productosVariaciones
                ?.map((v) => {
                      'referencia_variacion': v.referenciaVariacion,
                      'nombre': v.variaciones,
                      'codigo_variacion': v.codigoVariacion,
                      'stocks': v.stocks?.map((s) => s.toJson()).toList() ?? [],
                      'listas_precios':
                          v.listasPrecios?.map((lp) => lp.toJson()).toList() ??
                              [],
                    })
                .toList() ??
            [],
      };
      batch.set(_productos.doc(docId), map, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<ProductoResponse> getProductoResponse(
      int sucursalId, int listaId) async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .get();

      final datums = snap.docs.map((doc) {
        final d = doc.data();
        final listasPrecios = (d['listas_precios'] as List?)
                ?.map((lp) => ListasPrecio.fromJson(Map<String, dynamic>.from(lp)))
                .toList() ??
            [];
        final stocks = (d['stocks'] as List?)
                ?.map((s) => Stock.fromJson(Map<String, dynamic>.from(s)))
                .toList() ??
            [];
        final variaciones = (d['variaciones'] as List?)
                ?.map((v) {
                  final vm = Map<String, dynamic>.from(v);
                  return ProductosVariacione(
                    referenciaVariacion: vm['referencia_variacion'],
                    variaciones: vm['nombre'],
                    codigoVariacion: vm['codigo_variacion'],
                    stocks: (vm['stocks'] as List?)
                            ?.map((s) =>
                                Stock.fromJson(Map<String, dynamic>.from(s)))
                            .toList() ??
                        [],
                    listasPrecios: (vm['listas_precios'] as List?)
                            ?.map((lp) => ListasPrecio.fromJson(
                                Map<String, dynamic>.from(lp)))
                            .toList() ??
                        [],
                  );
                })
                .toList() ??
            [];

        List<ListasPrecio> filteredListasPrecios = listasPrecios;
        if (listaId > 0) {
          final especifica =
              listasPrecios.where((lp) => lp.listaId == listaId).toList();
          if (especifica.isNotEmpty) filteredListasPrecios = especifica;
        }

        List<Stock> filteredStocks = stocks;
        if (sucursalId > 0) {
          final especifica = stocks
              .where((s) => s.sucursalId == sucursalId || s.sucursalId == null)
              .toList();
          if (especifica.isNotEmpty) filteredStocks = especifica;
        }

        return Datum(
          id: d['id'] as int?,
          nombre: d['nombre'] as String?,
          barcode: d['barcode'] as String?,
          productoTipo: productoTipoValues.map[d['producto_tipo']],
          categoryId: d['category_id'] as int?,
          marcaId: d['marca_id'] as int?,
          proveedorId: d['proveedor_id'] as int?,
          comercioId: d['comercio_id']?.toString(),
          listasPrecios: filteredListasPrecios,
          stocks: filteredStocks,
          productosVariaciones: variaciones,
        );
      }).toList();

      return ProductoResponse(
        currentPage: 1,
        data: datums,
        firstPageUrl: null,
        from: 1,
        lastPage: 1,
        lastPageUrl: null,
        links: [],
        nextPageUrl: null,
        path: null,
        perPage: datums.length,
        prevPageUrl: null,
        to: datums.length,
        total: datums.length,
      );
    } catch (_) {
      return ProductoResponse(
        currentPage: 1,
        data: [],
        firstPageUrl: null,
        from: 0,
        lastPage: 1,
        lastPageUrl: null,
        links: [],
        nextPageUrl: null,
        path: null,
        perPage: 0,
        prevPageUrl: null,
        to: 0,
        total: 0,
      );
    }
  }

  Future<List<ProductoModel>> getProductos() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return ProductoModel(
          id: d['id'] as int?,
          name: d['nombre'] as String?,
          tipoProducto: d['tipo_producto'] as String?,
          barcode: d['barcode'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearProductos() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<List<ProductoConPrecioYStock>> getProductosConPrecioYStock({
    required int sucursalId,
    required int listaId,
  }) async {
    try {
      final response = await getProductoResponse(sucursalId, listaId);
      return (response.data ?? []).expand((datum) {
        if (datum.productosVariaciones != null &&
            datum.productosVariaciones!.isNotEmpty) {
          return datum.productosVariaciones!.map((variacion) {
            double precio = 0.0;
            double? stock;
            if (variacion.listasPrecios != null &&
                variacion.listasPrecios!.isNotEmpty) {
              precio = double.tryParse(
                      variacion.listasPrecios!.first.precioLista ?? '') ??
                  0.0;
            }
            if (variacion.stocks != null && variacion.stocks!.isNotEmpty) {
              stock = double.tryParse(
                  variacion.stocks!.first.stock?.toString() ?? '');
            }
            return ProductoConPrecioYStock(
              datum: datum,
              precioLista: precio,
              stock: stock,
              iva: null,
              categoria: null,
            );
          });
        }
        double precio = 0.0;
        double? stock;
        if (datum.listasPrecios != null && datum.listasPrecios!.isNotEmpty) {
          precio =
              double.tryParse(datum.listasPrecios!.first.precioLista ?? '') ??
                  0.0;
        }
        if (datum.stocks != null && datum.stocks!.isNotEmpty) {
          stock = double.tryParse(datum.stocks!.first.stock?.toString() ?? '');
        }
        return [
          ProductoConPrecioYStock(
            datum: datum,
            precioLista: precio,
            stock: stock,
            iva: null,
            categoria: null,
          )
        ];
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── CATEGORÍAS ────────────────────────────────────────────────────────────

  Future<void> upsertCategorias(List<CategoriaModel> categorias) async {
    final batch = _db.batch();
    for (final cat in categorias) {
      if (cat.id == null) continue;
      batch.set(
          _categorias.doc(cat.id.toString()), cat.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<CategoriaModel>> getCategorias() async {
    try {
      final snap = await _categorias.get();
      return snap.docs
          .map((d) => CategoriaModel.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── DATOS FACTURACIÓN ─────────────────────────────────────────────────────

  Future<void> upsertDatosFacturacion(DatosFacturacionModel datos) async {
    if (datos.id == null) return;
    await _datosFacturacion
        .doc(datos.id.toString())
        .set(datos.toJson(), SetOptions(merge: true));
  }

  Future<void> upsertDatosFacturacionList(
      List<DatosFacturacionModel> lista) async {
    final batch = _db.batch();
    for (final datos in lista) {
      if (datos.id == null) continue;
      batch.set(_datosFacturacion.doc(datos.id.toString()), datos.toJson(),
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<DatosFacturacionModel>> getDatosFacturacion(
      int comercioId) async {
    try {
      Query<Map<String, dynamic>> query = _datosFacturacion;
      if (comercioId > 0) {
        query = query.where('comercio_id', isEqualTo: comercioId);
      }
      final snap = await query.get();
      if (snap.docs.isEmpty && comercioId > 0) {
        // Fallback: get any
        final fallback = await _datosFacturacion.get();
        return fallback.docs
            .map((d) => DatosFacturacionModel.fromJson(d.data()))
            .toList();
      }
      return snap.docs
          .map((d) => DatosFacturacionModel.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DatosFacturacionModel>> getAllDatosFacturacion() async {
    try {
      final snap = await _datosFacturacion.get();
      return snap.docs
          .map((d) => DatosFacturacionModel.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── MÉTODOS DE PAGO ───────────────────────────────────────────────────────

  Future<void> upsertPaymentProvider(Map<String, dynamic> providerJson) async {
    try {
      final provider = PaymentProvider.fromJson(providerJson);
      if (provider.id == null) return;

      await _paymentProviders
          .doc(provider.id.toString())
          .set(provider.toMap(), SetOptions(merge: true));

      if (provider.metodosPago != null) {
        final batch = _db.batch();
        for (final method in provider.metodosPago!) {
          if (method.id == null) continue;
          batch.set(_paymentMethods.doc(method.id.toString()), method.toMap(),
              SetOptions(merge: true));
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<List<PaymentProvider>> getPaymentProviders() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      Query<Map<String, dynamic>> query = _paymentProviders;
      if (comercioId > 0) {
        query = query.where('comercio_id', isEqualTo: comercioId);
      }
      final provSnap = await query.get();

      if (provSnap.docs.isEmpty) {
        return [_defaultProvider()];
      }

      final providers = <PaymentProvider>[];
      for (final provDoc in provSnap.docs) {
        final provider = PaymentProvider.fromJson(provDoc.data());
        final methSnap = await _paymentMethods
            .where('provider_id', isEqualTo: provider.id)
            .get();
        final methods = methSnap.docs
            .map((d) => PaymentMethod.fromJson(d.data()))
            .toList();
        providers.add(provider.copyWith(metodosPago: methods));
      }
      return providers;
    } catch (_) {
      return [_defaultProvider()];
    }
  }

  PaymentProvider _defaultProvider() => PaymentProvider(
        id: 0,
        nombre: 'Efectivo',
        metodosPago: [
          PaymentMethod(id: 0, providerId: 0, nombre: 'Efectivo', recargo: 0.0)
        ],
      );

  // ── PRODUCTOS IVAS ────────────────────────────────────────────────────────

  Future<void> upsertProductosIvas(List<ProductosIvasModel> ivas) async {
    final batch = _db.batch();
    for (final iva in ivas) {
      final docId =
          '${iva.productId}_${iva.sucursalId}_${iva.comercioId}';
      batch.set(_productosIvas.doc(docId), iva.toMap(),
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<ProductosIvasModel>> getProductosIvas() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productosIvas
          .where('comercio_id', isEqualTo: comercioId)
          .get();
      return snap.docs
          .map((d) => ProductosIvasModel.fromMap(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── VENTAS ────────────────────────────────────────────────────────────────

  Future<int> saveSale(Sale sale) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final saleWithId = sale.copyWith(id: id, idVenta: id.toString());
    final map = saleWithId.toMap();
    map['detalles'] =
        saleWithId.detalles?.map((d) => d.toMap()).toList() ?? [];
    map['created_at'] = FieldValue.serverTimestamp();
    map['updated_at'] = FieldValue.serverTimestamp();
    await _ventas.doc(id.toString()).set(map);
    return id;
  }

  Future<void> updateSale(Sale sale) async {
    if (sale.id == null && sale.idVenta == null) return;
    final docId = sale.idVenta ?? sale.id.toString();
    final map = sale.toMap();
    map['updated_at'] = FieldValue.serverTimestamp();
    await _ventas.doc(docId).update(map);
  }

  Future<Sale?> getSaleById(int id) async {
    try {
      final doc = await _ventas.doc(id.toString()).get();
      if (!doc.exists || doc.data() == null) return null;
      return _saleFromFirestore(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<List<Sale>> getAllSales() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _ventas
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => _saleFromFirestore(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Sale>> getSalesByClientId(int clienteId) async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _ventas
          .where('comercio_id', isEqualTo: comercioId)
          .where('cliente_id', isEqualTo: clienteId)
          .where('eliminado', isEqualTo: 0)
          .get();
      return snap.docs.map((d) => _saleFromFirestore(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Sale>> getSalesByPeriod(DateTime inicio, DateTime fin) async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _ventas
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .where('fecha',
              isGreaterThanOrEqualTo: inicio.toIso8601String())
          .where('fecha', isLessThanOrEqualTo: fin.toIso8601String())
          .get();
      return snap.docs.map((d) => _saleFromFirestore(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> softDeleteSale(int ventaId) async {
    final now = DateTime.now().toIso8601String();
    await _ventas.doc(ventaId.toString()).update({
      'eliminado': 1,
      'updated_at': FieldValue.serverTimestamp(),
      'deleted_at': now,
    });
  }

  Future<void> markSaleAsSynchronized(int ventaId) async {
    final now = DateTime.now().toIso8601String();
    await _ventas.doc(ventaId.toString()).update({
      'sincronizado': 1,
      'updated_at': FieldValue.serverTimestamp(),
      'sincronizado_at': now,
    });
  }

  Future<List<Sale>> getUnsynchronizedSales() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _ventas
          .where('comercio_id', isEqualTo: comercioId)
          .where('sincronizado', isEqualTo: 0)
          .where('eliminado', isEqualTo: 0)
          .get();
      return snap.docs.map((d) => _saleFromFirestore(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<double> getTotalSalesByPeriod(DateTime inicio, DateTime fin) async {
    try {
      final sales = await getSalesByPeriod(inicio, fin);
      return sales.fold<double>(0.0, (sum, s) => sum + s.total);
    } catch (_) {
      return 0.0;
    }
  }

  Sale _saleFromFirestore(Map<String, dynamic> data) {
    final detallesRaw = data['detalles'] as List?;
    final detalles = detallesRaw
        ?.map((d) => SaleDetail.fromMap(Map<String, dynamic>.from(d)))
        .toList();

    // Firestore Timestamps → ISO strings for Sale.fromMap
    final map = Map<String, dynamic>.from(data);
    if (map['created_at'] is Timestamp) {
      map['created_at'] =
          (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updated_at'] is Timestamp) {
      map['updated_at'] =
          (map['updated_at'] as Timestamp).toDate().toIso8601String();
    }
    map.remove('detalles');

    return Sale.fromMap(map).copyWith(detalles: detalles);
  }

  // ── STOCKS SUCURSALES ─────────────────────────────────────────────────────

  Future<List<ProductosStockSucursalesModel>> getProductosStockSucursales(
      int sucursalId) async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .get();

      final result = <ProductosStockSucursalesModel>[];
      for (final doc in snap.docs) {
        final stocks = doc.data()['stocks'] as List? ?? [];
        for (final s in stocks) {
          final sm = Map<String, dynamic>.from(s);
          if (sm['sucursal_id'] == sucursalId || sucursalId == 0) {
            result.add(ProductosStockSucursalesModel(
              productId: doc.data()['id'] as int?,
              sucursalId: sm['sucursal_id'] as int?,
              stock: sm['stock'] != null
                  ? (double.tryParse(sm['stock'].toString()) ?? 0.0)
                  : 0.0,
              comercioId: comercioId,
            ));
          }
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<ProductosListaPreciosModel>> getProductosListaPrecios(
      int listaId) async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      final snap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .where('eliminado', isEqualTo: 0)
          .get();

      final result = <ProductosListaPreciosModel>[];
      for (final doc in snap.docs) {
        final precios = doc.data()['listas_precios'] as List? ?? [];
        for (final p in precios) {
          final pm = Map<String, dynamic>.from(p);
          if (pm['lista_id'] == listaId || listaId == 0) {
            result.add(ProductosListaPreciosModel(
              productId: doc.data()['id'] as int?,
              listaId: pm['lista_id'] as int?,
              precioLista: double.tryParse(pm['precio_lista']?.toString() ?? '') ?? 0.0,
              comercioId: comercioId,
            ));
          }
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ── ESTADO DE DATOS ───────────────────────────────────────────────────────

  Future<bool> isDataSynchronized() async {
    try {
      final comercioId = int.tryParse(_currentComercioId) ?? 0;
      if (comercioId == 0) return false;

      final snap = await _datosFacturacion
          .where('comercio_id', isEqualTo: comercioId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;

      final prodSnap = await _productos
          .where('comercio_id', isEqualTo: comercioId)
          .limit(1)
          .get();
      return prodSnap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
