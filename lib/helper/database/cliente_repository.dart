import 'package:sqflite/sqflite.dart';
import '../../models/clientes_mostrador.dart';
import '../../util/logger.dart';
import '../database_helper.dart';

/// Repositorio específico para operaciones de base de datos relacionadas con clientes
class ClienteRepository {
  /// Obtiene una referencia a la base de datos principal
  Future<Database> get database async => await DatabaseHelper.instance.database;

  /// Inserta un cliente en la base de datos si no existe
  Future<void> insertCliente(ClientesMostrador cliente) async {
    if (!await clienteExiste(cliente.idCliente!)) {
      Database db = await database;
      await db.insert(
        'Clientes_mostrador',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      log.i('ClienteRepository', 'Cliente insertado: ${cliente.idCliente}');
    }
  }

  /// Verifica si un cliente existe en la base de datos
  Future<bool> clienteExiste(String idCliente) async {
    Database db = await database;
    final result = await db.query(
      'Clientes_mostrador',
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
    );
    return result.isNotEmpty;
  }

  /// Obtiene clientes que han sido modificados localmente
  Future<List<ClientesMostrador>> getClientesModificados() async {
    final db = await database;
    final maps = await db.query('clientes_mostrador', where: 'modificado = 1');
    return maps.map((e) => ClientesMostrador.fromJson(e)).toList();
  }

  /// Marca un cliente como sincronizado con el servidor
  Future<void> marcarClienteSincronizado(String? idCliente) async {
    final db = await database;
    await db.update('clientes_mostrador', {'modificado': 0}, where: 'id_cliente = ?', whereArgs: [idCliente]);
    log.i('ClienteRepository', 'Cliente marcado como sincronizado: $idCliente');
  }

  /// Actualiza la información de un cliente existente
  Future<void> updateCliente(ClientesMostrador cliente) async {
    Database db = await database;
    await db.update(
      'Clientes_mostrador',
      cliente.toMap(),
      where: 'id_cliente = ?',
      whereArgs: [cliente.idCliente],
    );
    log.i('ClienteRepository', 'Cliente actualizado: ${cliente.idCliente}');
  }

  /// Elimina un cliente por su ID
  Future<void> deleteCliente(String idCliente) async {
    Database db = await database;
    await db.delete(
      'Clientes_mostrador',
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
    );
    log.i('ClienteRepository', 'Cliente eliminado: $idCliente');
  }

  /// Obtiene todos los clientes de la base de datos
  Future<List<ClientesMostrador>> getClientes() async {
    try {
      const cacheKey = 'all_clientes';
      
      // Verificar si existe en caché
      final cachedResult = DatabaseHelper.instance._getCachedResult(cacheKey);
      if (cachedResult != null) {
        log.d('ClienteRepository', 'Usando clientes en caché');
        return cachedResult as List<ClientesMostrador>;
      }
      
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('Clientes_mostrador');
      final result = List.generate(maps.length, (i) => ClientesMostrador.fromJson(maps[i]));
      
      // Guardar en caché
      DatabaseHelper.instance._cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      log.e('ClienteRepository', 'Error al obtener clientes', e);
      return [];
    }
  }
}