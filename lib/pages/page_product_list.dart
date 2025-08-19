import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../models/productos_maestro.dart';
import '../models/user.dart';
import '../helper/database_helper.dart';

class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedListaId; // Lista predeterminada - usamos null para iniciar
  int? _selectedSucursalId; // Sucursal predeterminada - usamos null para iniciar
  String _sortBy = 'nombre'; // nombre, codigo, precio
  String _sortDirection = 'asc'; // asc, desc
  List<Lista> _listasPrecios = [];
  List<Map<String, dynamic>> _sucursales = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _cargarDatosIniciales();
  }
  
  void _cargarDatosIniciales() async {
    final user = User.currencyUser;
    
    // Primero cargamos las listas de precios y sucursales
    await _cargarListasPrecios();
    await _cargarSucursales();
    
    // Luego establecemos los valores predeterminados basados en lo que hay disponible
    setState(() {
      // Para sucursal, usamos la del usuario o la primera disponible
      int? userSucursal = int.tryParse(user?.sucursal?.toString() ?? '');
      if (_sucursales.isNotEmpty) {
        if (userSucursal != null && _sucursales.any((s) => s['id'] == userSucursal)) {
          _selectedSucursalId = userSucursal;
        } else {
          _selectedSucursalId = _sucursales.first['id'];
        }
      }
      
      // Para lista de precios, usamos la primera disponible si hay alguna
      if (_listasPrecios.isNotEmpty) {
        _selectedListaId = _listasPrecios.first.id;
      }
    });
    
    // Finalmente cargamos los productos
    await _cargarTodosProductos(); // Carga todos los productos primero
    
    if (_selectedListaId != null) {
      await _cargarProductosLista(); // Carga productos por lista de precio
    }
    
    if (_selectedSucursalId != null) {
      await _cargarProductosStock(); // Carga productos por stock y sucursal
    }
  }
  
  // Carga productos filtrados por lista de precio para la pestaña PRECIOS
  Future<void> _cargarProductosLista() async {
    if (_selectedListaId == null) return;
    context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(_selectedListaId!, -1); // Usamos -1 para evitar conflictos
    print('Productos filtrados por lista $_selectedListaId cargados');
  }
  
  // Carga productos filtrados por stock y sucursal para la pestaña STOCK
  Future<void> _cargarProductosStock() async {
    if (_selectedSucursalId == null) return;
    context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, _selectedSucursalId!); // Usamos -1 para evitar conflictos
    print('Productos filtrados por sucursal $_selectedSucursalId cargados');
  }
  
  // Carga todos los productos independientemente del stock o lista de precio para la pestaña CATÁLOGO
  Future<void> _cargarTodosProductos() async {
    context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, -1); // Usamos -1 para todos
    print('Todos los productos cargados');
  }
  
  // Carga las listas de precios disponibles para el selector de la pestaña PRECIOS
  Future<void> _cargarListasPrecios() async {
    try {
      final listas = await DatabaseHelper.instance.getListaPrecios();
      setState(() {
        _listasPrecios = listas;
      });
      print('${listas.length} listas de precios cargadas');
    } catch (e) {
      print('Error al cargar listas de precios: $e');
      setState(() {
        _listasPrecios = [];
      });
    }
  }
  
  // Carga las sucursales disponibles para el selector de la pestaña STOCK
  Future<void> _cargarSucursales() async {
    try {
      final sucursales = await DatabaseHelper.instance.getSucursales();
      setState(() {
        _sucursales = sucursales;
      });
      print('${sucursales.length} sucursales cargadas');
    } catch (e) {
      print('Error al cargar sucursales: $e');
      // Fallback en caso de error
      setState(() {
        _sucursales = [
          {'id': 0, 'nombre': 'Casa Central'}
        ];
      });
    }
  }
  
  void _handleTabChange() {
    // Actualizar UI según la pestaña seleccionada
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Productos"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "CATÁLOGO"),
            Tab(text: "PRECIOS"),
            Tab(text: "STOCK"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCatalogoTab(), // CATÁLOGO
          _buildPreciosTab(), // PRECIOS
          _buildStockTab(), // STOCK
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Recargar primero datos básicos y luego los específicos según pestaña
          await _cargarListasPrecios();
          await _cargarSucursales();
          
          // Recargar los datos según la pestaña activa
          if (_tabController.index == 0) {
            await _cargarTodosProductos();
          } else if (_tabController.index == 1) {
            await _cargarProductosLista();
          } else if (_tabController.index == 2) {
            await _cargarProductosStock();
          }
        },
        tooltip: 'Recargar datos',
        child: Icon(Icons.refresh),
      ),
    );
  }

  // Pestaña de Catálogo - Muestra el listado principal
  Widget _buildCatalogoTab() {
    return Column(
      children: [
        _buildFilterAndSearch(),
        _buildCatalogoTableHeader(),
        Expanded(
          child: _buildCatalogoRows(),
        ),
      ],
    );
  }
  
  // Pestaña de Precios - Muestra todas las listas de precios
  Widget _buildPreciosTab() {
    return Column(
      children: [
        _buildPreciosFilter(),
        _buildPreciosTableHeader(),
        Expanded(
          child: _buildPreciosRows(),
        ),
      ],
    );
  }
  
  // Pestaña de Stock - Muestra el stock por sucursal
  Widget _buildStockTab() {
    return Column(
      children: [
        _buildStockFilter(),
        _buildStockTableHeader(),
        Expanded(
          child: _buildStockRows(),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _showSortOptions(context);
            },
            icon: Icon(Icons.filter_list),
            label: Text('Ordenar'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Buscar por nombre o código...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                ),
              ),
              onChanged: (value) {
                // Búsqueda en tiempo real
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              // Lógica para exportar
            },
            child: Text('Exportar'),
          ),
        ],
      ),
    );
  }
  
  // Filtro especial para la pestaña de precios
  Widget _buildPreciosFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _showSortOptions(context);
            },
            icon: Icon(Icons.filter_list),
            label: Text('Ordenar'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _listasPrecios.isEmpty
                ? DropdownButton<int?>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: null,
                    hint: Text("No hay listas disponibles"),
                    items: [],
                    onChanged: null, // Deshabilitado si no hay listas
                  )
                : DropdownButton<int?>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: _selectedListaId,
                    hint: Text("Seleccionar lista de precios"),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas las listas'),
                      ),
                      ..._listasPrecios
                        .where((lista) => lista.id != null)
                        .map((lista) => DropdownMenuItem<int?>(
                          value: lista.id,
                          child: Text(lista.nombre ?? 'Lista ${lista.id}'),
                        )).toList(),
                    ],
                onChanged: (value) {
                  setState(() {
                    _selectedListaId = value;
                    _cargarProductosLista(); // Siempre recargamos
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Buscar por nombre o código...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Filtro especial para la pestaña de stock
  Widget _buildStockFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _showSortOptions(context);
            },
            icon: Icon(Icons.filter_list),
            label: Text('Ordenar'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _sucursales.isEmpty
                ? DropdownButton<int?>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: null,
                    hint: Text("No hay sucursales disponibles"),
                    items: [],
                    onChanged: null, // Deshabilitado si no hay sucursales
                  )
                : DropdownButton<int?>(
                    isExpanded: true,
                    underline: SizedBox(),
                    value: _selectedSucursalId,
                    hint: Text("Seleccionar sucursal"),
                    items: _sucursales
                        .map((sucursal) => DropdownMenuItem<int?>(
                          value: sucursal['id'],
                          child: Text(sucursal['nombre'] ?? 'Sucursal ${sucursal['id']}'),
                        ))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSucursalId = value;
                    _cargarProductosStock(); // Siempre recargamos
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Buscar por nombre o código...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Nombre'),
              leading: Radio<String>(
                value: 'nombre',
                groupValue: _sortBy,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Código'),
              leading: Radio<String>(
                value: 'codigo',
                groupValue: _sortBy,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Precio'),
              leading: Radio<String>(
                value: 'precio',
                groupValue: _sortBy,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _sortDirection = 'asc';
                    });
                  },
                  icon: Icon(Icons.arrow_upward),
                  label: Text('Ascendente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sortDirection == 'asc' ? Colors.blue : Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _sortDirection = 'desc';
                    });
                  },
                  icon: Icon(Icons.arrow_downward),
                  label: Text('Descendente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sortDirection == 'desc' ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogoTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (bool? value) {}),
          _buildTableHeaderCell('Nombre del producto', flex: 2),
          _buildTableHeaderCell('SKU', flex: 1),
          _buildTableHeaderCell('Precio', flex: 1),
          _buildTableHeaderCell('Precio Lista mayorista', flex: 1),
          _buildTableHeaderCell('Stock', flex: 1),
        ],
      ),
    );
  }
  
  Widget _buildPreciosTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (bool? value) {}),
          _buildTableHeaderCell('Nombre del producto', flex: 2),
          _buildTableHeaderCell('SKU', flex: 1),
          ...(_selectedListaId == -1 ? 
            _listasPrecios.take(3).map((lista) => _buildTableHeaderCell(lista.nombre ?? 'Lista ${lista.id}', flex: 1)).toList() :
            [_buildTableHeaderCell('Precio Lista ${_selectedListaId}', flex: 2)])
        ],
      ),
    );
  }
  
  Widget _buildStockTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (bool? value) {}),
          _buildTableHeaderCell('Nombre del producto', flex: 2),
          _buildTableHeaderCell('SKU', flex: 1),
          _buildTableHeaderCell('Stock en ${_getNombreSucursal(_selectedSucursalId!)}', flex: 2),
        ],
      ),
    );
  }
  
  String _getNombreSucursal(int sucursalId) {
    final sucursal = _sucursales.firstWhere(
      (s) => s['id'] == sucursalId, 
      orElse: () => {'id': sucursalId, 'nombre': 'Sucursal $sucursalId'}
    );
    return sucursal['nombre'];
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Ordenar productos según criterio seleccionado
  List<Datum> _getSortedProducts(List<Datum> productos) {
    // Crear una copia para no modificar la original
    final sortedProducts = List<Datum>.from(productos);
    
    sortedProducts.sort((a, b) {
      if (_sortBy == 'nombre') {
        final nombreA = a.nombre?.toLowerCase() ?? '';
        final nombreB = b.nombre?.toLowerCase() ?? '';
        return _sortDirection == 'asc' ? nombreA.compareTo(nombreB) : nombreB.compareTo(nombreA);
      } 
      else if (_sortBy == 'codigo') {
        final codigoA = a.barcode?.toLowerCase() ?? '';
        final codigoB = b.barcode?.toLowerCase() ?? '';
        return _sortDirection == 'asc' ? codigoA.compareTo(codigoB) : codigoB.compareTo(codigoA);
      }
      else if (_sortBy == 'precio') {
        // Comparar por precio
        final precioA = double.tryParse(
          a.listasPrecios?.firstWhere(
            (lp) => lp.listaId == _selectedListaId,
            orElse: () => ListasPrecio(precioLista: '0.0')
          ).precioLista ?? '0.0'
        ) ?? 0.0;
        
        final precioB = double.tryParse(
          b.listasPrecios?.firstWhere(
            (lp) => lp.listaId == _selectedListaId,
            orElse: () => ListasPrecio(precioLista: '0.0')
          ).precioLista ?? '0.0'
        ) ?? 0.0;
        
        return _sortDirection == 'asc' ? precioA.compareTo(precioB) : precioB.compareTo(precioA);
      }
      
      return 0;
    });
    
    return sortedProducts;
  }
  
  // Filtrar productos por búsqueda
  List<Datum> _getFilteredProducts(List<Datum> productos) {
    if (_searchQuery.isEmpty) {
      return productos;
    }
    
    return productos.where((producto) => 
      (producto.nombre?.toLowerCase().contains(_searchQuery) ?? false) ||
      (producto.barcode?.toLowerCase().contains(_searchQuery) ?? false)
    ).toList();
  }

  // Filas para la pestaña de catálogo
  Widget _buildCatalogoRows() {
    return BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (state.errorMessage != null) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }
        
        final productos = state.filteredProductoResponse?.data ?? 
                         state.productoResponse?.data ?? [];
        
        if (productos.isEmpty) {
          return Center(child: Text('No se encontraron productos'));
        }
        
        // Filtrar y ordenar productos
        final filteredProducts = _getFilteredProducts(productos);
        final sortedProducts = _getSortedProducts(filteredProducts);
        
        if (sortedProducts.isEmpty) {
          return Center(child: Text('No se encontraron productos que coincidan con la búsqueda'));
        }
            
        return ListView(
          children: sortedProducts.map((producto) {
          // Obtener precio de la lista 0 (normal)
          final precioNormal = producto.listasPrecios?.isNotEmpty == true
              ? producto.listasPrecios!.firstWhere(
                  (lp) => lp.listaId == 0,
                  orElse: () => ListasPrecio(precioLista: '0.0'),
                ).precioLista ?? '0.0'
              : '0.0';
          
          // Obtener precio mayorista (para este ejemplo usamos lista 1)
          final precioMayorista = producto.listasPrecios?.where((lp) => lp.listaId != 0).isNotEmpty == true
              ? producto.listasPrecios!.firstWhere(
                  (lp) => lp.listaId != 0,
                  orElse: () => ListasPrecio(precioLista: '0.0'),
                ).precioLista ?? '0.0'
              : '0.0';
          
          // Obtener stock
          final stock = producto.stocks?.isNotEmpty == true
              ? producto.stocks!.first.stock ?? '0'
              : '0';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Checkbox(value: false, onChanged: (bool? value) {}),
                _buildProductRowCell(
                  const Icon(Icons.add, size: 20),
                  flex: 2,
                  text: producto.nombre ?? 'Sin nombre',
                ),
                _buildProductRowCell(Text(producto.barcode ?? 'Sin código'), flex: 1),
                _buildProductRowCell(Text('\$$precioNormal'), flex: 1),
                _buildProductRowCell(Text('\$$precioMayorista'), flex: 1),
                _buildProductRowCell(Text(stock), flex: 1),
              ],
            ),
          );
        }).toList(),
        );
      },
    );
  }
  
  // Filas para la pestaña de precios
  Widget _buildPreciosRows() {
    return BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (state.errorMessage != null) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }
        
        final productos = state.filteredProductoResponse?.data ?? 
                         state.productoResponse?.data ?? [];
        
        if (productos.isEmpty) {
          return Center(child: Text('No se encontraron productos'));
        }
        
        // Filtrar y ordenar productos
        final filteredProducts = _getFilteredProducts(productos);
        final sortedProducts = _getSortedProducts(filteredProducts);
        
        if (sortedProducts.isEmpty) {
          return Center(child: Text('No se encontraron productos que coincidan con la búsqueda'));
        }
        
        return ListView(
          children: sortedProducts.map((producto) {
          if (_selectedListaId == -1) {
            // Mostrar múltiples listas de precios
            final preciosPorLista = _listasPrecios.take(3).map((lista) {
              final precio = producto.listasPrecios?.firstWhere(
                (lp) => lp.listaId == lista.id,
                orElse: () => ListasPrecio(precioLista: '0.0'),
              ).precioLista ?? '0.0';
              return _buildProductRowCell(Text('\$$precio'), flex: 1);
            }).toList();
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(value: false, onChanged: (bool? value) {}),
                  _buildProductRowCell(
                    const Icon(Icons.add, size: 20),
                    flex: 2,
                    text: producto.nombre ?? 'Sin nombre',
                  ),
                  _buildProductRowCell(Text(producto.barcode ?? 'Sin código'), flex: 1),
                  ...preciosPorLista
                ],
              ),
            );
          } else {
            // Mostrar una lista de precios específica
            final precio = producto.listasPrecios?.firstWhere(
              (lp) => lp.listaId == _selectedListaId,
              orElse: () => ListasPrecio(precioLista: '0.0'),
            ).precioLista ?? '0.0';
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(value: false, onChanged: (bool? value) {}),
                  _buildProductRowCell(
                    const Icon(Icons.add, size: 20),
                    flex: 2,
                    text: producto.nombre ?? 'Sin nombre',
                  ),
                  _buildProductRowCell(Text(producto.barcode ?? 'Sin código'), flex: 1),
                  _buildProductRowCell(Text('\$$precio'), flex: 2),
                ],
              ),
            );
          }
        }).toList());
      },
    );
  }
  
  // Filas para la pestaña de stock
  Widget _buildStockRows() {
    return BlocBuilder<ProductosMaestroCubit, ProductosMaestroState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (state.errorMessage != null) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }
        
        final productos = state.filteredProductoResponse?.data ?? 
                         state.productoResponse?.data ?? [];
        
        if (productos.isEmpty) {
          return Center(child: Text('No se encontraron productos'));
        }
        
        // Filtrar y ordenar productos
        final filteredProducts = _getFilteredProducts(productos);
        final sortedProducts = _getSortedProducts(filteredProducts);
        
        if (sortedProducts.isEmpty) {
          return Center(child: Text('No se encontraron productos que coincidan con la búsqueda'));
        }
        
        return ListView(
          children: sortedProducts.map((producto) {
          // Obtener stock para la sucursal seleccionada
          final stock = producto.stocks?.firstWhere(
            (s) => s.sucursalId == _selectedSucursalId,
            orElse: () => Stock(stock: '0'),
          ).stock ?? '0';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Checkbox(value: false, onChanged: (bool? value) {}),
                _buildProductRowCell(
                  const Icon(Icons.add, size: 20),
                  flex: 2,
                  text: producto.nombre ?? 'Sin nombre',
                ),
                _buildProductRowCell(Text(producto.barcode ?? 'Sin código'), flex: 1),
                _buildProductRowCell(Text(stock), flex: 2),
              ],
            ),
          );
        }).toList(),
        );
      },
    );
  }

  Widget _buildProductRowCell(Widget content, {int flex = 1, String? text}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: content,
            ),
          if (text != null)
            Text(text),
          if (text == null) content,
        ],
      ),
    );
  }
}