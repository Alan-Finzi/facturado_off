import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/clientes_mostrador.dart';
import '../../services/user_repository.dart';

part 'cliente_mostrador_state.dart';
/// Cubit para la gestión de clientes de mostrador en la aplicación.
/// Maneja la carga, filtrado, selección y actualización de clientes.
class ClientesMostradorCubit extends Cubit<ClientesMostradorState> {
  /// Repositorio para acceso a datos de clientes
  final UserRepository userRepository;

  /// Constructor que inicializa el Cubit con un estado vacío
  /// @param userRepository Repositorio para acceso a datos
  ClientesMostradorCubit(this.userRepository)
      : super(const ClientesMostradorState(clientes: [], filteredClientes: []));

  /// Deselecciona el cliente actualmente seleccionado
  /// Reinicia el estado de búsqueda de cliente a falso
  void deseleccionarCliente() {
    emit(state.copyWith(
      clienteSeleccionado: null,
      buscarCliente: false,
    ));
  }

  /// Obtiene los clientes desde la base de datos y actualiza el estado
  /// Los clientes se filtran en activos y desactivados basados en el campo activo
  Future<void> getClientesBD() async {
    try {
      // Obtener todos los clientes de la base de datos
      final list = await userRepository.fetchClientes();

      // Filtrar clientes activos y desactivados
      final clientesActivos = list.where((cliente) => cliente.activo == 1).toList();
      final clientesDesactivados = list.where((cliente) => cliente.activo == 0).toList();

      // Emitir un nuevo estado, preservando cualquier otro estado existente
      emit(state.copyWith(
        clientes: clientesActivos,
        filteredClientes: clientesActivos,
        deleteClientes: clientesDesactivados,
      ));
    } catch (e) {
      print("Error al obtener clientes: $e");
      // Considerar emitir un estado de error para notificar al UI
    }
  }

  /// Busca clientes que coincidan con el texto de búsqueda proporcionado
  /// @param query Texto a buscar en nombre, DNI o código de cliente
  Future<void> buscarCliente(String query) async {
    try {
      // Filtrar clientes que coincidan con la búsqueda
      final filteredClientes = state.clientes.where((cliente) {
        final nombre = cliente.nombre?.toLowerCase() ?? '';
        final dni = cliente.dni ?? '';
        final codigoCliente = cliente.idCliente ?? '';
        return nombre.contains(query.toLowerCase()) || 
               dni.contains(query) || 
               codigoCliente.contains(query);
      }).toList();

      // Actualizar solo la lista filtrada, manteniendo el resto del estado
      emit(state.copyWith(filteredClientes: filteredClientes));
    } catch (e) {
      print("Error al buscar cliente: $e");
    }
  }
  /// Selecciona un cliente y actualiza el estado de búsqueda
  /// @param cliente Cliente a seleccionar
  /// @param value Estado actual de búsqueda que se invertirá
  /// Este método es clave para la integración con listas de precios, ya que al seleccionar
  /// un cliente se debe actualizar la lista de precios según su configuración
  void seleccionarCliente(ClientesMostrador cliente, bool value) {
    emit(state.copyWith(
      clienteSeleccionado: cliente,
      buscarCliente: !value,
    ));
  }




  // Método para actualizar un cliente
  Future<void> updateCliente(ClientesMostrador cliente) async {
    try {
      await userRepository.updateCliente(cliente);
      await getClientesBD(); // Refresca la lista de clientes después de la actualización
    } catch (e) {
      print("Error al actualizar cliente: $e");
    }
  }

  // Método para eliminar un cliente
  Future<void> deleteCliente(String idCliente) async {
    try {
      // Eliminar cliente de la base de datos
      await userRepository.removeCliente(idCliente);

      // Refrescar la lista de clientes desde la base de datos
      final updatedClientes = await userRepository.fetchClientes();

      // Actualizar el estado con la lista de clientes actualizada
      emit(state.copyWith(
        clientes: updatedClientes,
        deleteClientes: List.from(state.deleteClientes)..addAll(updatedClientes.where((c) => c.idCliente == idCliente)),
      ));

      // Deseleccionar el cliente después de la eliminación
      deseleccionarCliente();
    } catch (e) {
      print("Error al eliminar cliente: $e");
      // Aquí podrías manejar el error de manera más detallada, como emitir un estado con un mensaje de error si es necesario.
    }
  }

  // Método para filtrar los clientes
  void filterClientes(String nameQuery, String dniQuery, int priceListQuery, int isActivo) {
      final filteredClientes = state.clientes.where((cliente) {
        bool matches = true;

        // Filtro por estado activo o inactivo
        if (isActivo == 1) {
          matches = matches && (cliente.activo == 1);
        } else if (isActivo == 0) {
          matches = matches && (cliente.activo == 0);
        }

        if (nameQuery.isNotEmpty ||nameQuery != "") {
          matches = matches && (cliente.nombre?.toLowerCase().contains(nameQuery.toLowerCase()) ?? false);
        }

        if (dniQuery.isNotEmpty) {
          matches = matches && (cliente.dni?.contains(dniQuery) ?? false);
        }

        if (priceListQuery > 0) {
          final priceListValue = priceListQuery;
          matches = matches && (cliente.listaPrecio == priceListValue);
        }

        return matches;
      }).toList();

      emit(state.copyWith(filteredClientes: filteredClientes));

  }
}
