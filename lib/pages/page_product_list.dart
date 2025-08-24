import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import '../models/productos_maestro.dart';
import '../models/user.dart';
import '../helper/database_helper.dart';
import 'dart:math';

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
    // Si tenemos seleccionada una lista y sucursal específicas, aplicamos ambos filtros
    if (_selectedListaId != null && _selectedSucursalId != null) {
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(_selectedListaId!, _selectedSucursalId!);
      print('Productos filtrados por lista $_selectedListaId y sucursal $_selectedSucursalId cargados');
    } 
    // Si solo tenemos lista seleccionada
    else if (_selectedListaId != null) {
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(_selectedListaId!, -1);
      print('Productos filtrados por lista $_selectedListaId cargados');
    }
    // Si solo tenemos sucursal seleccionada
    else if (_selectedSucursalId != null) {
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, _selectedSucursalId!);
      print('Productos filtrados por sucursal $_selectedSucursalId cargados');
    }
    // Si no tenemos nada seleccionado, cargamos todos
    else {
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, -1);
      print('Todos los productos cargados');
    }
  }
  
  // Carga productos filtrados por stock y sucursal para la pestaña STOCK
  Future<void> _cargarProductosStock() async {
    if (_selectedSucursalId == null) {
      // Si no hay sucursal seleccionada, cargamos todos los productos
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, -1);
      print('Todos los productos cargados para mostrar stock');
    } else {
      // Cargamos productos filtrados por la sucursal_id seleccionada
      context.read<ProductosMaestroCubit>().cargarProductosConPrecioYStock(-1, _selectedSucursalId!); 
      print('Productos filtrados por sucursal_id $_selectedSucursalId cargados');
    }
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

  // Pestaña de Catálogo - Muestra precio base y stock por sucursal
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
      child: Column(
        children: [
          // Primera fila con botón de ordenar y buscador
          Row(
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
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Segunda fila con dos filtros: lista de precios y sucursales
          Row(
            children: [
              // Filtro de Lista de Precios
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
              // Filtro de Sucursales
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
                        onChanged: null,
                      )
                    : DropdownButton<int?>(
                        isExpanded: true,
                        underline: SizedBox(),
                        value: _selectedSucursalId,
                        hint: Text("Seleccionar sucursal"),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas las sucursales'),
                          ),
                          ..._sucursales
                            .map((sucursal) => DropdownMenuItem<int?>(
                              value: sucursal['id'],
                              child: Text(sucursal['nombre'] ?? 'Sucursal ${sucursal['id']}'),
                            ))
                            .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSucursalId = value;
                          });
                        },
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Filtro especial para la pestaña de stock
  Widget _buildStockFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Primera fila con botón de ordenar y buscador
          Row(
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
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Segunda fila con filtro de sucursales
          Row(
            children: [
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
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas las sucursales'),
                          ),
                          ..._sucursales
                            .map((sucursal) => DropdownMenuItem<int?>(
                              value: sucursal['id'],
                              child: Text(sucursal['nombre'] ?? 'Sucursal ${sucursal['id']}'),
                            ))
                            .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSucursalId = value;
                            _cargarProductosStock(); // Siempre recargamos
                            print('Sucursal seleccionada: ${_selectedSucursalId}');
                          });
                        },
                      ),
                ),
              ),
              SizedBox(width: 16),
              // Área para mostrar información de la sucursal seleccionada
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSucursalId != null
                              ? 'Mostrando stock de: ${_getNombreSucursal(_selectedSucursalId!)} (ID: ${_selectedSucursalId})'
                              : 'Mostrando todas las sucursales disponibles',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          _buildTableHeaderCell('Precio base', flex: 1),
          _buildTableHeaderCell('Stock disponible', flex: 1),
        ],
      ),
    );
  }
  
  Widget _buildPreciosTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            Checkbox(value: false, onChanged: (bool? value) {}),
            _buildTableHeaderCell('Nombre del producto', flex: 2),
            _buildTableHeaderCell('SKU', flex: 1),
            // Mostrar todas las listas de precios disponibles o la lista específica
            if (_selectedListaId == null) 
              ...(_listasPrecios.map((lista) => 
                _buildTableHeaderCell(
                  '${lista.nombre ?? "Lista ${lista.id}"} (${lista.id})', 
                  flex: 1
                )
              ).toList())
            else
              _buildTableHeaderCell(
                'Precio Lista ${_listasPrecios.firstWhere(
                  (l) => l.id == _selectedListaId, 
                  orElse: () => Lista(id: _selectedListaId, nombre: "")
                ).nombre ?? _selectedListaId}', 
                flex: 1
              ),
            // Si hay sucursal seleccionada, mostrar cabecera de stock
            if (_selectedListaId != null && _selectedSucursalId != null)
              _buildTableHeaderCell(
                'Stock en ${_getNombreSucursal(_selectedSucursalId!)}',
                flex: 1
              )
          ],
        ),
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
          _buildTableHeaderCell(
            'Stock en ${_selectedSucursalId != null ? _getNombreSucursal(_selectedSucursalId!) : "Todas las sucursales"}', 
            flex: 2
          ),
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

  // Filas para la pestaña de catálogo - muestra precio base y stock de la sucursal actual
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
        
        // Obtener la sucursal actual del usuario
        final user = User.currencyUser;
        final sucursalActual = int.tryParse(user?.sucursal?.toString() ?? '0') ?? 0;
        
        // Usar ListView.builder para mejor rendimiento
        return ListView.builder(
          itemCount: sortedProducts.length,
          itemBuilder: (context, index) {
            final producto = sortedProducts[index];
            
            // Obtener precio base (precio por defecto, no por lista)
            final precioBase = producto.listasPrecios?.where((lp) => lp.listaId == 0).isNotEmpty == true
                ? producto.listasPrecios!.firstWhere(
                    (lp) => lp.listaId == 0, // Lista 0 es la base/default
                    orElse: () => ListasPrecio(precioLista: '0.0'),
                  ).precioLista ?? '0.0'
                : '0.0';
            
            // Obtener stock de la sucursal actual (buscando por sucursal_id)
            final stockSucursalActual = producto.stocks?.where((s) => s.sucursalId == sucursalActual).isNotEmpty == true
                ? producto.stocks!.firstWhere(
                    (s) => s.sucursalId == sucursalActual,
                    orElse: () => Stock(stock: '0'),
                  ).stock ?? '0'
                : '0';
            
            // Destacar visualmente el nivel de stock
            Color stockColor = Colors.blue;
            if (int.tryParse(stockSucursalActual) == 0) {
              stockColor = Colors.red;
            } else if (int.tryParse(stockSucursalActual) != null && int.parse(stockSucursalActual) < 5) {
              stockColor = Colors.orange;
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              height: 48, 
              color: index % 2 == 0 ? Colors.grey.withOpacity(0.1) : Colors.white,
              child: Row(
                children: [
                  SizedBox(width: 24, child: Checkbox(value: false, onChanged: (bool? value) {})),
                  _buildProductRowCell(
                    const Icon(Icons.inventory_2, size: 20), // Icono de inventario para catálogo
                    flex: 2,
                    text: producto.nombre ?? 'Sin nombre',
                  ),
                  _buildProductRowCell(Text(producto.barcode ?? 'Sin código'), flex: 1),
                  _buildProductRowCell(
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(precioBase),
                      ],
                    ), 
                    flex: 1
                  ),
                  _buildProductRowCell(
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: stockColor),
                        SizedBox(width: 4),
                        Text(stockSucursalActual, style: TextStyle(color: stockColor)),
                      ],
                    ), 
                    flex: 1
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Filas para la pestaña de precios - muestra precios por cada lista
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
        
        // Crear las columnas dependiendo de la configuración
        List<DataColumn> columns = [];
        
        // Agregar las columnas estándar
        columns.add(DataColumn(label: SizedBox(width: 30, child: Checkbox(value: false, onChanged: null))));
        columns.add(DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))));
        columns.add(DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))));
        
        // Mostrar columnas para todas las listas de precios o solo la seleccionada
        if (_selectedListaId == null) {
          // Mostrar columnas para todas las listas de precios
          for (var lista in _listasPrecios) {
            columns.add(DataColumn(
              label: Text(
                '${lista.nombre ?? "Lista ${lista.id}"}', 
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ));
          }
        } else {
          // Mostrar columna para lista específica
          final nombreLista = _listasPrecios.firstWhere(
            (l) => l.id == _selectedListaId,
            orElse: () => Lista(id: _selectedListaId, nombre: "Lista $_selectedListaId"),
          ).nombre ?? "Lista $_selectedListaId";
          
          columns.add(DataColumn(
            label: Text(
              nombreLista,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ));
        }
        
        // Crear las filas
        List<DataRow> rows = [];
        for (int i = 0; i < sortedProducts.length; i++) {
          final producto = sortedProducts[i];
          List<DataCell> cells = [];
          
          // Celda de checkbox
          cells.add(DataCell(Checkbox(value: false, onChanged: (bool? value) {})));
          
          // Celda de nombre
          cells.add(DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_money, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    producto.nombre ?? 'Sin nombre',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ));
          
          // Celda de código
          cells.add(DataCell(Text(producto.barcode ?? 'Sin código')));
          
          // Celdas dinámicas para precios
          if (_selectedListaId == null) {
            // Mostrar celdas para todas las listas de precios
            for (var lista in _listasPrecios) {
              final precio = producto.listasPrecios?.firstWhere(
                (lp) => lp.listaId == lista.id,
                orElse: () => ListasPrecio(precioLista: '0.0'),
              ).precioLista ?? '0.0';
              
              cells.add(DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: lista.id == 0 ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  ),
                  child: Text(
                    '\$$precio', 
                    style: TextStyle(
                      fontWeight: lista.id == 0 ? FontWeight.bold : FontWeight.normal,
                      color: lista.id == 0 ? Colors.blue.shade800 : Colors.green.shade800,
                    )
                  ),
                )
              ));
            }
          } else {
            // Mostrar celda para lista específica
            final precio = producto.listasPrecios?.firstWhere(
              (lp) => lp.listaId == _selectedListaId,
              orElse: () => ListasPrecio(precioLista: '0.0'),
            ).precioLista ?? '0.0';
            
            cells.add(DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _selectedListaId == 0 ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                ),
                child: Text(
                  '\$$precio', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedListaId == 0 ? Colors.blue.shade800 : Colors.green.shade800,
                  )
                ),
              )
            ));
          }
          
          // Agregar la fila con color alternado
          rows.add(DataRow(
            color: MaterialStatePropertyAll(
              i % 2 == 0 ? Colors.grey.withOpacity(0.1) : Colors.white
            ),
            cells: cells,
          ));
        }
        
        // DataTable con scroll horizontal y vertical
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              columns: columns,
              rows: rows,
              border: TableBorder(
                horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                verticalInside: BorderSide(width: 1, color: Colors.grey.shade200),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Filas para la pestaña de stock - muestra nombre y stock por sucursal
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
        
        // Crear lista de sucursales_id disponibles en todos los productos
        Set<int?> sucursalesIdDisponibles = Set();
        for (var producto in sortedProducts) {
          if (producto.stocks != null) {
            for (var stock in producto.stocks!) {
              if (stock.sucursalId != null) {
                sucursalesIdDisponibles.add(stock.sucursalId);
              }
            }
          }
        }
        
        print('Sucursales ID disponibles: $sucursalesIdDisponibles');
        
        // Crear columnas para DataTable
        List<DataColumn> columns = [
          DataColumn(label: SizedBox(width: 30, child: Checkbox(value: false, onChanged: null))),
          DataColumn(label: Text('Nombre del producto', style: TextStyle(fontWeight: FontWeight.bold))),
        ];
        
        // Agregar columna para la sucursal seleccionada o todas las sucursales
        if (_selectedSucursalId != null) {
          // Sucursal específica
          final nombreSucursal = _getNombreSucursal(_selectedSucursalId!);
          columns.add(DataColumn(
            label: Text(
              'Stock en $nombreSucursal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ));
        } else {
          // Mostrar columnas para cada sucursal_id encontrado en los datos
          // Crear un mapa de sucursalId -> nombre para usar después
          Map<int, String> nombresSucursales = {};
          for (var sucursal in _sucursales) {
            if (sucursal['id'] != null) {
              nombresSucursales[sucursal['id']] = sucursal['nombre'] ?? 'Sucursal ${sucursal['id']}';
            }
          }
          
          // Mostrar solo las columnas de sucursales que tengan stocks
          List<int?> sucursalesIdOrdenadas = sucursalesIdDisponibles.toList();
          sucursalesIdOrdenadas.sort(); // Ordenarlas para mostrar consistentemente
          
          for (var sucursalId in sucursalesIdOrdenadas) {
            if (sucursalId != null) {
              final nombreSucursal = nombresSucursales[sucursalId] ?? 'Sucursal $sucursalId';
              columns.add(DataColumn(
                label: Text(
                  nombreSucursal,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ));
            }
          }
        }
        
        // Crear filas
        List<DataRow> rows = [];
        for (int i = 0; i < sortedProducts.length; i++) {
          final producto = sortedProducts[i];
          List<DataCell> cells = [];
          
          // Celda de checkbox
          cells.add(DataCell(Checkbox(value: false, onChanged: (bool? value) {})));
          
          // Celda de nombre del producto
          cells.add(DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    producto.nombre ?? 'Sin nombre',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ));
          
          // Crear un mapa de sucursalId -> stock para acceder rápidamente
          Map<int?, String> stocksPorSucursalId = {};
          if (producto.stocks != null) {
            for (var stock in producto.stocks!) {
              if (stock.sucursalId != null && !stocksPorSucursalId.containsKey(stock.sucursalId)) {
                stocksPorSucursalId[stock.sucursalId] = stock.stock ?? '0';
              }
            }
          }
          
          if (_selectedSucursalId != null) {
            // Mostrar stock solo para la sucursal seleccionada
            final stock = stocksPorSucursalId[_selectedSucursalId] ?? '0';
            
            // Destacar visualmente el nivel de stock
            Color stockColor = Colors.green;
            if (int.tryParse(stock) == 0 || stock == '0' || stock == '0.000') {
              stockColor = Colors.red;
            } else if (int.tryParse(stock) != null && int.parse(stock) < 5) {
              stockColor = Colors.orange;
            }
            
            cells.add(DataCell(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: stockColor.withOpacity(0.2),
                ),
                child: Text(
                  stock,
                  style: TextStyle(color: stockColor, fontWeight: FontWeight.bold),
                ),
              ),
            ));
          } else {
            // Mostrar stock para todas las sucursales disponibles
            List<int?> sucursalesIdOrdenadas = sucursalesIdDisponibles.toList();
            sucursalesIdOrdenadas.sort();
            
            for (var sucursalId in sucursalesIdOrdenadas) {
              if (sucursalId != null) {
                final stock = stocksPorSucursalId[sucursalId] ?? '0';
                
                // Destacar visualmente el nivel de stock
                Color stockColor = Colors.green;
                if (int.tryParse(stock) == 0 || stock == '0' || stock == '0.000') {
                  stockColor = Colors.red;
                } else if (int.tryParse(stock) != null && int.parse(stock) < 5) {
                  stockColor = Colors.orange;
                }
                
                cells.add(DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: stockColor.withOpacity(0.2),
                    ),
                    child: Text(
                      stock,
                      style: TextStyle(color: stockColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ));
              }
            }
          }
          
          // Agregar la fila con color alternado
          rows.add(DataRow(
            color: MaterialStatePropertyAll(
              i % 2 == 0 ? Colors.grey.withOpacity(0.1) : Colors.white
            ),
            cells: cells,
          ));
        }
        
        // DataTable con scroll horizontal y vertical
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              columns: columns,
              rows: rows,
              border: TableBorder(
                horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                verticalInside: BorderSide(width: 1, color: Colors.grey.shade200),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductRowCell(Widget content, {int flex = 1, String? text}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 48, // Altura fija para evitar problemas de tamaño
        constraints: BoxConstraints(
          minHeight: 48.0, // Altura mínima garantizada
          minWidth: 50.0,  // Ancho mínimo garantizado
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Asegurar tamaño mínimo
          children: [
            if (text != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: content,
              ),
            if (text != null)
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis, // Evitar desbordamiento de texto
                ),
              ),
            if (text == null) 
              Expanded(child: content), // Envolver el contenido en un Expanded
          ],
        ),
      ),
    );
  }
}