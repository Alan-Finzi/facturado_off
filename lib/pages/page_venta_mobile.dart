import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/clientes_mostrador.dart';
import '../util/platform_service.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/resumen_widget.dart';
import '../widget/split_payment_container.dart';
import 'package:facturador_offline/widget/platform_adaptive_widget.dart';
import 'page_forma_cobro.dart';

/// Página principal de venta optimizada para dispositivos móviles
/// Esta página implementa un diseño responsive que se adapta a pantallas pequeñas
class VentaMainPageMobile extends StatefulWidget {
  const VentaMainPageMobile({Key? key}) : super(key: key);

  @override
  State<VentaMainPageMobile> createState() => _VentaMainPageMobileState();
}

class _VentaMainPageMobileState extends State<VentaMainPageMobile> {
  bool _datosFacturacionCargados = false;
  Map<String, dynamic>? datosFacturacion;
  bool _isResumenExpanded = false;
  int _currentTabIndex = 0;
  final PlatformService _platformService = PlatformService();

  @override
  void initState() {
    super.initState();
    _cargarDatosFacturacion();
  }

  Future<void> _cargarDatosFacturacion() async {
    setState(() {
      _datosFacturacionCargados = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Agregar cliente',
            onPressed: () => _mostrarDialogoCliente(),
          ),
          IconButton(
            icon: const Icon(Icons.payment),
            tooltip: 'Ir a forma de cobro',
            onPressed: () => _irAFormaDeCobro(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de cliente y selector de entrega
          _buildClientePanel(),

          // Tabs para producto y resumen
          _buildTabBar(),

          // Contenido principal
          Expanded(
            child: _currentTabIndex == 0
                ? _buildProductosContent()
                : _buildResumenContent(),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0 ? FloatingActionButton(
        onPressed: () => _showCatalogoProductos(),
        child: const Icon(Icons.add_shopping_cart),
        tooltip: 'Agregar productos',
      ) : null,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentTabIndex == 0
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory,
                      color: _currentTabIndex == 0
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Productos',
                      style: TextStyle(
                        color: _currentTabIndex == 0
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        fontWeight: _currentTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentTabIndex == 1
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: _currentTabIndex == 1
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen',
                      style: TextStyle(
                        color: _currentTabIndex == 1
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        fontWeight: _currentTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientePanel() {
    final clienteCubit = context.watch<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  cliente?.nombre ?? 'Consumidor Final',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: 'Entregado',
            items: const [
              DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
              DropdownMenuItem(value: 'Envío', child: Text('Envío')),
              DropdownMenuItem(value: 'Retiro', child: Text('Retiro en local')),
            ],
            onChanged: (value) {
              // Manejar cambio en la modalidad de entrega
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductosContent() {
    final productosCubit = context.watch<ProductosCubit>();
    final productosSeleccionados = productosCubit.state.productosSeleccionados;

    if (productosSeleccionados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos seleccionados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCatalogoProductos(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar productos'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: productosSeleccionados.length,
      itemBuilder: (context, index) {
        final producto = productosSeleccionados[index];
        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Text(
              producto.producto?.name ?? 'Producto sin nombre',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cantidad: ${producto.cantidad}'),
                Text('Precio: \$${producto.precioLista?.toStringAsFixed(2)}'),
                if (producto.descuento != null && producto.descuento! > 0)
                  Text('Descuento: ${producto.descuento}%'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(producto.precioFinal ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if ((producto.cantidad ?? 0) > 1) {
                          productosCubit.decrementarProducto(producto);
                        } else {
                          productosCubit.eliminarProducto(producto);
                        }
                      },
                    ),
                    Text('${producto.cantidad}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        productosCubit.incrementarProducto(producto);
                      },
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildResumenContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de venta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          const ResumenTabla(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  // Cancelar la venta
                  _showCancelDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => _irAFormaDeCobro(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cobrar'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    // Si estamos en la tab de resumen, mostrar botones de acción
    if (_currentTabIndex == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _showCancelDialog(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => _irAFormaDeCobro(context),
              icon: const Icon(Icons.payment),
              label: const Text('Cobrar'),
            ),
          ],
        ),
      );
    }

    // En la tab de productos, no mostrar barra inferior (usamos el FAB)
    return null;
  }

  void _mostrarDialogoCliente() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Cliente'),
          content: SizedBox(
            width: double.maxFinite,
            child: BuscarCliente(
              onClienteSeleccionado: (ClienteMostrador cliente) {
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCatalogoProductos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Catálogo de Productos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const BuscarProductos(),
              // Lista de productos aquí...
            ],
          ),
        );
      },
    );
  }

  void _irAFormaDeCobro(BuildContext context) {
    final productosState = context.read<ProductosCubit>().state;

    if (productosState.productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un producto')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FormaCobroPage(),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar venta'),
          content: const Text('¿Está seguro que desea cancelar la venta actual?'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sí'),
              onPressed: () {
                // Limpiar productos seleccionados
                context.read<ProductosCubit>().limpiarProductos();
                // Limpiar cliente seleccionado
                context.read<ClientesMostradorCubit>().limpiarClienteSeleccionado();
                // Volver a la página anterior
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
