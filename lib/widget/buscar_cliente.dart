import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/widget/mod_cliente_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import 'widget_alta_clientes.dart';
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';
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
    // Llama al método para cargar los clientes al iniciar el widget
    context.read<ClientesMostradorCubit>().getClientesBD();
  }

  void cargarSugerencias(List<ClientesMostrador> clientes) {
    // Convierte la lista de ClientesMostrador a SearchFieldListItem
    clienteSugerencias = clientes.map((cliente) {
      return SearchFieldListItem<String>(
        cliente.nombre ?? 'Sin nombre',
        item: cliente.dni ?? cliente.idCliente ?? 'Sin DNI',
      );
    }).toList();
    setState(() {}); // Actualiza el estado para mostrar las sugerencias cargadas
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
              final selectedCliente = clienteSugerencias.firstWhere(
                    (c) => c.searchKey == cliente.searchKey,
              );
              print('Cliente seleccionado: ${selectedCliente.searchKey} - DNI: ${selectedCliente.item}');
              _controller.text = selectedCliente.searchKey;
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
