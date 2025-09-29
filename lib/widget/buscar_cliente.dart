import 'package:facturador_offline/bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/widget/mod_cliente_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/productos_maestro.dart';
import 'widget_alta_clientes.dart';
import 'package:searchfield/searchfield.dart';
/// Widget para la búsqueda y selección de clientes
/// Permite buscar clientes por nombre o DNI y seleccionarlos
/// Cuando se selecciona un cliente, actualiza la lista de precios y limpia los productos
/// Este widget es reutilizable en diferentes páginas y mantiene el cliente seleccionado entre navegaciones
class BuscarClienteWidget extends StatefulWidget {
  /// Si es true, limpia los productos al seleccionar un cliente
  final bool clearProductsOnSelection;

  /// Si es true, muestra un texto con el cliente seleccionado
  final bool showSelectedClient;

  /// Constructor con parámetros opcionales
  const BuscarClienteWidget({
    Key? key,
    this.clearProductsOnSelection = true,
    this.showSelectedClient = true,
  }) : super(key: key);

  @override
  _BuscarClienteWidgetState createState() => _BuscarClienteWidgetState();
}

class _BuscarClienteWidgetState extends State<BuscarClienteWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchFieldListItem<String>> clienteSugerencias = [];

  @override
  void initState() {
    super.initState();
    // Cargar clientes y listas de precios desde la base de datos al iniciar el widget
    context.read<ClientesMostradorCubit>().getClientesBD();
    context.read<ListaPreciosCubit>().getListasPreciosBD();
  }

  /// Convierte la lista de clientes a un formato compatible con el campo de búsqueda
  /// @param clientes Lista de clientes a convertir
  void cargarSugerencias(List<ClientesMostrador> clientes) {
    // Convertir la lista de ClientesMostrador a SearchFieldListItem
    clienteSugerencias = clientes.map((cliente) {
      return SearchFieldListItem<String>(
        cliente.nombre ?? 'Sin nombre',
        item: cliente.dni ?? cliente.idCliente ?? 'Sin DNI', // Usar DNI o ID como identificador
      );
    }).toList();
    setState(() {}); // Actualizar el estado para mostrar las sugerencias cargadas
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientesMostradorCubit, ClientesMostradorState>(
      listener: (context, state) {
        // Cuando hay cambios en el estado, cargamos las sugerencias
        print('Estado de clientes actualizado: ${state.clientes.length} clientes');
        cargarSugerencias(state.clientes);

        // Si hay un cliente seleccionado y el controlador de texto está vacío, mostrar el nombre del cliente
        if (state.clienteSeleccionado != null && _controller.text.isEmpty) {
          _controller.text = state.clienteSeleccionado?.nombre ?? '';
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muestra el cliente seleccionado si existe y si la opción está habilitada
            if (widget.showSelectedClient && state.clienteSeleccionado != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cliente seleccionado: ${state.clienteSeleccionado?.nombre ?? ""} (${state.clienteSeleccionado?.dni ?? ""})',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Limpiar el campo para permitir nueva búsqueda
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),

            // Campo de búsqueda de cliente
            SearchField(
              controller: _controller,
              focusNode: _focusNode,
              suggestions: clienteSugerencias,
              suggestionState: Suggestion.expand,
              textInputAction: TextInputAction.done,
              searchInputDecoration: SearchInputDecoration(
                labelText: 'Buscar cliente o cuit',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _focusNode.unfocus();
                  },
                ),
              ),
              maxSuggestionsInViewPort: 5,
              itemHeight: 50,
              onSuggestionTap: (cliente) {
                final selectedCliente = clienteSugerencias.firstWhere(
                      (c) => c.searchKey == cliente.searchKey,
                );
                // Acceder al estado del ClientesMostradorCubit para obtener la lista de clientes
                final clientes = context.read<ClientesMostradorCubit>().state.clientes;
                final value = context.read<ClientesMostradorCubit>().state.buscarCliente;
                // Buscar el cliente original en la lista de clientes basada en la búsqueda
                ClientesMostrador? clienteCorrespondiente;
                try {
                  clienteCorrespondiente = clientes.firstWhere(
                        (c) => c.dni == selectedCliente.item || c.idCliente == selectedCliente.item,
                  );
                } catch (e) {
                  print('Error al buscar cliente: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cliente no encontrado')),
                  );
                  return;
                }

                // Continuar con el proceso ya que encontramos el cliente
                // Mostrar el pop-up para notificar al usuario que los productos se limpiarán
                // Solo si la opción clearProductsOnSelection está activada
                if (widget.clearProductsOnSelection) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Cambio de Cliente'),
                        content: Text('Los productos seleccionados se limpiarán debido a la actualización de precios.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Cerrar el pop-up
                              _seleccionarCliente(context, clienteCorrespondiente!, value);
                            },
                            child: Text('Aceptar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Si no se deben limpiar productos, seleccionar cliente directamente
                  _seleccionarCliente(context, clienteCorrespondiente!, value);
                }
              },
            ),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // Método para seleccionar un cliente y actualizar el estado
  void _seleccionarCliente(BuildContext context, ClientesMostrador cliente, bool value) {
    // IMPORTANTE: Primero actualizar el cliente seleccionado
    // Esto es clave para la sincronización con la lista de precios
    context.read<ClientesMostradorCubit>().seleccionarCliente(cliente, value);

    if (widget.clearProductsOnSelection) {
      // Después limpiar los productos seleccionados si es necesario
      // Este orden es crucial para mantener la consistencia
      context.read<ProductosCubit>().limpiarProductosSeleccionados();
    }

    // Actualizar la información de la lista de precios del cliente
    if (cliente.listaPrecio != null) {
      final listasPreciosCubit = context.read<ListaPreciosCubit>();
      final listaPrecios = listasPreciosCubit.state.currentList;

      // Buscar el nombre de la lista de precio por ID
      Lista listaCliente;
      try {
        listaCliente = listaPrecios.firstWhere(
          (lista) => lista.id == cliente.listaPrecio,
        );
      } catch (e) {
        print('Lista de precio no encontrada, usando precio base: $e');
        listaCliente = Lista(id: 1, nombre: 'Precio base');
      }

      // Actualizar la información de la lista de precios en ProductosCubit
      context.read<ProductosCubit>().updateListaPreciosInfo(
        cliente.listaPrecio!,
        listaCliente.nombre ?? 'Precio base',
      );

      // Forzar actualización de la UI para mostrar el cambio de lista de precios
      print('Actualizada lista de precios a: ${listaCliente.nombre} (ID: ${listaCliente.id})');
    }

    // Actualizar el texto del controlador
    _controller.text = cliente.nombre ?? '';
  }
}