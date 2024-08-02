import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';

class CatalogoPage extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productosCubit = context.watch<ProductosCubit>();

    _searchController.addListener(() {
      productosCubit.filterProducts(_searchController.text, productosCubit.state.categoriaSeleccionada);
    });

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
              decoration: InputDecoration(
                labelText: 'Buscar producto por nombre o código',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16.0),
            BlocBuilder<ProductosCubit, ProductosState>(
              builder: (context, state) {
                return DropdownButton<String>(
                  value: state.categoriaSeleccionada.isEmpty ? 'Todas las categorías' : state.categoriaSeleccionada,
                  hint: const Text('Seleccionar categoría'),
                  items: state.categorias.map((categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (categoria) {
                    if (categoria != null) {
                      productosCubit.setCategoriaSeleccionada(categoria);
                    } else {
                      productosCubit.setCategoriaSeleccionada('Todas las categorías');
                    }
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            BlocBuilder<ProductosCubit, ProductosState>(
              builder: (context, state) {
                if (state.filteredListProductCubit == null || state.filteredListProductCubit!.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                return Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Precio')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: state.filteredListProductCubit!.map((producto) {
                      return DataRow(cells: [
                        DataCell(Text(producto.name ?? '')),
                        DataCell(Text(producto.barcode ?? '')),
                        DataCell(Text('\$${producto.precioInterno?.toStringAsFixed(2) ?? '0.00'}')),
                        DataCell(Text(producto.tipoProducto ?? 'Sin categoría')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'codigo': producto.barcode,
                                'nombre': producto.name,
                                'precio': producto.precioInterno,
                              });
                            },
                            child: Text('Agregar'),
                          ),
                        ),
                      ]);
                    }).toList(),
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
