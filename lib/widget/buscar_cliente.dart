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
  TextEditingController? _fieldController;
  FocusNode? _fieldFocusNode;

  @override
  void initState() {
    super.initState();
    context.read<ClientesMostradorCubit>().getClientesBD();
    context.read<ListaPreciosCubit>().getListasPreciosBD();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientesMostradorCubit, ClientesMostradorState>(
      listener: (context, state) {
        print('Estado de clientes actualizado: ${state.clientes.length} clientes');
        if (state.clienteSeleccionado != null && (_fieldController?.text.isEmpty ?? true)) {
          _fieldController?.text = state.clienteSeleccionado?.nombre ?? '';
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
                      _fieldController?.clear();
                      _fieldFocusNode?.requestFocus();
                    },
                    ),
                  ],
                ),
              ),

            // Campo de búsqueda de cliente
            Autocomplete<ClientesMostrador>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                if (query.isEmpty) return const Iterable<ClientesMostrador>.empty();
                return state.clientes.where((c) {
                  return (c.nombre?.toLowerCase().contains(query) ?? false) ||
                      (c.dni?.toLowerCase().contains(query) ?? false);
                }).take(5);
              },
              displayStringForOption: (c) => c.nombre ?? '',
              onSelected: (clienteCorrespondiente) {
                final value = context.read<ClientesMostradorCubit>().state.buscarCliente;
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
                              Navigator.of(context).pop();
                              _seleccionarCliente(context, clienteCorrespondiente, value);
                            },
                            child: Text('Aceptar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _seleccionarCliente(context, clienteCorrespondiente, value);
                }
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                _fieldController = textEditingController;
                _fieldFocusNode = focusNode;
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente o cuit',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        textEditingController.clear();
                        focusNode.unfocus();
                      },
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final cliente = options.elementAt(index);
                          return ListTile(
                            title: Text(cliente.nombre ?? ''),
                            subtitle: Text(cliente.dni ?? ''),
                            onTap: () => onSelected(cliente),
                          );
                        },
                      ),
                    ),
                  ),
                );
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

    _fieldFocusNode?.unfocus();
  }
}