import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/split_payment_collection.dart';
import '../widget/split_payment_container.dart';
import '../util/platform_service.dart';

/// Página de forma de cobro optimizada para dispositivos móviles
class FormaCobroPageMobile extends StatefulWidget {
  const FormaCobroPageMobile({Key? key}) : super(key: key);

  @override
  State<FormaCobroPageMobile> createState() => _FormaCobroPageMobileState();
}

class _FormaCobroPageMobileState extends State<FormaCobroPageMobile> {
  // Variables de estado
  String _selectedCaja = 'Caja #11';
  bool _isResumenExpanded = true;
  String _tipoDePago = 'Efectivo';
  TextEditingController _montoController = TextEditingController(text: '0');
  TextEditingController _descuentoController = TextEditingController(text: '0');
  String _tipoPago = 'Total';
  String _selectedBanco = 'Efectivo';
  String _selectedMetodo = 'Efectivo';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener cubits y estados necesarios
    final productosCubit = context.watch<ProductosCubit>();
    final paymentMethodsCubit = context.watch<PaymentMethodsCubit>();
    final clienteCubit = context.watch<ClientesMostradorCubit>();

    // Calcular totales
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final totalFinal = subtotal - montoDescuento + iva;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SizedBox(
          width: 150,
          child: Image.network(
            'https://flamincoapp.com.ar/wp-content/uploads/2021/09/logo-flaminco-rojo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.orange),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.orange),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotaObservaciones(),
                  _buildCajaSelector(),
                  _buildTipoPagoSelector(),
                  _buildBancoSelector(),
                  _buildMetodoSelector(),
                  _buildMontoSelector(totalFinal),
                  _buildDescuentoSelector(),
                  _buildTotales(subtotal, iva, descuentoGeneral, montoDescuento, totalFinal),
                  _buildDeliveryOption(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Botón flotante de chat
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.blue,
                child: Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widgets para los diferentes componentes de la interfaz

  Widget _buildNotaObservaciones() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Filas: 3',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Cod venta:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 8),
              Text(
                'CUV-20260128222635-615-2180',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ultima venta:',
                style: TextStyle(fontSize: 16),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.print, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Volver a la version anterior (V1)',
            style: TextStyle(fontSize: 16, color: Colors.orange),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCajaSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caja', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCaja,
                icon: Icon(Icons.keyboard_arrow_down),
                items: ['Caja #10', 'Caja #11', 'Caja #12']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCaja = value!;
                  });
                },
                isExpanded: true,
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTipoPagoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipo de Pago', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tipoPago,
                icon: Icon(Icons.keyboard_arrow_down),
                items: ['Total', 'Parcial']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoPago = value!;
                  });
                },
                isExpanded: true,
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBancoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Banco', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBanco,
                      icon: Icon(Icons.keyboard_arrow_down),
                      items: ['Efectivo', 'Banco Nación', 'Santander', 'Galicia']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBanco = value!;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetodoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Método', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMetodo,
                      icon: Icon(Icons.keyboard_arrow_down),
                      items: ['Efectivo', 'Tarjeta de Crédito', 'Tarjeta de Débito', 'Transferencia']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMetodo = value!;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMontoSelector(double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monto Pagado', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: TextField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: TextButton(
                    child: Text('Pago Total', style: TextStyle(color: Colors.grey.shade700)),
                    onPressed: () {
                      setState(() {
                        _montoController.text = total.toStringAsFixed(2);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDescuentoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descuento', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
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
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: TextField(
                    controller: _descuentoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTotales(double subtotal, double iva, double descuentoGeneral, double montoDescuento, double totalFinal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Text('\$ 0,00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recargo: (0%)', style: TextStyle(fontSize: 16)),
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
              Text('Total:', style: TextStyle(fontSize: 16)),
              Text('\$ ${totalFinal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Retiro en el local',
            style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final productosCubit = context.read<ProductosCubit>();
    final totalFinal = productosCubit.calcularSubtotal() + productosCubit.calcularIva();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
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
              onPressed: () => _confirmarVenta(context),
              child: Text('Guardar', style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deuda:', style: TextStyle(fontSize: 16)),
              Text('\$ ${totalFinal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 50), // Space for FAB
        ],
      ),
    );
  }

  // Método para mostrar el diálogo de confirmación de venta
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
              // Guardar venta y salir - utilizando la lógica original
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a pantalla anterior
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}