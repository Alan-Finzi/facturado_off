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
import '../models/payment_method.dart';
import '../models/payment_provider.dart';
import '../models/Producto_precio_stock.dart';
import '../util/platform_service.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/resumen_widget.dart';
import '../widget/split_payment_container.dart';
import '../widget/listado_precios.dart';
import 'package:facturador_offline/widget/platform_adaptive_widget.dart';
import 'page_catalogo.dart';

/// Página principal de venta optimizada para dispositivos móviles
/// Esta página implementa un diseño responsive que se adapta a pantallas pequeñas
/// siguiendo el diseño de la app Flaminco
class VentaMainPageMobile extends StatefulWidget {
  const VentaMainPageMobile({Key? key}) : super(key: key);

  @override
  State<VentaMainPageMobile> createState() => _VentaMainPageMobileState();
}

class _VentaMainPageMobileState extends State<VentaMainPageMobile> {
  // State variables
  bool _datosFacturacionCargados = false;
  List<DatosFacturacionModel> datosFacturacion = [];
  String _deliveryType = 'Entregado';
  final PlatformService _platformService = PlatformService();

  // Loading states
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Load data
    _cargarDatosFacturacion();
    _initData();
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

    // Calcular totales para el resumen
    final productos = productosCubit.state.productosSeleccionados;
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final total = subtotal - montoDescuento + iva;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: 150,
          child: Image.network(
            'https://flamincoapp.com.ar/wp-content/uploads/2021/09/logo-flaminco-rojo.png',
            fit: BoxFit.contain,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la página
              Text(
                'Punto de Venta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Panel de factura
              Container(
                margin: EdgeInsets.only(bottom: 16),
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

              // Cliente
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      child: BuscarClienteWidget(
                        clearProductsOnSelection: true,
                        showSelectedClient: false,
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
                      onPressed: () {
                        // Agregar nuevo cliente
                      },
                    ),
                  ),
                ],
              ),

              // Tipo de entrega
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
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

              // Campo de búsqueda de productos
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      child: BuscarProductoWidget(),
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

              // Botón Ver catálogo
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
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

              // Lista de precios
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      'Lista de Precios: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        productosCubit.state.nombreListaPrecios ?? 'Precio Base',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),

              // Productos en el carrito
              if (hasProducts) ...[
                ...productos.map((producto) => _buildCartItem(producto, productosCubit)),
                SizedBox(height: 16),
              ],

              // Nota interna
              Text(
                'Nota interna',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'Escribe una nota interna...',
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Observaciones
              Text(
                'Observaciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'Escribe observaciones...',
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Sección de pago (solo visible si hay productos)
              if (hasProducts) ...[
                // Sección de caja
                Text(
                  'Caja',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Caja #10',
                      icon: Icon(Icons.keyboard_arrow_down),
                      isExpanded: true,
                      items: ['Caja #10', 'Caja #11', 'Caja #12']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        // Actualizar caja seleccionada
                        if (value != null) {
                          productosCubit.updateCajaSeleccionada(value);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Tipo de pago
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipo de Pago', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: 'Total',
                            icon: Icon(Icons.keyboard_arrow_down),
                            isExpanded: true,
                            items: ['Total', 'Cuenta corriente / Pago Dividido']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) {
                              // Actualizar tipo de pago
                            },
                          ),
                        ),
                      ),

                      // Configurar pagos (botón naranja)
                      SizedBox(height: 16),
                      Container(
                        width: 200,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {},
                          child: Text('Configurar Pagos'),
                        ),
                      ),

                      // Descuento
                      SizedBox(height: 16),
                      Text('Descuento', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                                left: BorderSide(color: Colors.grey.shade300),
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: '%',
                                icon: Icon(Icons.keyboard_arrow_down),
                                items: ['%', '\$']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (value) {},
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: descuentoGeneral.toString()),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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

                      // Totales
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text('\$ ${subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Descuento:', style: TextStyle(fontSize: 16)),
                          Text('\$ ${montoDescuento.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recargo:', style: TextStyle(fontSize: 16)),
                          Text('\$ 0,00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('IVA:', style: TextStyle(fontSize: 16)),
                          Text('\$ ${iva.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('(incluido en el precio)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('\$ ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Opción de retiro
                      SizedBox(height: 16),
                      Text(
                        'Retiro en el local',
                        style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),

                      // Botones de acción
                      SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _showCancelDialog(context);
                          },
                          child: Text('Cancelar', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _confirmarVenta(context);
                          },
                          child: Text('Guardar', style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      // Deuda
                      if (hasProducts) ...[
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Deuda:', style: TextStyle(fontSize: 16)),
                            Text('\$ ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Agregar espacio al final para que el botón flotante no tape contenido
              SizedBox(height: 70),
            ],
          ),
        ),
      ),

      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  // Método para mostrar el catálogo de productos
  void _showCatalogoProductos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CatalogoPage(),
      ),
    );
  }

  // Construcción de cada elemento del carrito
  Widget _buildCartItem(ProductoConPrecioYStock producto, ProductosCubit productosCubit) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto (placeholder)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(Icons.image, color: Colors.grey),
            ),
          ),
          SizedBox(width: 12),

          // Detalles del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.producto?.name ?? 'Producto sin nombre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$ ${producto.precioLista?.toStringAsFixed(2) ?? '0.00'} / unidad',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),

                // Control de cantidad
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 16),
                            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: () => _decrementarProducto(producto, productosCubit),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${producto.cantidad?.toInt() ?? 1}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, size: 16),
                            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: () => _incrementarProducto(producto, productosCubit),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      '\$ ${producto.precioFinal?.toStringAsFixed(2) ?? '0.00'}',
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

          // Botón para eliminar
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => _eliminarProducto(producto, productosCubit),
          ),
        ],
      ),
    );
  }

  // Incrementar cantidad de un producto
  void _incrementarProducto(ProductoConPrecioYStock producto, ProductosCubit productosCubit) {
    productosCubit.incrementarProducto(producto);
  }

  // Decrementar cantidad de un producto
  void _decrementarProducto(ProductoConPrecioYStock producto, ProductosCubit productosCubit) {
    productosCubit.decrementarProducto(producto);
  }

  // Eliminar un producto del carrito
  void _eliminarProducto(ProductoConPrecioYStock producto, ProductosCubit productosCubit) {
    final index = productosCubit.state.productosSeleccionados.indexOf(producto);
    if (index != -1) {
      productosCubit.eliminarProducto(index);
    }
  }

  // Mostrar diálogo de cancelación
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar venta'),
        content: Text('¿Está seguro de que desea cancelar la venta actual? Se perderán todos los productos seleccionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              final productosCubit = context.read<ProductosCubit>();
              productosCubit.limpiarProductos();
              Navigator.of(context).pop();
            },
            child: Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  // Método para confirmar la venta
  void _confirmarVenta(BuildContext context) {
    final productosCubit = context.read<ProductosCubit>();
    final productosState = productosCubit.state;
    final productos = productosState.productosSeleccionados;
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;

    // Calcular totales
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosState.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final total = subtotal - montoDescuento + iva;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirmar venta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Por favor confirme los detalles de la venta:'),
              SizedBox(height: 16),

              // Cliente
              Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cliente?.nombre ?? 'Consumidor final'),
              SizedBox(height: 8),

              // Productos
              Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...productos.map((producto) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(producto.producto?.name ?? 'Producto sin nombre'),
                    ),
                    Text('\$${producto.precioLista?.toStringAsFixed(2) ?? '0.00'}'),
                  ],
                ),
              )),
              Divider(),

              // Mostrar totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:', style: TextStyle(fontSize: 14)),
                  Text('\$${subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                ],
              ),
              if (descuentoGeneral > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Descuento (${descuentoGeneral.round()}%):', style: TextStyle(fontSize: 14)),
                    Text('- \$${montoDescuento.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IVA:', style: TextStyle(fontSize: 14)),
                  Text('\$${iva.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Aquí iría la lógica para guardar la venta
              // Después limpiar el carrito y volver a la pantalla principal
              productosCubit.limpiarProductos();
              Navigator.of(context).pop();
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}