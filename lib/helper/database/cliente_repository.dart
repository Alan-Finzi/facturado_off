import '../../models/clientes_mostrador.dart';
import '../../services/firestore_service.dart';

class ClienteRepository {
  final _fs = FirestoreService.instance;

  Future<void> insertCliente(ClientesMostrador cliente) async {
    if (cliente.idCliente == null) return;
    final existe = await _fs.clienteExiste(cliente.idCliente!);
    if (!existe) await _fs.upsertCliente(cliente);
  }

  Future<bool> clienteExiste(String idCliente) async {
    return await _fs.clienteExiste(idCliente);
  }

  Future<List<ClientesMostrador>> getClientesModificados() async {
    return await _fs.getClientesModificados();
  }

  Future<void> marcarClienteSincronizado(String? idCliente) async {
    await _fs.marcarClienteSincronizado(idCliente);
  }

  Future<void> updateCliente(ClientesMostrador cliente) async {
    await _fs.updateCliente(cliente);
  }

  Future<void> deleteCliente(String idCliente) async {
    await _fs.deleteCliente(idCliente);
  }

  Future<List<ClientesMostrador>> getClientes() async {
    return await _fs.getClientes();
  }
}
