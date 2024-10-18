import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
class CatalogoPage extends StatefulWidget {
  @override
  _CatalogoPageState createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todas las categorías'; // Almacena la categoría seleccionada
  int limit = 100; // Número de productos a mostrar inicialmente

  @override
  void initState() {
    super.initState();
    final productosConPrecioYStockCubit = context.read<ProductosConPrecioYStockCubit>();
    final clientesMostradorCubit = context.read<ClientesMostradorCubit>();
    final loginCubit = context.read<LoginCubit>();

    // Determinar el listaId basado en el cliente seleccionado o el usuario
    final listaId = clientesMostradorCubit.state.clienteSeleccionado?.listaPrecio
        ?? loginCubit.state.user?.idListaPrecio
        ?? 1;

    // Cargar los productos con precio, stock y IVA una vez cuando se construye la página
    productosConPrecioYStockCubit.cargarProductosConPrecioYStock(listaId);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      productosConPrecioYStockCubit.filterProductosConPrecioYStock(
        query,
        _selectedCategoria == 'Todas las categorías' ? '' : _selectedCategoria, // Respetar la categoría
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar producto por nombre o código',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16.0),
              BlocBuilder<ProductosConPrecioYStockCubit, ProductosConPrecioYStockState>(
                builder: (context, productosConPrecioYStockState) {
                  // Extraemos las categorías de los productos cargados
                  final categorias = productosConPrecioYStockState.productos
                      .map((productoConPrecioYStock) => productoConPrecioYStock.categoria ?? 'Sin categoría')
                      .toSet()
                      .toList();

                  return DropdownSearch<String>(
                    items: ['Todas las categorías', ...categorias],
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Seleccionar categoría",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    selectedItem: _selectedCategoria, // Mantener la categoría seleccionada
                    onChanged: (categoria) {
                      if (categoria != null) {
                        setState(() {
                          _selectedCategoria = categoria;
                        });

                        // Aplicar filtro respetando el texto de búsqueda actual
                        context.read<ProductosConPrecioYStockCubit>().filterProductosConPrecioYStock(
                          _searchController.text.toLowerCase(),
                          categoria == 'Todas las categorías' ? '' : categoria,
                        );
                      }
                    },
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Buscar categoría",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(
                          title: Text(item),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0),
              BlocBuilder<ProductosConPrecioYStockCubit, ProductosConPrecioYStockState>(
                builder: (context, productosConPrecioYStockState) {
                  if (productosConPrecioYStockState.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (productosConPrecioYStockState.errorMessage != null) {
                    return Text('Error: ${productosConPrecioYStockState.errorMessage}');
                  }

                  final productos = productosConPrecioYStockState.filteredProductosConPrecioYStock.isNotEmpty
                      ? productosConPrecioYStockState.filteredProductosConPrecioYStock
                      : productosConPrecioYStockState.productos;

                  final limitedList = productos.take(limit).map((productoConPrecioYStock) {
                    return DataRow(cells: [
                      DataCell(Text(productoConPrecioYStock.producto.name ?? '')),
                      DataCell(Text(productoConPrecioYStock.producto.barcode ?? '')),
                      DataCell(Text('\$${productoConPrecioYStock.precioLista?.toStringAsFixed(2) ?? '0.00'}')),
                      DataCell(Text('${productoConPrecioYStock.stock ?? 0}')),
                      DataCell(Text('${productoConPrecioYStock.iva?.toStringAsFixed(2) ?? '0.00'}%')),
                      DataCell(Text(productoConPrecioYStock.categoria ?? 'Sin categoría')),
                      DataCell(
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'codigo': productoConPrecioYStock.producto.barcode,
                              'nombre': productoConPrecioYStock.producto.name,
                              'precio': productoConPrecioYStock.precioLista,
                              'iva': productoConPrecioYStock.iva,
                            });
                          },
                          child: Text('Agregar'),
                        ),
                      ),
                    ]);
                  }).toList();

                  return Column(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Precio de Lista')),
                          DataColumn(label: Text('Stock')),
                          DataColumn(label: Text('IVA')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: limitedList,
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            limit += 100; // Incrementar el límite de productos a mostrar
                          });
                        },
                        child: Text('Cargar más productos'),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
