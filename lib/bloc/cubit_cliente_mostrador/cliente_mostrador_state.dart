part of 'cliente_mostrador_cubit.dart';
/// Estado para el cubit de clientes de mostrador que almacena la información 
/// relacionada con clientes, búsqueda y selección
class ClientesMostradorState extends Equatable {
  /// Lista completa de clientes activos
  final List<ClientesMostrador> clientes;
  
  /// Lista filtrada de clientes según búsqueda
  final List<ClientesMostrador> filteredClientes;
  
  /// Lista de clientes eliminados/desactivados
  final List<ClientesMostrador> deleteClientes;
  
  /// Bandera para indicar si se debe actualizar la información del cliente
  final bool actualizarCliente;
  
  /// Cliente actualmente seleccionado
  final ClientesMostrador? clienteSeleccionado;
  
  /// Bandera para indicar si se está buscando un cliente
  final bool buscarCliente;

  /// Constructor del estado con valores por defecto
  /// @param clientes Lista de clientes activos (requerido)
  /// @param buscarCliente Indica si se está buscando un cliente (default: false)
  /// @param filteredClientes Lista filtrada de clientes (default: lista vacía)
  /// @param actualizarCliente Indica si se debe actualizar cliente (default: false)
  /// @param deleteClientes Lista de clientes eliminados (default: lista vacía)
  /// @param clienteSeleccionado Cliente seleccionado actualmente (default: null)
  const ClientesMostradorState({
    required this.clientes,
    this.buscarCliente = false,
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
    bool? buscarCliente,
    ClientesMostrador? clienteSeleccionado,
  }) {
    return ClientesMostradorState(
      clientes: clientes ?? this.clientes,
      filteredClientes: filteredClientes ?? this.filteredClientes,
      deleteClientes: deleteClientes ?? this.deleteClientes,
      actualizarCliente: actualizarCliente ?? this.actualizarCliente,
      buscarCliente: buscarCliente ?? this.buscarCliente,
      clienteSeleccionado: clienteSeleccionado ?? this.clienteSeleccionado,
    );
  }

  @override
  List<Object?> get props => [
    clientes,
    filteredClientes,
    deleteClientes,
    actualizarCliente,
    clienteSeleccionado,
    buscarCliente,
  ];
}
