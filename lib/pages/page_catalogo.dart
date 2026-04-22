import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../models/Producto_precio_stock.dart';
import '../models/productos_maestro.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogoPage extends StatefulWidget {
  @override
  _CatalogoPageState createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todas las categorías';
  int limit = 100;
  int? _listaId;

  @override
  void initState() {
    super.initState();
    _initializeListaId();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeListaId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  

  void _initializeListaId() {
    final clientesMostradorCubit = context.read<ClientesMostradorCubit>();
    final loginCubit = context.read<LoginCubit>();
    final user = User.currencyUser;

    final sucursalId = int.tryParse(user?.sucursal?.toString() ?? '') ?? 0;


    final listaId = (clientesMostradorCubit.state.clienteSeleccionado?.listaPrecio ??
        loginCubit.state.user?.idListaPrecio) ??
        1;

    if (_listaId != listaId) {
      setState(() {
        _listaId = listaId;
      });

      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(_listaId!, sucursalId);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    context.read<ProductosMaestroCubit>().filterProductosConPrecioYStock(
      query,
      _selectedCategoria == 'Todas las categorías' ? '' : _selectedCategoria,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Search Field with improved description
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar producto por nombre o código',
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Ejemplo: "azul verde" encontrará "producto azul y verde"',
                  helperText: 'Usa palabras clave en cualquier orden',
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _onSearchChanged();
                          });
                        },
                      )
                    : null,
                ),
                onSubmitted: (_) => _onSearchChanged(),
              ),
              const SizedBox(height: 16.0),

              // Dropdown for Categories
              _buildCategoryDropdown(),

              const SizedBox(height: 16.0),

              // Product Table
              _buildProductTable(),

              const SizedBox(height: 16.0),

              // Load More Button
              BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
                builder: (context, state) {
                  final productos = state.filteredProductoResponse?.data?.isNotEmpty == true
                    ? state.filteredProductoResponse!.data!
                    : state.productoResponse?.data ?? [];
                    
                  return productos.length > limit
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            limit += 100;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Cargar más productos (${productos.length - limit} restantes)'),
                      )
                    : SizedBox();
                },
              ),

              const SizedBox(height: 16.0),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Close Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Stats display
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
                          builder: (context, state) {
                            final productsCount = state.filteredProductoResponse?.data?.length ?? 
                                                state.productoResponse?.data?.length ?? 0;
                            
                            return Text(
                              'Mostrando ${productsCount < limit ? productsCount : limit} de $productsCount productos',
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Text('Error: ${state.errorMessage}');
        }

        final productos = state.filteredProductoResponse?.data ?? [];

        // Obtener nombres únicos de categoría y ordenarlos alfabéticamente
        final categorias = productos
            .map((producto) => producto.categoriaName ?? 'Sin categoría')
            .toSet()
            .toList()
            ..sort(); // Ordenar alfabéticamente para mejor experiencia de usuario

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categorías de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownSearch<String>(
              items: ['Todas las categorías', ...categorias],
              selectedItem: _selectedCategoria,
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Seleccionar categoría",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (categoria) {
                if (categoria != null) {
                  setState(() {
                    _selectedCategoria = categoria;
                  });
                  context.read<ProductosMaestroCubit>().filterProductosConPrecioYStock(
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
                    selected: isSelected,
                    tileColor: isSelected ? Colors.grey[200] : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('${categorias.length} categorías disponibles', 
                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        );
      },
    );
  }

  Widget _buildProductTable() {
    return BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(
            child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
          );
        }

        final productos = state.filteredProductoResponse?.data?.isNotEmpty == true
            ? state.filteredProductoResponse!.data!
            : state.productoResponse?.data ?? [];

        if (productos.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        final visibles = productos.take(limit).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 700) {
              return _buildProductDataTable(visibles);
            }
            return _buildProductCardList(visibles);
          },
        );
      },
    );
  }

  Widget _buildProductDataTable(List<Datum> productos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Precio')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Acción')),
        ],
        rows: productos.map((producto) {
          final listaPrecio = _getPrecio(producto);
          final stock = producto.stocks?.isNotEmpty == true
              ? (producto.stocks!.first.stock?.toString() ?? '0')
              : '0';
          return DataRow(cells: [
            DataCell(Text(producto.nombre ?? 'N/A')),
            DataCell(Text(producto.barcode ?? 'N/A')),
            DataCell(Text(listaPrecio)),
            DataCell(Text(stock)),
            DataCell(Text(producto.categoriaName ?? 'Sin categoría')),
            DataCell(_buildAgregarButton(producto)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildProductCardList(List<Datum> productos) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        final precio = _getPrecio(producto);
        final stock = producto.stocks?.isNotEmpty == true
            ? (producto.stocks!.first.stock?.toString() ?? '0')
            : '0';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(producto.nombre ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Cód: ${producto.barcode ?? '-'}  |  \$$precio  |  Stock: $stock\n${producto.categoriaName ?? ''}'),
            isThreeLine: true,
            trailing: _buildAgregarButton(producto),
          ),
        );
      },
    );
  }

  String _getPrecio(Datum producto) {
    if (producto.productosVariaciones?.any((v) => v.listasPrecios?.isNotEmpty == true) ?? false) {
      return 'con variación';
    }
    return producto.listasPrecios?.isNotEmpty == true
        ? (producto.listasPrecios!
                .firstWhere((lp) => lp.listaId == _listaId, orElse: () => ListasPrecio(precioLista: '0.0'))
                .precioLista ?? '0.0')
        : '0.0';
  }

  Widget _buildAgregarButton(Datum producto) {
    return ElevatedButton(
      onPressed: () async {
        if (producto.productosVariaciones?.isNotEmpty ?? false) {
          await mostrarVariacionesPopup(context, producto, 0, 317);
        } else {
          Navigator.pop(context, {'productoSeleccionado': producto, 'variacionSeleccionada': null});
        }
      },
      child: const Text('Agregar'),
    );
  }


  Future<void> mostrarVariacionesPopup(
      BuildContext context,
      Datum producto,
      int listaId,
      int sucursalId,
      ) async {
    final variacionSeleccionada = await showDialog<ProductosVariacione>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar Variación"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: producto.productosVariaciones?.length ?? 0,
              itemBuilder: (context, index) {
                final variacion = producto.productosVariaciones![index];

                // Filtrar el stock por sucursal
                final stock = variacion.stocks
                    ?.firstWhere((s) => s.sucursalId == sucursalId, orElse: () => Stock(stock: "0")) ??
                    Stock(stock: "0");

                // Filtrar el precio por lista
                final precio = variacion.listasPrecios
                    ?.firstWhere((lp) => lp.listaId == listaId, orElse: () => ListasPrecio(precioLista: "0")) ??
                    ListasPrecio(precioLista: "0");

                return ListTile(
                  title: Text(variacion.variaciones ?? "Sin descripción"),
                  subtitle: Text("Stock: ${stock.stock}, Precio: \$${precio.precioLista}"),
                  onTap: () => Navigator.pop(context, variacion),
                );
              },
            ),
          ),
        );
      },
    );

    if (variacionSeleccionada != null) {
      // Devolver producto con solo la variación seleccionada
      final productoConUnaSolaVariacion = Datum(
        id: producto.id,
        nombre: producto.nombre,
        barcode: producto.barcode,
        productoTipo: producto.productoTipo,
        categoryId: producto.categoryId,
        marcaId: producto.marcaId,
        proveedorId: producto.proveedorId,
        comercioId: producto.comercioId,
        productosVariaciones: [variacionSeleccionada],
        stocks: [], // Podés agregar acá también si necesitás incluirlo
        listasPrecios: [],
      );

      Navigator.pop(context, {'productoSeleccionado': productoConUnaSolaVariacion});
    }
  }

}



