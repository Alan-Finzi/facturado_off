import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/clientes_mostrador.dart';
import '../../services/user_repository.dart';

part 'cliente_mostrador_state.dart';
class ClientesMostradorCubit extends Cubit<ClientesMostradorState> {
  final UserRepository userRepository;

  ClientesMostradorCubit(this.userRepository)
      : super(const ClientesMostradorState(clientes: [], filteredClientes: []));

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
      // Aquí podrías emitir un estado de error si es necesario
    }
  }

  Future<void> buscarCliente(String query) async {
    try {
      final filteredClientes = state.clientes.where((cliente) {
        final dni = cliente.dni ?? '';
        final codigoCliente = cliente.idCliente ?? '';
        return dni.contains(query) || codigoCliente.contains(query);
      }).toList();

      emit(state.copyWith(filteredClientes: filteredClientes));
    } catch (e) {
      print("Error al buscar cliente: $e");
    }
  }

  // Método para seleccionar un cliente
  void seleccionarCliente(ClientesMostrador cliente) {
    emit(state.copyWith(clienteSeleccionado: cliente));
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
    } catch (e) {
      print("Error al eliminar cliente: $e");
      // Aquí podrías manejar el error de manera más detallada, como emitir un estado con un mensaje de error si es necesario.
    }
  }


  void filterClientes(String nameQuery, String dniQuery, int priceListQuery, int isActivo) {
    if (isActivo == 1) {
      final filteredClientes = state.clientes.where((cliente) {
        bool matches = true;

        if (nameQuery.isNotEmpty) {
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
}