part of 'cliente_mostrador_cubit.dart';

class ClientesMostradorState extends Equatable {
  final List<ClientesMostrador> clientes;
  final List<ClientesMostrador> filteredClientes;
  final List<ClientesMostrador> deleteClientes;
  final bool actualizarCliente;
  final ClientesMostrador? clienteSeleccionado;

  const ClientesMostradorState({
    required this.clientes,
    this.filteredClientes = const [],
    this.actualizarCliente = false,
    this.deleteClientes = const [],
    this.clienteSeleccionado,
  });

  ClientesMostradorState copyWith({
    List<ClientesMostrador>? clientes,
    List<ClientesMostrador>? filteredClientes,
    List<ClientesMostrador>? deleteClientes,
    bool? actualizarCliente,
    ClientesMostrador? clienteSeleccionado,
  }) {
    return ClientesMostradorState(
      clientes: clientes ?? this.clientes,
      filteredClientes: filteredClientes ?? this.filteredClientes,
      deleteClientes: deleteClientes ?? this.deleteClientes,
      actualizarCliente: actualizarCliente ?? this.actualizarCliente,
      clienteSeleccionado: clienteSeleccionado ?? this.clienteSeleccionado,
    );
  }

  @override
  List<Object?> get props => [clientes, filteredClientes, deleteClientes, actualizarCliente, clienteSeleccionado];
}