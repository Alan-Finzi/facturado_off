// buscar_producto.dart

import 'package:facturador_offline/models/producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searchfield/searchfield.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/Producto_precio_stock.dart';
import '../pages/page_catalogo.dart';
class BuscarProductoScanner extends StatefulWidget {
  @override
  _BuscarProductoScannerState createState() => _BuscarProductoScannerState();
}

class _BuscarProductoScannerState extends State<BuscarProductoScanner> {
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
                      labelText: 'Buscar Producto con Scanner',
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

          ],
        );
      },
    );
  }
}



class BuscarProductoWidget extends StatefulWidget {
  @override
  _BuscarProductoWidgetState createState() => _BuscarProductoWidgetState();
}

class _BuscarProductoWidgetState extends State<BuscarProductoWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchFieldListItem<String>> productoSugerencias = [];

  @override
  void initState() {
    super.initState();
    // Carga los productos al inicializar el widget
    _initializeListaId();
  }

  void _initializeListaId() {
    final clientesMostradorCubit = context.read<ClientesMostradorCubit>();
    final loginCubit = context.read<LoginCubit>();

    // Determina el `listaId` basado en el cliente seleccionado o el usuario
    final listaId = (clientesMostradorCubit.state.clienteSeleccionado?.listaPrecio ??
        loginCubit.state.user?.idListaPrecio) ?? 1;

    // Cargar los productos con el `listaId` actualizado y sucursal
    context.read<ProductosConPrecioYStockCubit>().cargarProductosConPrecioYStock(
      listaId,
      loginCubit.state.user!.sucursal!,
    );
  }

  void cargarSugerencias(String query, List<ProductoConPrecioYStock> productos) {
    final keywords = query.toLowerCase().split(' ');

    // Filtra los productos con las palabras clave y los convierte en sugerencias
    productoSugerencias = productos
        .where((producto) {
      final textoProducto =
      '${producto.producto.name ?? ''} ${producto.producto.barcode ?? ''}'.toLowerCase();
      return keywords.every((keyword) => textoProducto.contains(keyword));
    })
        .map((producto) {
      return SearchFieldListItem<String>(
        producto.producto.name ?? 'Sin nombre',
        item: producto.producto.barcode ?? 'Sin código',
      );
    })
        .toList();

    setState(() {}); // Actualiza el estado para reflejar los cambios
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductosConPrecioYStockCubit, ProductosConPrecioYStockState>(
      listener: (context, state) {
        // Cuando los productos están disponibles, actualiza las sugerencias
        if (state.productos.isNotEmpty) {
          cargarSugerencias(_controller.text, state.productos);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            controller: _controller,
            focusNode: _focusNode,
            suggestions: productoSugerencias,
            suggestionState: Suggestion.expand,
            textInputAction: TextInputAction.done,
            searchInputDecoration: SearchInputDecoration(
              labelText: 'Buscar producto por nombre o código de barras',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _focusNode.unfocus();
                  setState(() {
                    productoSugerencias = []; // Limpia las sugerencias
                  });
                },
              ),
            ),
            maxSuggestionsInViewPort: 5,
            itemHeight: 50,
            onSearchTextChanged: (query) {
              final productosState = context.read<ProductosConPrecioYStockCubit>().state;
              cargarSugerencias(query, productosState.productos);
            },
            onSuggestionTap: (producto) {
              final productosState = context.read<ProductosConPrecioYStockCubit>().state;

              // Busca el producto completo seleccionado en la lista de productos del estado
              final selectedProducto = productosState.productos.firstWhere(
                    (p) => p.producto.barcode == producto.item,
              );

              // Convierte el modelo a un mapa
              final productoMap = selectedProducto.toMap();

              // Agrega el producto al carrito o lista de productos
              context.read<ProductosCubit>().agregarProducto(productoMap);

              // Limpia el campo de búsqueda después de la selección
              _controller.clear();
              setState(() {
                productoSugerencias = [];
              });
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
