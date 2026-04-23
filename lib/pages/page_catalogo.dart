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

class CatalogoPage extends StatefulWidget {
  @override
  _CatalogoPageState createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todas las categorías';
  int limit = 100;
  int? _listaId;

  // IDs de productos con variaciones expandidos en la vista desktop
  final Set<int> _expandedProductIds = {};

  int get _sucursalId =>
      int.tryParse(User.currencyUser?.sucursal?.toString() ?? '') ?? 0;

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

    final listaId = (clientesMostradorCubit.state.clienteSeleccionado?.listaPrecio ??
            loginCubit.state.user?.idListaPrecio) ??
        1;

    if (_listaId != listaId) {
      setState(() {
        _listaId = listaId;
      });
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(_listaId!, _sucursalId);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    context.read<ProductosMaestroCubit>().filterProductosConPrecioYStock(
      query,
      _selectedCategoria == 'Todas las categorías' ? '' : _selectedCategoria,
    );
  }

  // --- Helpers de precio y stock ---

  String _getPrecio(Datum producto) {
    if (producto.productosVariaciones?.isNotEmpty == true) {
      return _getRangoPrecioVariaciones(producto.productosVariaciones!);
    }
    return producto.listasPrecios?.isNotEmpty == true
        ? (producto.listasPrecios!
                .firstWhere((lp) => lp.listaId == _listaId,
                    orElse: () => ListasPrecio(precioLista: '0.0'))
                .precioLista ??
            '0.0')
        : '0.0';
  }

  String _getRangoPrecioVariaciones(List<ProductosVariacione> variaciones) {
    final precios = variaciones
        .map((v) => double.tryParse(
              v.listasPrecios
                      ?.firstWhere((lp) => lp.listaId == _listaId,
                          orElse: () => ListasPrecio(precioLista: '0'))
                      .precioLista ??
                  '0',
            ) ??
            0.0)
        .where((p) => p > 0)
        .toList();

    if (precios.isEmpty) return 'Sin precio';
    final min = precios.reduce((a, b) => a < b ? a : b);
    final max = precios.reduce((a, b) => a > b ? a : b);
    if (min == max) return '\$${min.toStringAsFixed(2)}';
    return '\$${min.toStringAsFixed(2)} – \$${max.toStringAsFixed(2)}';
  }

  String _getPrecioVariacion(ProductosVariacione variacion) {
    return variacion.listasPrecios
            ?.firstWhere((lp) => lp.listaId == _listaId,
                orElse: () => ListasPrecio(precioLista: '0.0'))
            .precioLista ??
        '0.0';
  }

  String _getStock(List<Stock>? stocks) {
    if (stocks == null || stocks.isEmpty) return '0';
    final match = stocks.where((s) => s.sucursalId == _sucursalId);
    if (match.isNotEmpty) return match.first.stock ?? '0';
    return stocks.first.stock ?? '0';
  }

  // --- Acciones ---

  void _agregarProducto(Datum producto) {
    Navigator.pop(context, {'productoSeleccionado': producto, 'variacionSeleccionada': null});
  }

  void _agregarVariacion(Datum producto, ProductosVariacione variacion) {
    final productoConVariacion = Datum(
      id: producto.id,
      nombre: producto.nombre,
      barcode: producto.barcode,
      productoTipo: producto.productoTipo,
      categoryId: producto.categoryId,
      marcaId: producto.marcaId,
      proveedorId: producto.proveedorId,
      comercioId: producto.comercioId,
      productosVariaciones: [variacion],
      stocks: [],
      listasPrecios: [],
    );
    Navigator.pop(context, {'productoSeleccionado': productoConVariacion});
  }

  // --- Build principal ---

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
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar producto por nombre o código',
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Ejemplo: "azul verde" encontrará "producto azul y verde"',
                  helperText: 'Usa palabras clave en cualquier orden',
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
              _buildCategoryDropdown(),
              const SizedBox(height: 16.0),
              _buildProductTable(),
              const SizedBox(height: 16.0),
              BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
                builder: (context, state) {
                  final productos = state.filteredProductoResponse?.data?.isNotEmpty == true
                      ? state.filteredProductoResponse!.data!
                      : state.productoResponse?.data ?? [];
                  return productos.length > limit
                      ? ElevatedButton(
                          onPressed: () => setState(() => limit += 100),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Cargar más productos (${productos.length - limit} restantes)'),
                        )
                      : const SizedBox();
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
                          builder: (context, state) {
                            final productsCount = state.filteredProductoResponse?.data?.length ??
                                state.productoResponse?.data?.length ??
                                0;
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
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.errorMessage != null) return Text('Error: ${state.errorMessage}');

        final productos = state.filteredProductoResponse?.data ?? [];
        final categorias = productos
            .map((p) => p.categoriaName ?? 'Sin categoría')
            .toSet()
            .toList()
          ..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categorías de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownSearch<String>(
              items: ['Todas las categorías', ...categorias],
              selectedItem: _selectedCategoria,
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Seleccionar categoría',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (categoria) {
                if (categoria != null) {
                  setState(() => _selectedCategoria = categoria);
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
                    hintText: 'Buscar categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, item, isSelected) => ListTile(
                  title: Text(item),
                  selected: isSelected,
                  tileColor: isSelected ? Colors.grey[200] : null,
                ),
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
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.errorMessage != null) {
          return Center(
            child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
          );
        }

        final productos = state.filteredProductoResponse?.data?.isNotEmpty == true
            ? state.filteredProductoResponse!.data!
            : state.productoResponse?.data ?? [];

        if (productos.isEmpty) return const Center(child: Text('No hay productos disponibles.'));

        final visibles = productos.take(limit).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 700) return _buildDesktopTable(visibles);
            return _buildMobileList(visibles);
          },
        );
      },
    );
  }

  // =========== DESKTOP ===========

  Widget _buildDesktopTable(List<Datum> productos) {
    return Column(
      children: [
        _buildDesktopHeader(),
        const Divider(height: 1, thickness: 1),
        ...productos.map(_buildDesktopProductRow),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 100, child: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDesktopProductRow(Datum producto) {
    final hasVariaciones = producto.productosVariaciones?.isNotEmpty == true;

    if (!hasVariaciones) {
      return _buildDesktopSimpleRow(producto);
    }

    final isExpanded = _expandedProductIds.contains(producto.id);
    final varCount = producto.productosVariaciones!.length;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedProductIds.remove(producto.id);
            } else {
              _expandedProductIds.add(producto.id!);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          producto.nombre ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(producto.barcode ?? 'N/A')),
                Expanded(
                  flex: 3,
                  child: Text(
                    _getRangoPrecioVariaciones(producto.productosVariaciones!),
                    style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$varCount var.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                Expanded(flex: 2, child: Text(producto.categoriaName ?? 'Sin categoría')),
                const SizedBox(width: 100),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...producto.productosVariaciones!
              .map((v) => _buildDesktopVariacionRow(producto, v)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDesktopSimpleRow(Datum producto) {
    final precio = _getPrecio(producto);
    final stock = _getStock(producto.stocks);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(producto.nombre ?? 'N/A')),
              Expanded(flex: 2, child: Text(producto.barcode ?? 'N/A')),
              Expanded(flex: 3, child: Text('\$$precio')),
              Expanded(flex: 2, child: Text(stock)),
              Expanded(flex: 2, child: Text(producto.categoriaName ?? 'Sin categoría')),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () => _agregarProducto(producto),
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDesktopVariacionRow(Datum producto, ProductosVariacione variacion) {
    final precio = _getPrecioVariacion(variacion);
    final stock = _getStock(variacion.stocks);

    return Container(
      color: Colors.blue.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      variacion.variaciones ?? 'Sin descripción',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(variacion.codigoVariacion ?? '-', style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              flex: 3,
              child: Text('\$$precio', style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text(stock, style: const TextStyle(fontSize: 13)),
            ),
            const Expanded(flex: 2, child: SizedBox()),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _agregarVariacion(producto, variacion),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Agregar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========== MOBILE ===========

  Widget _buildMobileList(List<Datum> productos) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        final hasVariaciones = producto.productosVariaciones?.isNotEmpty == true;

        if (!hasVariaciones) {
          final precio = _getPrecio(producto);
          final stock = _getStock(producto.stocks);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(producto.nombre ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Cód: ${producto.barcode ?? '-'}  |  \$$precio  |  Stock: $stock\n${producto.categoriaName ?? ''}',
              ),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () => _agregarProducto(producto),
                child: const Text('Agregar'),
              ),
            ),
          );
        }

        final varCount = producto.productosVariaciones!.length;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.layers, color: Colors.blue, size: 22),
            title: Text(producto.nombre ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '$varCount variaciones  |  ${_getRangoPrecioVariaciones(producto.productosVariaciones!)}  |  ${producto.categoriaName ?? ''}',
            ),
            children: producto.productosVariaciones!.map((variacion) {
              final precio = _getPrecioVariacion(variacion);
              final stock = _getStock(variacion.stocks);
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 12),
                leading: const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.grey),
                title: Text(variacion.variaciones ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text('\$$precio  |  Stock: $stock'),
                trailing: ElevatedButton(
                  onPressed: () => _agregarVariacion(producto, variacion),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Agregar'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
