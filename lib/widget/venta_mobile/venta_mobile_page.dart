import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facturador_offline/bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import 'package:facturador_offline/bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/models/Producto_precio_stock.dart';
import 'package:facturador_offline/widget/venta_mobile/acciones_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/buscador_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/datos_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/producto_item_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/resumen_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/selector_entrega_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/venta_header.dart';
import 'package:facturador_offline/widget/buscar_cliente.dart';
import 'package:facturador_offline/widget/buscar_productos.dart';
import 'package:facturador_offline/pages/page_catalogo.dart';

/// Página principal de venta para dispositivos móviles con enfoque modular.
/// Esta implementación utiliza widgets desacoplados donde la UI está separada de la lógica.
class VentaMobilePage extends StatefulWidget {
  const VentaMobilePage({Key? key}) : super(key: key);

  @override
  State<VentaMobilePage> createState() => _VentaMobilePageState();
}

class _VentaMobilePageState extends State<VentaMobilePage> {
  // Estado local
  String _deliveryType = 'Entregado';
  bool _datosFacturacionCargados = false;
  final TextEditingController _notaInternaController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar datos necesarios
    _cargarDatos();
  }

  /// Método para cargar datos iniciales
  Future<void> _cargarDatos() async {
    // Obtener contexto de BLoC para clientes y productos
    final clientesMostradorCubit = context.read<ClientesMostradorCubit>();
    clientesMostradorCubit.getClientesBD();

    final listasPreciosCubit = context.read<ListaPreciosCubit>();
    listasPreciosCubit.getListasPreciosBD();
  }

  @override
  void dispose() {
    _notaInternaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observar los estados necesarios para actualizar la UI
    final productosCubit = context.watch<ProductosCubit>();
    final clienteCubit = context.watch<ClientesMostradorCubit>();

    // Verificar si hay productos en el carrito
    final productos = productosCubit.state.productosSeleccionados;
    final hasProducts = productos.isNotEmpty;

    // Calcular totales para el resumen
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final total = subtotal - montoDescuento + iva;

    return Scaffold(
      // Encabezado de la aplicación
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: VentaHeader(
          logo: SizedBox(
            width: 120,
            child: Image.network(
              'https://flamincoapp.com.ar/wp-content/uploads/2021/09/logo-flaminco-rojo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),

      backgroundColor: const Color(0xFFF5F7FA),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datos de la venta (título y tipo de factura)
            DatosVentaWidget(
              titulo: 'Punto de Venta',
              prefijo: 'Ejemplo',
              numeroFactura: '21000000001',
              tipoFactura: productosCubit.state.tipoFactura ?? 'Factura B',
              onTipoFacturaChanged: (value) {
                if (value != null) {
                  productosCubit.updateTipoFactura(value);
                }
              },
            ),

            // Buscador de cliente
            BuscadorWidget(
              child: BuscarClienteWidget(
                clearProductsOnSelection: true,
                showSelectedClient: true,
              ),
              onButtonPressed: () {
                // Acción para agregar nuevo cliente
              },
            ),

            // Selector de tipo de entrega
            SelectorEntregaWidget(
              value: _deliveryType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _deliveryType = value;
                  });
                }
              },
            ),

            // Buscador de productos
            BuscadorWidget(
              child: BuscarProductoWidget(),
              onButtonPressed: () => _showCatalogoProductos(),
            ),

            // Botón Ver catálogo
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[300]!),
                  backgroundColor: Colors.white,
                ),
                onPressed: () => _showCatalogoProductos(),
                child: const Text(
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
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Text(
                    'Lista de Precios: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      productosCubit.state.nombreListaPrecios ?? 'Precio Base',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),

            // Productos en el carrito
            if (hasProducts) ...[
              ...productos.asMap().entries.map((entry) {
                final index = entry.key;
                final producto = entry.value;

                // Obtener nombre del producto
                String nombreProducto = '';
                if (producto.producto != null && producto.producto!.name != null) {
                  nombreProducto = producto.producto!.name!;
                } else if (producto.datum != null && producto.datum!.nombre != null) {
                  nombreProducto = producto.datum!.nombre!;
                } else {
                  nombreProducto = 'Producto sin nombre';
                }

                return ProductoItemWidget(
                  nombreProducto: nombreProducto,
                  cantidad: producto.cantidad?.toInt() ?? 1,
                  precioFinal: producto.precioFinal ?? 0.0,
                  onDelete: () => _eliminarProducto(producto, productosCubit, index),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Nota interna
            const Text(
              'Nota interna',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _notaInternaController,
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Escribe una nota interna...',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Observaciones
            const Text(
              'Observaciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Escribe observaciones...',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sección de pago (solo visible si hay productos)
            if (hasProducts) ...[
              // Sección de caja
              const Text(
                'Caja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Caja #11',
                    icon: const Icon(Icons.keyboard_arrow_down),
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
              const SizedBox(height: 16),

              // Tipo de pago
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Pago', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'Total',
                          icon: const Icon(Icons.keyboard_arrow_down),
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

                    // Resumen de la venta con totales
                    ResumenVentaWidget(
                      subtotal: subtotal,
                      descuento: montoDescuento,
                      porcentajeDescuento: descuentoGeneral,
                      iva: iva,
                      total: total,
                      deuda: total, // La deuda inicialmente es igual al total
                    ),

                    // Acciones finales (botones y deuda)
                    AccionesVentaWidget(
                      deuda: total, // La deuda inicialmente es igual al total
                      onCancelar: () => _showCancelDialog(context),
                      onGuardar: () => _confirmarVenta(context),
                    ),
                  ],
                ),
              ),
            ],

            // Espacio adicional al final
            const SizedBox(height: 50),
          ],
        ),
      ),

      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  // Método para mostrar el catálogo de productos
  void _showCatalogoProductos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>  CatalogoPage(),
      ),
    );
  }

  // Método para eliminar un producto del carrito
  void _eliminarProducto(ProductoConPrecioYStock producto, ProductosCubit productosCubit, int index) {
    productosCubit.eliminarProducto(index);
  }

  // Mostrar diálogo de cancelación
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: const Text('¿Está seguro de que desea cancelar la venta actual? Se perderán todos los productos seleccionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              final productosCubit = context.read<ProductosCubit>();
              productosCubit.limpiarProductos();
              Navigator.of(context).pop();
            },
            child: const Text('Sí, cancelar'),
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
          children: const [
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
              const Text('Por favor confirme los detalles de la venta:'),
              const SizedBox(height: 16),

              // Cliente
              const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cliente?.nombre ?? 'Consumidor final'),
              const SizedBox(height: 8),

              // Productos
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Divider(),

              // Mostrar totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                  Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              if (descuentoGeneral > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Descuento (${descuentoGeneral.round()}%):', style: const TextStyle(fontSize: 14)),
                    Text('- \$${montoDescuento.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IVA:', style: TextStyle(fontSize: 14)),
                  Text('\$${iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Aquí iría la lógica para guardar la venta
              productosCubit.limpiarProductos();
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}