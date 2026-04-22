import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Colecciones ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get ventas =>
      _db.collection('ventas');

  CollectionReference<Map<String, dynamic>> get clientes =>
      _db.collection('clientes');

  CollectionReference<Map<String, dynamic>> get productos =>
      _db.collection('productos');

  CollectionReference<Map<String, dynamic>> get syncQueue =>
      _db.collection('sync_queue');

  // ── Ventas ───────────────────────────────────────────────────────────────────

  Future<String> crearVenta(Map<String, dynamic> venta) async {
    venta['created_at'] = FieldValue.serverTimestamp();
    venta['updated_at'] = FieldValue.serverTimestamp();
    final ref = await ventas.add(venta);
    return ref.id;
  }

  Future<void> actualizarVenta(String id, Map<String, dynamic> datos) async {
    datos['updated_at'] = FieldValue.serverTimestamp();
    await ventas.doc(id).update(datos);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamVentas({
    String? comercioId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = ventas.orderBy('created_at', descending: true).limit(limit);
    if (comercioId != null) {
      query = query.where('comercio_id', isEqualTo: comercioId);
    }
    return query.snapshots();
  }

  // ── Clientes ─────────────────────────────────────────────────────────────────

  Future<void> upsertCliente(String idCliente, Map<String, dynamic> cliente) async {
    cliente['updated_at'] = FieldValue.serverTimestamp();
    await clientes.doc(idCliente).set(cliente, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getClientesPorComercio(String comercioId) async {
    final snap = await clientes
        .where('comercio_id', isEqualTo: comercioId)
        .where('eliminado', isEqualTo: 0)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamClientes(String comercioId) {
    return clientes
        .where('comercio_id', isEqualTo: comercioId)
        .where('eliminado', isEqualTo: 0)
        .snapshots();
  }

  // ── Productos ─────────────────────────────────────────────────────────────────

  Future<void> upsertProducto(int productId, Map<String, dynamic> producto) async {
    producto['updated_at'] = FieldValue.serverTimestamp();
    await productos.doc(productId.toString()).set(producto, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getProductosPorComercio(String comercioId) async {
    final snap = await productos
        .where('comercio_id', isEqualTo: comercioId)
        .where('eliminado', isEqualTo: 0)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ── Sincronización ────────────────────────────────────────────────────────────

  Future<void> encolarSync({
    required String resourceType,
    required String resourceId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await syncQueue.add({
      'resource_type': resourceType,
      'resource_id': resourceId,
      'operation': operation,
      'payload': payload,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'attempts': 0,
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getPendingSync() async {
    final snap = await syncQueue
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at')
        .get();
    return snap.docs;
  }

  Future<void> marcarSyncCompletado(String docId) async {
    await syncQueue.doc(docId).update({
      'status': 'done',
      'completed_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Utilidades ────────────────────────────────────────────────────────────────

  Future<void> runBatch(Future<void> Function(WriteBatch batch) operations) async {
    final batch = _db.batch();
    await operations(batch);
    await batch.commit();
  }
}
