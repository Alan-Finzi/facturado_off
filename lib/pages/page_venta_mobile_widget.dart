import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:facturador_offline/bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import 'package:facturador_offline/bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/bloc/cubit_payment_methods/payment_methods_cubit.dart';
import 'package:facturador_offline/bloc/cubit_login/login_cubit.dart';
import 'package:facturador_offline/models/Producto_precio_stock.dart';
import 'package:facturador_offline/models/payment_method.dart';
import 'package:facturador_offline/models/datos_facturacion_model.dart';
import 'package:facturador_offline/pages/page_ventas_sincronizacion.dart';
import 'package:facturador_offline/widget/venta_mobile/acciones_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/buscador_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/datos_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/producto_item_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/resumen_venta_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/selector_entrega_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/payment_methods_widget.dart';
import 'package:facturador_offline/widget/venta_mobile/venta_header.dart';
import 'package:facturador_offline/widget/buscar_cliente.dart';
import 'package:facturador_offline/widget/buscar_productos.dart';
import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:facturador_offline/helper/sales_database_helper.dart';
import 'package:facturador_offline/models/sales/sale.dart';
import 'package:facturador_offline/models/sales/sale_detail.dart';
import 'package:facturador_offline/widget/dialogs/venta_dialogs.dart';
import 'dart:convert';

/// Página principal de venta para dispositivos móviles con enfoque modular.
/// Esta implementación utiliza widgets desacoplados donde la UI está separada de la lógica.
class PageVentaMobileWidget extends StatefulWidget {
  const PageVentaMobileWidget({Key? key}) : super(key: key);

  @override
  State<PageVentaMobileWidget> createState() => _PageVentaMobileWidgetState();
}

class _PageVentaMobileWidgetState extends State<PageVentaMobileWidget> {
  // Estado local
  String _deliveryType = 'Retiro por sucursal'; // Cambiado para coincidir con nuevas opciones
  bool _datosFacturacionCargados = false;
  Map<String, dynamic>? _datosEnvio; // Para almacenar datos de envío
  double _recargoMetodoPago = 0.0; // Para almacenar el recargo del método de pago seleccionado
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
    final paymentMethodsCubit = context.watch<PaymentMethodsCubit>();

    // Verificar si hay productos en el carrito
    final productos = productosCubit.state.productosSeleccionados;
    final hasProducts = productos.isNotEmpty;

    // Calcular totales para el resumen
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final total = subtotal - montoDescuento + iva;

    // Calcular recargo del método de pago seleccionado
    double recargoAmount = 0.0;
    double recargoPercentage = 0.0;
    if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
      final payState = paymentMethodsCubit.state as PaymentMethodsLoaded;
      if (payState.selectedMethodId != null && payState.selectedProviderId != null) {
        for (final provider in payState.providers) {
          if (provider.id == payState.selectedProviderId) {
            for (final method in provider.metodosPago ?? []) {
              if (method.id == payState.selectedMethodId) {
                recargoPercentage = method.recargo;
                recargoAmount = (total * recargoPercentage) / 100;
                break;
              }
            }
            break;
          }
        }
      }
    }
    final totalConRecargo = total + recargoAmount;

    return Scaffold(
      // Encabezado de la aplicación
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: VentaHeader(
          logo: SizedBox(
            width: 120,
            child: Image.asset(
              'assets/images/app_icon.png',
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
              cliente: clienteCubit.state.clienteSeleccionado,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _deliveryType = value;
                  });
                }
              },
              onEnvioDataChanged: (datos) {
                setState(() {
                  _datosEnvio = datos;
                });
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

              // Métodos de pago - Implementación mejorada
              PaymentMethodsWidget(
                totalVenta: total,
                onPaymentTypeChanged: (isPartialPayment, recargo) {
                  setState(() {
                    // Actualizar recargo si es necesario
                    _recargoMetodoPago = recargo;
                  });
                },
              ),

              // Resumen de la venta con totales
              ResumenVentaWidget(
                subtotal: subtotal,
                descuento: montoDescuento,
                porcentajeDescuento: descuentoGeneral,
                iva: iva,
                recargo: recargoAmount,
                porcentajeRecargo: recargoPercentage,
                total: totalConRecargo,
                deuda: totalConRecargo,
              ),

              // Acciones finales (botones y deuda)
              AccionesVentaWidget(
                deuda: totalConRecargo,
                onCancelar: () => _showCancelDialog(context),
                onGuardar: () => _confirmarVenta(context),
              ),
            ],

            // Espacio adicional al final
            const SizedBox(height: 50),
          ],
        ),
      ),

      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_fab_venta_mobile',
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  // Método para mostrar el catálogo de productos
  Future<void> _showCatalogoProductos() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => CatalogoPage(),
      ),
    );

    if (result != null && mounted) {
      await context.read<ProductosCubit>().agregarProducto(result);
    }
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

  // Método para confirmar la venta - Adaptado para todas las plataformas con validación
  void _confirmarVenta(BuildContext context) async {
    final productosCubit = context.read<ProductosCubit>();
    final productosState = productosCubit.state;
    final productos = productosState.productosSeleccionados;
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Lista para almacenar campos faltantes
    List<String> camposFaltantes = [];

    // 1. Validar cliente seleccionado
    if (clienteCubit.state.clienteSeleccionado == null) {
      camposFaltantes.add("Cliente");
    }

    // 2. Validar productos seleccionados
    if (productosCubit.state.productosSeleccionados.isEmpty) {
      camposFaltantes.add("Productos en la venta");
    }

    // 3. Validar método de pago
    bool tieneMetodoPago = false;
    if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
      final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
      tieneMetodoPago = state.selectedMethodId != null;
    }
    if (!tieneMetodoPago) {
      camposFaltantes.add("Método de pago");
    }

    // 4. Validar datos de facturación
    if (productosCubit.state.datosFacturacionModel == null ||
        productosCubit.state.datosFacturacionModel!.isEmpty) {
      camposFaltantes.add("Datos de facturación");
    }

    // 5. Validar tipo de envío y datos de domicilio si aplica
    if (_datosEnvio == null || _datosEnvio!.isEmpty) {
      camposFaltantes.add("Tipo de envío");
    } else {
      String? tipoEnvio = _datosEnvio!['tipo_envio'] as String?;

      if (tipoEnvio == 'domicilio_cliente') {
        if (_datosEnvio!['calle'] == null || _datosEnvio!['localidad'] == null ||
            _datosEnvio!['provincia'] == null) {
          camposFaltantes.add("Información completa de domicilio del cliente");
        }
      } else if (tipoEnvio == 'otro_domicilio') {
        if (_datosEnvio!['calle'] == null || _datosEnvio!['localidad'] == null ||
            _datosEnvio!['provincia'] == null) {
          camposFaltantes.add("Información completa de domicilio de envío");
        }
      }
    }

    // Si hay campos faltantes, mostrar error y no continuar
    if (camposFaltantes.isNotEmpty) {
      _mostrarErrorCamposFaltantes(context, camposFaltantes);
      return;
    }

    // Si pasamos todas las validaciones, continuar con la venta
    // Calcular totales
    final subtotal = productosCubit.calcularSubtotal();
    final iva = productosCubit.calcularIva();
    final descuentoGeneral = productosState.descuentoGeneral;
    final montoDescuento = subtotal * (descuentoGeneral / 100);
    final total = subtotal - montoDescuento + iva;

    // Calcular recargo del método de pago
    double recargoConfirm = 0.0;
    if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
      final payState = paymentMethodsCubit.state as PaymentMethodsLoaded;
      if (payState.selectedMethodId != null && payState.selectedProviderId != null) {
        for (final provider in payState.providers) {
          if (provider.id == payState.selectedProviderId) {
            for (final method in provider.metodosPago ?? []) {
              if (method.id == payState.selectedMethodId) {
                recargoConfirm = (total * method.recargo) / 100;
                break;
              }
            }
            break;
          }
        }
      }
    }

    // Preparar lista de productos para el diálogo
    List<Map<String, dynamic>> productosParaDialogo = productos.map((producto) {
      return {
        'nombre': producto.producto?.name ?? producto.datum?.nombre ?? 'Producto sin nombre',
        'precio': producto.precioLista ?? 0.0,
      };
    }).toList();

    // Mostrar diálogo de confirmación usando la clase VentaDialogs (compatible con todas las plataformas)
    final confirmado = await VentaDialogs.mostrarConfirmacionVenta(
      context,
      nombreCliente: cliente?.nombre ?? 'Consumidor final',
      productos: productosParaDialogo,
      subtotal: subtotal,
      descuentoGeneral: descuentoGeneral,
      montoDescuento: montoDescuento,
      iva: iva,
      total: total + recargoConfirm,
    );

    // Si el usuario confirmó, proceder con el guardado
    if (confirmado) {
      _guardarVenta(context, total, cliente);
    }
  }

  // Muestra un popup con los campos faltantes
  void _mostrarErrorCamposFaltantes(BuildContext context, List<String> campos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Información incompleta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por favor complete la siguiente información antes de guardar:'),
            SizedBox(height: 12),
            ...campos.map((campo) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(campo),
                ],
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Método para guardar la venta en la base de datos - Adaptado para todas las plataformas
  Future<void> _guardarVenta(BuildContext context, double total, dynamic cliente) async {
    // Mostrar indicador de carga usando la clase VentaDialogs
    VentaDialogs.mostrarCargando(context, mensaje: 'Guardando venta...');

    try {
      // Obtener los datos necesarios de los diferentes cubits
      final productosCubit = context.read<ProductosCubit>();
      final clienteCubit = context.read<ClientesMostradorCubit>();
      final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
      final loginCubit = context.read<LoginCubit>();


      // Datos del usuario actual
      final userId = loginCubit.state.user?.id;
      final comercioId = loginCubit.state.user?.comercioId != null
          ? int.tryParse(loginCubit.state.user!.comercioId!) ?? 0
          : 0;


      // Productos seleccionados
      final productos = productosCubit.state.productosSeleccionados;

      // Calcular totales
      double subtotal = 0;
      double totalIva = 0;

      for (var producto in productos) {
        final precioLista = producto.precioLista ?? 0;
        final cantidad = producto.cantidad ?? 1;
        final precioFinal = producto.precioFinal ?? 0;

        subtotal += precioLista * cantidad;
        totalIva += (precioFinal - (precioLista * cantidad));
      }

      // Descuentos
      final descuentoGeneral = productosCubit.state.descuentoGeneral;
      final montoDescuento = (descuentoGeneral / 100) * subtotal;

      // Recargo del método de pago
      double recargo = 0.0;
      String metodoPagoNombre = 'Efectivo'; // Valor por defecto

      // Método de pago
      if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
        final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
        if (state.selectedMethodId != null && state.selectedProviderId != null) {
          // Buscar el método en los proveedores
          for (final provider in state.providers) {
            if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
              for (final method in provider.metodosPago!) {
                if (method.id == state.selectedMethodId) {
                  metodoPagoNombre = method.nombre;
                  // Calcular recargo si existe
                  final subtotalParaRecargo = subtotal - montoDescuento + totalIva;
                  recargo = method.recargo > 0 ? (method.recargo / 100) * subtotalParaRecargo : 0.0;
                  break;
                }
              }
              if (metodoPagoNombre != 'Efectivo') break;
            }
          }
        }
      }

      // Calcular total final con todos los componentes
      final totalFinal = subtotal - montoDescuento + totalIva + recargo;


      // Datos para la venta
      final tipoComprobante = productosCubit.state.tipoFactura ?? 'Ticket';
      final datosFacturacion = productosCubit.state.datosFacturacionModel?.isNotEmpty == true
          ? productosCubit.state.datosFacturacionModel!.first
          : null;

      // Serializar datos de envío si existen
      String? domicilioEntrega;
      if (_datosEnvio != null && _datosEnvio!.isNotEmpty) {
        try {
          domicilioEntrega = jsonEncode(_datosEnvio);
        } catch (e) {
          domicilioEntrega = _datosEnvio.toString();
        }
      }

      // Crear el objeto de venta
      final sale = Sale(
        fecha: DateTime.now(),
        comercioId: comercioId,
        clienteId: cliente?.idCliente != null ? int.tryParse(cliente!.idCliente!) : null,
        domicilioEntrega: domicilioEntrega,
        tipoComprobante: tipoComprobante,
        datosFacturacionId: datosFacturacion?.id,
        subtotal: subtotal,
        iva: totalIva,
        total: totalFinal,
        descuento: montoDescuento,
        recargo: recargo,
        metodoPago: metodoPagoNombre,
        metodoPagoDetalles: null,
        sincronizado: 0, // No sincronizado inicialmente
        eliminado: 0,
        estado: 'completada', // Estado inicial
        userId: userId,
        canalVenta: 'Móvil',
        cajaId: 1, // Valor por defecto, idealmente sería configurable
        notaInterna: _notaInternaController.text.isNotEmpty ? _notaInternaController.text : null,
        observaciones: _observacionesController.text.isNotEmpty ? _observacionesController.text : null,
      );


      // Crear detalles de venta para cada producto
      final detalles = productos.map((producto) {
        // Calcular porcentaje de IVA
        final precioSinIva = producto.precioLista ?? 0.0;
        final iva = producto.iva ?? 0.0;
        final porcentajeIva = precioSinIva > 0 ? (iva / precioSinIva) * 100 : 21.0; // Por defecto 21%

        return SaleDetail.calculate(
          ventaId: 0, // Se actualizará después de insertar la venta
          productoId: producto.producto?.id ?? 0,
          codigoProducto: producto.producto?.barcode,
          nombreProducto: producto.datum?.nombre ?? producto.producto?.name ?? 'Producto sin nombre',
          descripcion: null,
          cantidad: producto.cantidad ?? 1.0,
          precioUnitario: producto.precioLista ?? 0.0,
          porcentajeIva: porcentajeIva,
          descuento: 0.0, // No manejamos descuentos por producto en la versión móvil
          categoriaId: producto.producto?.tipoProducto != null
              ? int.tryParse(producto.producto!.tipoProducto!)
              : null,
          categoriaNombre: producto.categoria,
        );
      }).toList();

      // Asignar los detalles a la venta
      final ventaConDetalles = sale.copyWith(detalles: detalles);


      // Guardar la venta en la base de datos utilizando SalesDatabaseHelper
      final salesDatabaseHelper = SalesDatabaseHelper();
      final ventaId = await salesDatabaseHelper.saveSale(ventaConDetalles);


      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar popup de éxito usando la clase VentaDialogs
      await VentaDialogs.mostrarExito(
        context,
        ventaId: ventaId,
        total: totalFinal,
        nombreCliente: cliente?.nombre ?? "Consumidor final",
        onAceptar: () {
          // Limpiar productos después de guardar
          productosCubit.limpiarProductos();

          // Navegar a la página de sincronización de ventas
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PageVentasSincronizacion()),
          );
        },
      );
    } catch (e) {

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar popup de error usando la clase VentaDialogs
      await VentaDialogs.mostrarError(
        context,
        error: e.toString(),
        onReintentar: () {
          // Intentar guardar nuevamente
          _guardarVenta(context, total, cliente);
        },
      );
    }
  }
}