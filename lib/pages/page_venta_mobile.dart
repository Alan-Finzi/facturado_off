import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/datos_facturacion_model.dart';
import '../util/platform_service.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/resumen_widget.dart';
import '../widget/split_payment_container.dart';
import '../widget/listado_precios.dart';
import 'package:facturador_offline/widget/platform_adaptive_widget.dart';
import 'page_catalogo.dart';
import 'page_forma_cobro.dart';

/// Página principal de venta optimizada para dispositivos móviles
/// Esta página implementa un diseño responsive que se adapta a pantallas pequeñas
class VentaMainPageMobile extends StatefulWidget {
  const VentaMainPageMobile({Key? key}) : super(key: key);

  @override
  State<VentaMainPageMobile> createState() => _VentaMainPageMobileState();
}

class _VentaMainPageMobileState extends State<VentaMainPageMobile> with TickerProviderStateMixin {
  // State variables
  bool _datosFacturacionCargados = false;
  List<DatosFacturacionModel> datosFacturacion = [];
  bool _isResumenExpanded = false;
  int _currentTabIndex = 0;
  bool _showSearchBar = false;
  String _deliveryType = 'Entregado';
  final PlatformService _platformService = PlatformService();

  // Loading states
  bool _isLoading = false;
  bool _isSearching = false;

  // Controllers
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load data
    _cargarDatosFacturacion();

    // Initialize product and client data
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Method to initialize product and client data
  Future<void> _initData() async {
    final clientesMostradorCubit = context.read<ClientesMostradorCubit>();
    clientesMostradorCubit.getClientesBD();

    final loginCubit = context.read<LoginCubit>();
    final listasPreciosCubit = context.read<ListaPreciosCubit>();
    listasPreciosCubit.getListasPreciosBD();
  }

  // Method to load invoicing data
  Future<void> _cargarDatosFacturacion() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final loginCubit = context.read<LoginCubit>();
      String comercioId = (loginCubit.state.user!.comercioId == "1")
          ? loginCubit.state.user!.id.toString()
          : loginCubit.state.user!.comercioId!;

      final datos = await DatabaseHelper.instance.getAllDatosFacturacionCommerce(int.parse(comercioId));

      if (mounted) {
        setState(() {
          datosFacturacion = datos;
          _datosFacturacionCargados = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos de facturación: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the cubits
    final productosCubit = context.watch<ProductosCubit>();
    final clienteCubit = context.watch<ClientesMostradorCubit>();
    final hasProducts = productosCubit.state.productosSeleccionados.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? _buildSearchField()
            : Text('Venta', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
        leading: _showSearchBar
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearchBar = false;
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: _showSearchBar
            ? []
            : [
                // Search button
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar productos',
                  onPressed: () {
                    setState(() {
                      _showSearchBar = true;
                    });
                  },
                ),
                // Client button
                IconButton(
                  icon: const Icon(Icons.person),
                  tooltip: 'Cliente: ${clienteCubit.state.clienteSeleccionado?.nombre ?? "Consumidor Final"}',
                  onPressed: () => _mostrarDialogoCliente(),
                ),
                // Payment button
                IconButton(
                  icon: const Icon(Icons.payment),
                  tooltip: 'Ir a forma de cobro',
                  onPressed: () => _irAFormaDeCobro(context),
                ),
                // Cart icon with badge showing the number of products
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      tooltip: 'Ver carrito',
                      onPressed: () {
                        _tabController.animateTo(1); // Switch to cart tab
                      },
                    ),
                    if (hasProducts)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${productosCubit.state.productosSeleccionados.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          // Client panel and delivery selector
          _buildClientePanel(),

          // Tab bar for products and summary
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(Icons.inventory),
                text: 'Productos',
              ),
              Tab(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (hasProducts)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${productosCubit.state.productosSeleccionados.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                text: 'Carrito',
              ),
            ],
          ),

          // Main content with TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(), // Products tab
                _buildCartTab(),     // Cart tab
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Search field widget for app bar
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: TextStyle(color: Colors.white),
      onChanged: (value) {
        // Implement product search
        setState(() {
          _isSearching = value.isNotEmpty;
        });
      },
    );
  }

  // Client panel with delivery type selector
  Widget _buildClientePanel() {
    final clienteCubit = context.watch<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;

    // More compact version for mobile
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Client info
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        cliente?.nombre ?? 'Consumidor Final',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delivery type dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _deliveryType,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).primaryColor,
                ),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
                items: const [
                  DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
                  DropdownMenuItem(value: 'Envío', child: Text('Envío')),
                  DropdownMenuItem(value: 'Retiro', child: Text('Retiro')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _deliveryType = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Products tab content
  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product search bar
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar Productos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BuscarProductoScanner(),
                  const SizedBox(height: 8),
                  BuscarProductoWidget(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Categories section (placeholder for now, to be implemented)
          _buildCategoriesSection(),

          const SizedBox(height: 16),

          // Featured products
          _buildFeaturedProductsSection(),

          const SizedBox(height: 24),

          // Lista de precios para productos seleccionados
          BlocBuilder<ProductosCubit, ProductosState>(
            builder: (context, state) {
              if (state.productosSeleccionados.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos seleccionados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListaPrecios(),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Cart/summary tab content
  Widget _buildCartTab() {
    final productosCubit = context.watch<ProductosCubit>();
    final productosSeleccionados = productosCubit.state.productosSeleccionados;

    if (productosSeleccionados.isEmpty) {
      return _buildEmptyCartState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen de venta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _showCancelDialog(context);
                },
                icon: Icon(Icons.delete_outline, size: 16),
                label: Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cart items
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products list
                  ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: productosSeleccionados.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final producto = productosSeleccionados[index];
                      return _buildCartItem(producto, productosCubit);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sales information (select invoice type, discount, etc)
          _datosFacturacionCargados
            ? _buildSalesInfoCard()
            : Center(child: CircularProgressIndicator()),

          const SizedBox(height: 16),

          // Total summary
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ResumenTabla(),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(0); // Go back to products tab
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Seguir agregando'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _irAFormaDeCobro(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text('Cobrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Cart item widget
  Widget _buildCartItem(dynamic producto, ProductosCubit productosCubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image or icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.producto?.name ?? producto.datum?.nombre ?? 'Producto sin nombre',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${producto.precioLista?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (producto.descuento != null && producto.descuento! > 0)
                      Text(
                        ' (-${producto.descuento}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    if ((producto.cantidad ?? 0) > 1) {
                      // Usar decrementarCantidad con el índice correcto
                      final index = productosCubit.state.productosSeleccionados.indexOf(producto);
                      if (index != -1) {
                        productosCubit.decrementarCantidad(index);
                      }
                    } else {
                      // Usar eliminarProducto con el índice correcto
                      final index = productosCubit.state.productosSeleccionados.indexOf(producto);
                      if (index != -1) {
                        productosCubit.eliminarProducto(index);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${producto.cantidad ?? 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    // Usar incrementarCantidad con el índice correcto
                    final index = productosCubit.state.productosSeleccionados.indexOf(producto);
                    if (index != -1) {
                      productosCubit.incrementarCantidad(index);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Price
          Text(
            '\$${(producto.precioFinal ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Empty cart state
  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade productos a tu carrito para continuar',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0); // Go to products tab
            },
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Agregar productos'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Categories section
  Widget _buildCategoriesSection() {
    // Mock categories for display purposes
    final categories = [
      {'name': 'Todos', 'icon': Icons.category},
      {'name': 'Destacados', 'icon': Icons.star},
      {'name': 'Ofertas', 'icon': Icons.local_offer},
      {'name': 'Nuevos', 'icon': Icons.new_releases},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Featured products section
  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Productos destacados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showCatalogoProductos(),
              child: Text('Ver catálogo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCatalogoProductos(),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Abrir catálogo completo',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Sales information card
  Widget _buildSalesInfoCard() {
    final productosCubit = context.watch<ProductosCubit>();
    final state = productosCubit.state;

    // Check if we have datos facturación
    if (datosFacturacion.isEmpty) {
      return Center(
        child: Text('No hay datos de facturación disponibles'),
      );
    }

    // Find the selected facturación data or use the first one
    DatosFacturacionModel? selected;
    if (state.datosFacturacionModel != null && state.datosFacturacionModel!.isNotEmpty) {
      selected = state.datosFacturacionModel!.first;
    } else {
      selected = datosFacturacion.first;
      // Update the state with the default value
      productosCubit.updateDatosFacturacion([selected]);
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de venta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Datos facturación dropdown
            DropdownButtonFormField<DatosFacturacionModel>(
              decoration: InputDecoration(
                labelText: 'Datos de facturación',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              value: selected,
              isExpanded: true,
              items: datosFacturacion.map((factura) {
                String condicionIvaText =
                    factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';
                return DropdownMenuItem<DatosFacturacionModel>(
                  value: factura,
                  child: Text(
                    '${factura.razonSocial?.isNotEmpty == true ? factura.razonSocial : 'Sin razón social'} - $condicionIvaText',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (DatosFacturacionModel? selectedFactura) {
                if (selectedFactura != null) {
                  DatosFacturacionModel.datosFacturacionCurrent
                    ..clear()
                    ..add(selectedFactura);
                  context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);
                }
              },
            ),

            const SizedBox(height: 16),

            // Invoice type dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tipo de factura',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              value: state.tipoFactura ?? 'Factura C',
              isExpanded: true,
              items: ['Factura A', 'Factura B', 'Factura C']
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  productosCubit.updateTipoFactura(newValue);
                }
              },
            ),

            const SizedBox(height: 16),

            // Discount field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.descuentoGeneral.round().toString(),
                    decoration: InputDecoration(
                      labelText: 'Descuento (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? descuento = int.tryParse(value);
                      if (descuento != null) {
                        if (descuento > 100) descuento = 100;
                        productosCubit.updateDescuentoGeneral(descuento.toDouble());
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation bar
  Widget _buildBottomBar() {
    // Only show bottom bar on the cart tab
    if (_currentTabIndex != 1) return const SizedBox.shrink();

    final productosCubit = context.watch<ProductosCubit>();
    final productosSeleccionados = productosCubit.state.productosSeleccionados;

    // Don't show if cart is empty
    if (productosSeleccionados.isEmpty) return const SizedBox.shrink();

    // Calculate total
    double total = 0.0;
    for (var producto in productosSeleccionados) {
      total += producto.precioFinal ?? 0.0;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Checkout button
            ElevatedButton.icon(
              onPressed: () => _irAFormaDeCobro(context),
              icon: Icon(Icons.payment),
              label: Text('Cobrar'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Floating action button
  Widget _buildFloatingActionButton() {
    if (_currentTabIndex == 0) {
      return FloatingActionButton(
        onPressed: () => _showCatalogoProductos(),
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Escanear código',
      );
    }
    return const SizedBox.shrink(); // Widget vacío en lugar de null
  }

  // Client selection dialog - enhanced for mobile
  void _mostrarDialogoCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Seleccionar Cliente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(),
              // Client search widget
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: BuscarClienteWidget(
                    clearProductsOnSelection: true,
                    showSelectedClient: false,
                  ),
                ),
              ),
              // Action buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Get the currently selected client
                            final clienteCubit = context.read<ClientesMostradorCubit>();
                            if (clienteCubit.state.clienteSeleccionado != null) {
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Seleccione un cliente'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text('Seleccionar'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Product catalog modal - full page for better mobile experience
  void _showCatalogoProductos() {
    // Navigate to full-screen catalog page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CatalogoPage(),
        fullscreenDialog: true,
      ),
    );
  }

  // Navigate to payment form with validation
  void _irAFormaDeCobro(BuildContext context) {
    final productosCubit = context.read<ProductosCubit>();
    final clienteCubit = context.read<ClientesMostradorCubit>();

    // Validate required data
    if (productosCubit.state.productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optional: validate client selection
    if (clienteCubit.state.clienteSeleccionado == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cliente no seleccionado'),
          content: Text('¿Desea continuar con Consumidor Final?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to payment form
                _navigateToPaymentForm();
              },
              child: Text('Continuar'),
            ),
          ],
        ),
      );
    } else {
      // Client is selected, navigate directly
      _navigateToPaymentForm();
    }
  }

  // Method to navigate to payment form
  void _navigateToPaymentForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormaCobroPage(
          onBackPressed: () {
            Navigator.of(context).pop();
          },
          onGetDatosEnvio: (datos) {
            // Store delivery data if needed
            setState(() {});
          },
        ),
      ),
    );
  }

  // Cancel sale confirmation dialog
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cancelar venta'),
            ],
          ),
          content: const Text('¿Está seguro que desea cancelar la venta actual? Se perderán todos los productos agregados.'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Clean up
                context.read<ProductosCubit>().limpiarProductosSeleccionados();
                context.read<ClientesMostradorCubit>().deseleccionarCliente();

                // Close dialog and show confirmation
                Navigator.of(context).pop();

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Venta cancelada'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Go back to first tab
                _tabController.animateTo(0);
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }
}
