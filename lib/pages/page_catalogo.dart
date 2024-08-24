import 'package:dropdown_search/dropdown_search.dart';
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
            BlocBuilder<ProductosCubit, ProductosState>(
              builder: (context, state) {

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
