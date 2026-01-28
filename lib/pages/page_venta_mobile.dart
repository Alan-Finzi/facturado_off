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
        title: Row(
          children: [
            // Logo de Flaminco
            Expanded(
              child: Center(
                child: Text(
                  'flaminco',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.orange),
          onPressed: () {
            // Menú lateral (no implementado en este ejemplo)
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.orange),
            onPressed: () {
              // Menú de opciones (no implementado en este ejemplo)
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFF5F7FA), // Fondo gris muy claro como en las imágenes
      body: Column(
        children: [
          // Título de la página
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'Punto de Venta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Panel de factura y cliente
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown de cliente (según imagen de referencia)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        clienteCubit.state.clienteSeleccionado?.nombre ?? "Consumidor Final",
                        style: TextStyle(
                          fontSize: 16,
                          color: clienteCubit.state.clienteSeleccionado != null ? Colors.black : Colors.grey[600],
                          fontWeight: clienteCubit.state.clienteSeleccionado != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? value) {
                        _mostrarDialogoCliente();
                      },
                      items: null,
                    ),
                  ),
                ),

                // Dropdown de tipo de factura (según imagen de referencia)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: productosCubit.state.tipoFactura ?? 'Factura B',
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? value) {
                        if (value != null) {
                          productosCubit.updateTipoFactura(value);
                        }
                      },
                      items: ['Factura A', 'Factura B', 'Factura C']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),


                // Tipo de entrega (según imagen de referencia)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _deliveryType,
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _deliveryType = value;
                          });
                        }
                      },
                      items: ['Entregado', 'Envío', 'Retiro']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                // Campo de búsqueda de productos (según imagen de referencia)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                          color: Colors.white,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: InputBorder.none,
                          ),
                          onTap: () => _showCatalogoProductos(),
                          readOnly: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _showCatalogoProductos(),
                      ),
                    ),
                  ],
                ),

                // Botón Ver catálogo (según imagen de referencia)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _showCatalogoProductos(),
                    child: Text(
                      'Ver catálogo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Lista de precios (según imagen de referencia)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Text(
                        'Lista de Precios: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Precio Base',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos / carrito
          Expanded(
            child: hasProducts ? _buildCartContent(productosCubit) : _buildEmptyCartState(),
          ),
        ],
      ),
      // Eliminamos el botón flotante que es redundante
      bottomNavigationBar: hasProducts ? _buildBottomBar() : null,
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
            onPressed: () => _showCatalogoProductos(),
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Ver catálogo'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.green, // Color verde según imágenes de referencia
            ),
          ),
        ],
      ),
    );
  }

  // Cart content based on reference images
  Widget _buildCartContent(ProductosCubit productosCubit) {
    final productosSeleccionados = productosCubit.state.productosSeleccionados;

    return Column(
      children: [
        // Lista de productos seleccionados
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: productosSeleccionados.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final producto = productosSeleccionados[index];
              final nombre = producto.producto?.name ?? producto.datum?.nombre ?? 'Producto sin nombre';
              final precioUnitario = producto.precioLista ?? 0.0;
              final precioFinal = producto.precioFinal ?? 0.0;
              final cantidad = producto.cantidad ?? 1.0;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Imagen de producto o placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.inventory_2, color: Colors.grey.shade600),
                    ),
                    SizedBox(width: 12),

                    // Detalles del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              // Control de cantidad con botones + y -
                              Row(
                                children: [
                                  // Botón para decrementar
                                  InkWell(
                                    onTap: () {
                                      if (cantidad > 1) {
                                        // Usar decrementarCantidad con el índice correcto
                                        productosCubit.decrementarCantidad(index);
                                      } else {
                                        // Eliminar el producto si la cantidad es 1
                                        productosCubit.eliminarProducto(index);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.remove, size: 16),
                                    ),
                                  ),

                                  // Mostrar cantidad
                                  Container(
                                    width: 40,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Center(
                                      child: Text(
                                        '${cantidad.toInt()}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),

                                  // Botón para incrementar
                                  InkWell(
                                    onTap: () {
                                      // Usar incrementarCantidad con el índice correcto
                                      productosCubit.incrementarCantidad(index);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.add, size: 16),
                                    ),
                                  ),
                                ],
                              ),

                              Spacer(),

                              // Precio unitario y final
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$ ${precioUnitario.toStringAsFixed(2)} x ${cantidad.toInt()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    '\$ ${precioFinal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botón eliminar
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        productosCubit.eliminarProducto(index);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Sección de notas y observaciones
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nota interna',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ),
              SizedBox(height: 12),

              Text(
                'Observaciones',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
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
    final productosCubit = context.watch<ProductosCubit>();
    final paymentCubit = context.watch<PaymentMethodsCubit>();
    final productosSeleccionados = productosCubit.state.productosSeleccionados;

    // Don't show if cart is empty
    if (productosSeleccionados.isEmpty) return const SizedBox.shrink();

    // Calculate total
    double subtotal = 0.0;
    double iva = 0.0;
    double total = 0.0;
    double descuento = productosCubit.state.descuentoGeneral;

    // Calcular valores
    for (var producto in productosSeleccionados) {
      subtotal += (producto.precioLista ?? 0.0) * (producto.cantidad ?? 1.0);
      // IVA está incluido en el precio según las imágenes
      iva += producto.porcentajeIva ?? 0.0;
      total += producto.precioFinal ?? 0.0;
    }

    // Aplicar descuento si hay
    double montoDescuento = 0.0;
    if (descuento > 0) {
      montoDescuento = subtotal * (descuento / 100);
      total = total - montoDescuento;
    }

    // Obtener recargo según método de pago (si hay seleccionado)
    double recargo = 0.0;
    double montoRecargo = 0.0;

    // Verificar si el estado es PaymentMethodsLoaded y tiene un método seleccionado
    if (paymentCubit.state is PaymentMethodsLoaded) {
      final paymentState = paymentCubit.state as PaymentMethodsLoaded;

      // Verificar si hay un método de pago seleccionado
      if (paymentState.selectedMethodId != null && paymentState.selectedProviderId != null) {
        // Buscar el método seleccionado para obtener su recargo
        for (final provider in paymentState.providers) {
          if (provider.id == paymentState.selectedProviderId && provider.metodosPago != null) {
            for (final method in provider.metodosPago!) {
              if (method.id == paymentState.selectedMethodId) {
                recargo = method.recargo;
                montoRecargo = total * (recargo / 100);
                total = total + montoRecargo;
                break;
              }
            }
          }
        }
      }
    }

    // Variable para controlar si hay pagos configurados
    bool hayPagosConfigurados = false;
    if (paymentCubit.state is PaymentMethodsLoaded) {
      final paymentState = paymentCubit.state as PaymentMethodsLoaded;
      hayPagosConfigurados = paymentState.selectedMethodId != null;
    }

    // Crear formato según las imágenes de referencia (venta 3.jpeg)
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección Tipo de Pago según imagen venta 3.jpeg
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Dropdown de tipo de pago
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: 'Cuenta corriente / Pago Dividido',
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? newValue) {
                        // Aquí se manejaría el cambio de tipo de pago
                      },
                      items: <String>['Cuenta corriente / Pago Dividido', 'Efectivo', 'Tarjeta', 'Transferencia']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                // Botón Configurar Pagos
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Aquí se abriría el diálogo para configurar pagos
                    _showConfigurePagosDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Configurar Pagos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Mostrar métodos de pago configurados
                if (hayPagosConfigurados && paymentCubit.state is PaymentMethodsLoaded) {
                  final paymentState = paymentCubit.state as PaymentMethodsLoaded;

                  // Buscar el método y proveedor seleccionados
                  String providerName = "Método de pago";
                  String methodName = "No seleccionado";

                  if (paymentState.selectedProviderId != null && paymentState.selectedMethodId != null) {
                    for (final provider in paymentState.providers) {
                      if (provider.id == paymentState.selectedProviderId) {
                        providerName = provider.nombre ?? "Proveedor";

                        if (provider.metodosPago != null) {
                          for (final method in provider.metodosPago!) {
                            if (method.id == paymentState.selectedMethodId) {
                              methodName = method.nombre;
                              break;
                            }
                          }
                        }
                        break;
                      }
                    }
                  }

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // Método configurado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$providerName - $methodName'),
                            Text('\$ ${total.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (montoRecargo > 0) ...[
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Incluye recargo ${recargo.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 12, color: Colors.red)),
                              Text('\$ ${montoRecargo.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        ],
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$ ${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },

                // Sección de descuento según imagen venta 3.jpeg
                SizedBox(height: 12),
                Text(
                  'Descuento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Tipo de descuento
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: '%',
                            icon: Icon(Icons.keyboard_arrow_down),
                            isDense: true,
                            onChanged: (String? newValue) {
                              // Cambiar tipo de descuento
                            },
                            items: <String>['%', '\$']
                                .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Valor del descuento
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: descuento.toStringAsFixed(2)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Actualizar descuento
                          double? descuento = double.tryParse(value);
                          if (descuento != null) {
                            productosCubit.updateDescuentoGeneral(descuento);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Mostrar subtotal, descuento, recargo, IVA y total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: TextStyle(fontSize: 16)),
                Text('\$ ${subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Descuento:', style: TextStyle(fontSize: 16)),
                Text('\$ ${montoDescuento.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recargo:', style: TextStyle(fontSize: 16)),
                Text('\$ ${montoRecargo.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('IVA:', style: TextStyle(fontSize: 16)),
                Text('\$ ${iva.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
              ],
            ),
            Text('(incluido en el precio)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\$ ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),

            // Texto de entrega
            SizedBox(height: 8),
            Text(
              _deliveryType == 'Retiro' ? 'Retiro en el local' : _deliveryType,
              style: TextStyle(
                fontSize: 16,
                color: Colors.amber[800],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 12),

            // Botones según imágenes de referencia
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _irAFormaDeCobro(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Deuda (según imagen de referencia)
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deuda:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar el diálogo de configuración de pagos
  void _showConfigurePagosDialog(BuildContext context) {
    final paymentCubit = context.read<PaymentMethodsCubit>();
    // Cargar los proveedores de pagos si no están cargados
    if (!(paymentCubit.state is PaymentMethodsLoaded)) {
      paymentCubit.loadPaymentProviders();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
          builder: (context, state) {
            // Mostrar cargando si el estado es PaymentMethodsLoading
            if (state is PaymentMethodsLoading) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando métodos de pago...'),
                    ],
                  ),
                ),
              );
            }

            // Mostrar error si el estado es PaymentMethodsError
            if (state is PaymentMethodsError) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('Error al cargar métodos de pago'),
                      SizedBox(height: 8),
                      Text(state.message, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          paymentCubit.loadPaymentProviders();
                        },
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Mostrar mensaje si no hay métodos de pago
            if (state is PaymentMethodsEmpty) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 48),
                      SizedBox(height: 16),
                      Text('No hay métodos de pago disponibles'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Mostrar lista de métodos si el estado es PaymentMethodsLoaded
            if (state is PaymentMethodsLoaded) {
              final providers = state.providers;

              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configurar pagos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Divider(),

                    // Selector de proveedor
                    Text(
                      'Proveedor de pago',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: state.selectedProviderId,
                          hint: Text('Seleccione proveedor'),
                          onChanged: (int? value) {
                            if (value != null) {
                              paymentCubit.selectPaymentProvider(value);
                            }
                          },
                          items: providers.map((provider) {
                            return DropdownMenuItem<int>(
                              value: provider.id,
                              child: Text(provider.nombre ?? 'Proveedor sin nombre'),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Selector de método de pago
                    Text(
                      'Método de pago',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    if (state.selectedProviderId != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: state.selectedMethodId,
                            hint: Text('Seleccione método'),
                            onChanged: (int? value) {
                              if (value != null) {
                                paymentCubit.selectPaymentMethod(value);
                              }
                            },
                            items: _getMethodsForProvider(providers, state.selectedProviderId!).map((method) {
                              return DropdownMenuItem<int>(
                                value: method.id,
                                child: Row(
                                  children: [
                                    Expanded(child: Text(method.nombre)),
                                    if (method.recargo > 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '+${method.recargo}%',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    Divider(),

                    // Lista de métodos de pago
                    Expanded(
                      child: ListView.builder(
                        itemCount: providers.length,
                        itemBuilder: (context, providerIndex) {
                          final provider = providers[providerIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  provider.nombre ?? 'Proveedor sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Mostrar métodos de este proveedor
                              if (provider.metodosPago != null)
                                ...provider.metodosPago!.map((method) {
                                  final isSelected = state.selectedMethodId == method.id &&
                                      state.selectedProviderId == provider.id;
                                  return _buildPaymentMethodItem(
                                    method.nombre,
                                    provider.nombre ?? '',
                                    method.recargo,
                                    isSelected,
                                    onTap: () {
                                      paymentCubit.selectPaymentProvider(provider.id);
                                      paymentCubit.selectPaymentMethod(method.id);
                                    },
                                  );
                                }).toList(),
                              SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),

                    // Botón para confirmar
                    ElevatedButton(
                      onPressed: () {
                        // Actualizar el monto subtotal antes de cerrar
                        final productosCubit = context.read<ProductosCubit>();
                        double subtotal = 0.0;
                        for (var producto in productosCubit.state.productosSeleccionados) {
                          subtotal += (producto.precioLista ?? 0.0) * (producto.cantidad ?? 1.0);
                        }
                        paymentCubit.updateSubtotalAmount(subtotal);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Por defecto mostrar un cargando
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  // Método auxiliar para obtener los métodos de un proveedor
  List<PaymentMethod> _getMethodsForProvider(List<PaymentProvider> providers, int providerId) {
    try {
      final provider = providers.firstWhere((p) => p.id == providerId);
      return provider.metodosPago ?? [];
    } catch (e) {
      return [];
    }
  }

  // Widget para un método de pago
  Widget _buildPaymentMethodItem(String title, String subtitle, double recargo, bool selected, {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recargo > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${recargo.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? Colors.green : Colors.grey,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // Eliminamos la función _buildFloatingActionButton() ya que no se usa

  // Client selection dialog styled according to reference images
  void _mostrarDialogoCliente() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Text(
                      'Catálogo de clientes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(),

                // Search field
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),

                // Lista de clientes
                Container(
                  height: 300,
                  child: BuscarClienteWidget(
                    clearProductsOnSelection: true,
                    showSelectedClient: false,
                  ),
                ),

                // Action buttons in Flaminco style
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Seleccionar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Product catalog modal styled according to reference images
  void _showCatalogoProductos() {
    // Open a dialog similar to the design in the reference images
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Catálogo de productos',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Search field
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Category selector
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: 'Todas las categorías',
                            onChanged: (String? newValue) {},
                            items: <String>['Todas las categorías'].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Brand selector
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: 'Todas las marcas',
                            onChanged: (String? newValue) {},
                            items: <String>['Todas las marcas'].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Products list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5, // Elementos de muestra
                      itemBuilder: (context, index) {
                        // Nombres de muestra basados en las imágenes de referencia
                        final productos = [
                          '1 vino TORO 1 coca 2,25',
                          'ACEITE AEROSOL NATURA X 120 CC',
                          'Aceite de Oliva x 500',
                          'Aceite Fritolin Manteca',
                          'ACEITUNAS NEGRAS'
                        ];
                        final precios = [3448.09, 3080.88, 2515.59, 2732.81, 2343.09];

                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del producto
                              Text(
                                productos[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),

                              // Categoría
                              Text(
                                index % 2 == 0 ? 'Sin categoría' : 'Alimentos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              // Precio y botón
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$ ${precios[index].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Botón para agregar
                                  IconButton(
                                    onPressed: () {
                                      // Simular agregar producto al carrito
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Producto agregado al carrito'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
