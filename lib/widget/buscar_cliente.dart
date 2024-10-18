import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/widget/mod_cliente_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import 'widget_alta_clientes.dart';

class BuscarCliente extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final clientesCubit = context.watch<ClientesMostradorCubit>();
    final productosConPrecioYStockCubit = context.watch<ProductosConPrecioYStockCubit>();
    final productosSeleccionados = context.watch<ProductosCubit>();
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Buscar cliente o cuit',
            prefixIcon: Icon(Icons.person_search),
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AltaClienteDialog();
                  },
                );
              },
            ),
          ),
          onSubmitted: (query) async {
            // Realiza la búsqueda cuando se presiona Enter
            await clientesCubit.buscarCliente(query);
            if (clientesCubit.state.filteredClientes.isNotEmpty) {
              // Muestra el popup con los resultados
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text('Seleccionar cliente'),
                    children: clientesCubit.state.filteredClientes.map((cliente) {
                      return SimpleDialogOption(
                        onPressed: () async {
                          clientesCubit.seleccionarCliente(cliente);
                         final listaId = clientesCubit.state.clienteSeleccionado?.listaPrecio;
                          if (listaId != null) {
                            final listaPrecios = await productosConPrecioYStockCubit.cargarProductosConPrecioYStock(listaId);
                            productosSeleccionados.actualizarPreciosDeProductosSeleccionados(productosSeleccionados.state.productosSeleccionados, listaPrecios);
                          }

                          Navigator.pop(context); // Cierra el diálogo
                          _controller.text = cliente.dni ?? ''; // Coloca el DNI en el TextField
                        },
                        child: ListTile(
                          title: Text(cliente.nombre ?? 'No Name'),
                          subtitle: Text(cliente.dni ?? ''),
                        ),
                      );
                    }).toList(),
                  );
                },
              );

            } else {
              // Maneja el caso donde no hay resultados
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('No se encontraron resultados'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}