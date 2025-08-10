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
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';
/// Widget para la búsqueda y selección de clientes
/// Permite buscar clientes por nombre o DNI y seleccionarlos
/// Cuando se selecciona un cliente, actualiza la lista de precios y limpia los productos
class BuscarClienteWidget extends StatefulWidget {
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
    // Filtrar clientes nulos o sin identificadores
    final clientesFiltrados = clientes.where(
      (cliente) => cliente.nombre != null && (cliente.dni != null || cliente.idCliente != null)
    ).toList();
    
    // Convertir la lista filtrada a SearchFieldListItem
    clienteSugerencias = clientesFiltrados.map((cliente) {
      // Crear un texto más descriptivo para mostrar
      final String displayText = '${cliente.nombre ?? 'Sin nombre'} ${cliente.dni != null ? '- DNI: ${cliente.dni}' : ''}';
      
      // Crear identificador único
      final String identifier = cliente.idCliente ?? cliente.dni ?? 'ID-${cliente.nombre}';
      
      return SearchFieldListItem<String>(
        displayText,
        item: identifier,
      );
    }).toList();
    
    setState(() {}); // Actualizar el estado para mostrar las sugerencias cargadas
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientesMostradorCubit, ClientesMostradorState>(
      listener: (context, state) {
        // Cuando hay cambios en el estado, cargamos las sugerencias
        if (state.clientes.isNotEmpty) {
          cargarSugerencias(state.clientes);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              SearchFieldListItem<String>? selectedCliente;
              
              try {
                // Buscar el cliente seleccionado en las sugerencias
                selectedCliente = clienteSugerencias.firstWhere(
                  (c) => c.searchKey == cliente.searchKey,
                );
              } catch (e) {
                print('Error al encontrar la sugerencia seleccionada: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al seleccionar el cliente')),
                );
                return;
              }
              
              if (selectedCliente == null) {
                print('Cliente seleccionado no encontrado');
                return;
              }
              // Acceder al estado del ClientesMostradorCubit para obtener la lista de clientes
              final clientes = context.read<ClientesMostradorCubit>().state.clientes;
              final value = context.read<ClientesMostradorCubit>().state.buscarCliente;
              // Buscar el cliente original en la lista de clientes basada en la búsqueda
              ClientesMostrador? clienteCorrespondiente;
              try {
                // Intentar encontrar el cliente en la lista
                clienteCorrespondiente = clientes.firstWhere(
                  (c) => c.dni == selectedCliente?.item || c.idCliente == selectedCliente?.item,
                );
              } catch (e) {
                // Si no se encuentra, asignamos null
                clienteCorrespondiente = null;
                print('Error al buscar cliente: $e');
              }
              
              // Verificar si se encontró el cliente
              if (clienteCorrespondiente == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cliente no encontrado')),
                );
                return;
              }

              // Si se encontró el cliente correspondiente, seleccionarlo
              // Como clienteCorrespondiente nunca será null (debido a firstWhere sin orElse), no necesitamos verificarlo
              try {
                // Mostrar el pop-up para notificar al usuario que los productos se limpiarán
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

                            // IMPORTANTE: Primero actualizar el cliente seleccionado
                            // Esto es clave para la sincronización con la lista de precios
                            context.read<ClientesMostradorCubit>().seleccionarCliente(clienteCorrespondiente!,value);

                            // Después limpiar los productos seleccionados
                            // Este orden es crucial para mantener la consistencia
                            context.read<ProductosCubit>().limpiarProductosSeleccionados();
                            
                            // Actualizar la información de la lista de precios del cliente
                            if (clienteCorrespondiente.listaPrecio != null) {
                              final listasPreciosCubit = context.read<ListaPreciosCubit>();
                              final listaPrecios = listasPreciosCubit.state.currentList;
                              final listaCliente = listaPrecios.firstWhere(
                                (lista) => lista.id == clienteCorrespondiente?.listaPrecio,
                                orElse: () => Lista(id: 1, nombre: 'Precio base'),
                              );
                              
                              // Actualizar la información de la lista de precios en ProductosCubit
                              context.read<ProductosCubit>().updateListaPreciosInfo(
                                clienteCorrespondiente.listaPrecio!,
                                listaCliente.nombre ?? 'Precio base',
                              );
                            }
                            
                            // Aquí podría agregarse actualización de precios basados en la lista del cliente
                            // Ejemplo: context.read<ProductosCubit>().actualizarPreciosSegunCliente(clienteCorrespondiente.listaPrecio);
                          },
                          child: Text('Aceptar'),
                        ),
                      ],
                    );
                  },
                );
                _controller.text = selectedCliente.searchKey;
              } catch (e) {
                print('Cliente no encontrado: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo seleccionar el cliente. Inténtelo de nuevo.')),
                );
              }
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
