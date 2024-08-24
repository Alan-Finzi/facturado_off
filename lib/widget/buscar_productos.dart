// buscar_producto.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_productos/productos_cubit.dart';
import '../pages/page_catalogo.dart';
class BuscarProducto extends StatefulWidget {
  @override
  _BuscarProductoState createState() => _BuscarProductoState();
}

class _BuscarProductoState extends State<BuscarProducto> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  late Map<String, dynamic> productoBuscador;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductosCubit, ProductosState>(
      builder: (context, state) {
        final todosLosProductos = state.currentListProductCubit.map((producto) {
          return {
            'codigo': producto.barcode,
            'nombre': producto.name,
            'precio': producto.id,
          };
        }).toList();

        return Row(
          children: [
            Expanded(
              child: Autocomplete<Map<String, dynamic>>(

                optionsBuilder: (TextEditingValue textEditingValue) {
                  final input = textEditingValue.text.toLowerCase();
                  if (input.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  return todosLosProductos.where((Map<String, dynamic> producto) {
                    return producto['codigo'].toLowerCase().contains(input) ||
                        producto['nombre'].toLowerCase().contains(input);
                  }).toList();
                },
                displayStringForOption: (Map<String, dynamic> producto) => producto['codigo'],
                onSelected: (Map<String, dynamic> selection) {
                  context.read<ProductosCubit>().agregarProducto(selection);
                  _textEditingController.clear(); // Clear the text field after selection
                  FocusScope.of(context).requestFocus(_focusNode);// Request focus again
                },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        final matchedProduct = todosLosProductos.firstWhere(
                              (producto) => producto['codigo'] == value,
                          orElse: () => {},
                        );
                        productoBuscador = matchedProduct;
                        if (matchedProduct.isNotEmpty) {
                          context.read<ProductosCubit>().agregarProducto(matchedProduct);
                          context.read<ProductosCubit>().actualizarPrecioTotalProducto(matchedProduct);
                          _textEditingController.clear();

                          // Clear the text field after adding the product
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Producto no encontrado')),
                          );
                          // Clear the text field if the product is not found
                        }
                      }
                      FocusScope.of(context).requestFocus(focusNode);
                      textEditingController.clear();
                      _textEditingController.clear();// Ensure focus after submit
                    },
                    decoration: const InputDecoration(
                      labelText: 'Buscar por código o nombre del producto',
                      prefixIcon: Icon(Icons.search),
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      child: Container(
                        width: 300,
                        child: ListView.builder(
                          padding: EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Map<String, dynamic> option = options.elementAt(index);
                            return GestureDetector(

                              onTap: () {
                                onSelected(option);
                                context.read<ProductosCubit>().actualizarPrecioTotalProducto(option);
                                _textEditingController.clear();
                              },
                              child: ListTile(
                                title: Text(option['codigo']),
                                subtitle: Text(option['nombre']),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CatalogoPage()),
                );
                if (result != null) {
                  context.read<ProductosCubit>().agregarProducto(result);
                }
              },
              child: const Text('Ver catálogo'),
            ),
          ],
        );
      },
    );
  }
}
