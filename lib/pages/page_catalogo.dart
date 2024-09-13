import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_productos_stock_sucursales/productos_stock_sucursales_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../models/Producto_precio_stock.dart';
class CatalogoPage extends StatefulWidget {
  @override
  _CatalogoPageState createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();

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
    productosConPrecioYStockCubit.getProductosConPrecioYStock(listaId);

    _searchController.addListener(() {
      context.read<ProductosCubit>().filterProducts(
        _searchController.text,
        context.read<ProductosCubit>().state.categoriaSeleccionada,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final productosCubit = context.watch<ProductosCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            BlocBuilder<ProductosCubit, ProductosState>(
              builder: (context, state) {
                return DropdownSearch<String>(
                  items: state.categorias,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Seleccionar categoría",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  selectedItem: state.categoriaSeleccionada.isEmpty
                      ? 'Todas las categorías'
                      : state.categoriaSeleccionada,
                  onChanged: (categoria) {
                    if (categoria != null) {
                      productosCubit.setCategoriaSeleccionada(categoria);
                    } else {
                      productosCubit.setCategoriaSeleccionada('Todas las categorías');
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
                  return CircularProgressIndicator();
                }

                if (productosConPrecioYStockState.errorMessage != null) {
                  return Text('Error: ${productosConPrecioYStockState.errorMessage}');
                }

                final filteredList = productosConPrecioYStockState.productos?.map((productoConPrecioYStock) {
                  return DataRow(cells: [
                    DataCell(Text(productoConPrecioYStock.producto.name ?? '')),
                    DataCell(Text(productoConPrecioYStock.producto.barcode ?? '')),
                    DataCell(Text('\$${productoConPrecioYStock.precioLista?.toStringAsFixed(2) ?? '0.00'}')),
                    DataCell(Text('${productoConPrecioYStock.stock ?? 0}')),
                    DataCell(Text('${productoConPrecioYStock.iva?.toStringAsFixed(2) ?? '0.00'}%')),  // Nueva columna IVA
                    DataCell(Text(productoConPrecioYStock.producto.tipoProducto ?? 'Sin categoría')),
                    DataCell(
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'codigo': productoConPrecioYStock.producto.barcode,
                            'nombre': productoConPrecioYStock.producto.name,
                            'precio': productoConPrecioYStock.precioLista,
                            'iva': productoConPrecioYStock.iva,  // Agregar IVA en el botón "Agregar"
                          });
                        },
                        child: Text('Agregar'),
                      ),
                    )
                  ]);
                }).toList() ?? [];

                return Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Precio de Lista')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('IVA')),  // Nueva columna IVA
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: filteredList,
                  ),
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
    );
  }
}