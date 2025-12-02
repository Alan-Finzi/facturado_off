import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:facturador_offline/pages/page_forma_cobro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_state.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../helper/database_helper.dart';
import '../helper/sales_database_helper.dart';
import '../models/datos_facturacion_model.dart';
import '../models/payment_method.dart';
import '../models/sales/sale.dart';
import '../models/sales/sale_detail.dart';
import '../pages/page_ventas_sincronizacion.dart';
import '../widget/buildDropdowns.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';
import '../widget/resumen_widget.dart';

class VentaMainPage extends StatefulWidget {
  @override
  _VentaMainPageState createState() => _VentaMainPageState();
}

class _VentaMainPageState extends State<VentaMainPage> {
  int _currentPageIndex = 0;
  String categoriaIvaUser = 'Seleccionar';
  List<DatosFacturacionModel> datosFacturacion = [];
  bool datosCargados = false; // Variable para evitar que se recarguen los datos
  bool _isLoading = false; // Variable para mostrar indicador de carga durante operaciones
  // Las páginas se crearán en el método build para poder pasar el callback actualizado

  @override
  Widget build(BuildContext context) {
    // Creamos la lista de páginas aquí para poder pasar los callbacks actualizados
    final List<Widget> pages = [
      const NuevaVentaPage(),
      FormaCobroPage(
        onBackPressed: () {
          // Volver a la página anterior al presionar el botón
          _navigateToPage(0);
        },
      ),
    ];

    return BlocProvider<PaymentMethodsCubit>(
      create: (context) => PaymentMethodsCubit(databaseHelper: DatabaseHelper.instance),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Proceso de Venta'),
            ),
            body: Row(
              children: [
                Expanded(
                  child: pages[_currentPageIndex],
                ),
                _buildResumenDeVenta(context),
              ],
            ),
          ),
          // Indicador de carga que se muestra cuando está procesando
          _isLoading
            ? Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 20.0),
                      Text(
                        'Guardando venta...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10.0),
                      Text('Procesando información'),
                    ],
                  ),
                ),
              ),
            )
            : Container(), // Widget vacío cuando no está cargando
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  Widget _buildResumenDeVenta(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();

   String? userIdOrComercioId = (loginCubit.state.user!.comercioId == "1")
        ? loginCubit.state.user!.id.toString()
        : loginCubit.state.user!.comercioId;
    return SingleChildScrollView(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            VentaDropdownsWidget(comercioId: userIdOrComercioId!),
          const SizedBox(height: 16.0),
            const Text('Resumen de venta'),
            // Si estamos en la página de forma de cobro, mostraremos el ResumenTabla
            // con el botón de guardar en esa página, no aquí
            const ResumenTabla(),
            const SizedBox(height: 16.0),
            _buildBotonesAccion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _navigateToPage(0),// Cancelar
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_currentPageIndex == 0) {
              // Si estamos en la primera página, simplemente navegamos a la segunda
              _navigateToPage(1);
            } else {
              // Si estamos en la segunda página (forma de cobro), guardamos la venta
              _guardarVentaConEnvio(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text(_currentPageIndex == 0 ? 'SIGUIENTE' : 'GUARDAR'),
        ),
      ],
    );
  }

  // Método para guardar la venta con la información de envío
  void _guardarVentaConEnvio(BuildContext context) {
    // Obtener el estado actual
    final productosCubit = context.read<ProductosCubit>();
    final clienteCubit = context.read<ClientesMostradorCubit>();
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

    // 5. Validar tipo de envío (esto debe hacerse en la página forma_cobro)
    // Aquí necesitaríamos la información del FormaCobroPage, que no tenemos directamente
    // Para este caso, podemos hacer que la página FormaCobroPage valide esto antes

    // Si hay campos faltantes, mostrar error
    if (camposFaltantes.isNotEmpty) {
      _mostrarErrorCamposFaltantes(context, camposFaltantes);
      return;
    }

    // Si todas las validaciones pasan, mostrar el popup de confirmación
    _mostrarPopupConfirmacionVenta(context);
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

  // Muestra un popup de confirmación de la venta con los detalles
  void _mostrarPopupConfirmacionVenta(BuildContext context) {
    final productosCubit = context.read<ProductosCubit>();
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Obtener datos para mostrar
    final cliente = clienteCubit.state.clienteSeleccionado;
    final productos = productosCubit.state.productosSeleccionados;
    final subtotal = productos.fold(0.0, (sum, producto) => sum + (producto.precioLista ?? 0.0));
    final descuento = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuento / 100);
    final iva = productos.fold(0.0, (sum, producto) => sum + (producto.iva ?? 0.0));
    final total = subtotal - montoDescuento + iva;

    // Obtener método de pago seleccionado
    PaymentMethod? metodoPago;
    String metodoPagoNombre = 'No seleccionado';
    if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
      final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
      if (state.selectedMethodId != null && state.selectedProviderId != null) {
        for (final provider in state.providers) {
          if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
            for (final method in provider.metodosPago!) {
              if (method.id == state.selectedMethodId) {
                metodoPago = method;
                metodoPagoNombre = method.nombre;
                break;
              }
            }
            if (metodoPago != null) break;
          }
        }
      }
    }

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

              // Totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:'),
                  Text('\$${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              if (descuento > 0) Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Descuento (${descuento.toStringAsFixed(2)}%):'),
                  Text('-\$${montoDescuento.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IVA:'),
                  Text('\$${iva.toStringAsFixed(2)}'),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),

              // Método de pago
              SizedBox(height: 16),
              Text('Método de pago:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(metodoPagoNombre),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cerrar el diálogo
              Navigator.of(context).pop();
              // Guardar la venta
              _guardarVentaEnBaseDeDatos(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Guardar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar guardar e imprimir
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función guardar e imprimir no implementada aún')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Guardar e imprimir'),
          ),
        ],
      ),
    );
  }

  // Guarda la venta en la base de datos
  Future<void> _guardarVentaEnBaseDeDatos(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true; // Mostrar indicador de carga
      });

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
      final subtotal = productos.fold(0.0, (sum, producto) => sum + (producto.precioLista ?? 0.0));
      final descuentoGeneral = productosCubit.state.descuentoGeneral;
      final montoDescuento = subtotal * (descuentoGeneral / 100);
      final iva = productos.fold(0.0, (sum, producto) => sum + (producto.iva ?? 0.0));
      final total = subtotal - montoDescuento + iva;

      // Cliente
      final cliente = clienteCubit.state.clienteSeleccionado;

      // Método de pago
      PaymentMethod? metodoPago;
      String metodoPagoNombre = 'Efectivo';

      // Obtener el método de pago seleccionado
      if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
        final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
        if (state.selectedMethodId != null && state.selectedProviderId != null) {
          // Buscar el método en los proveedores
          for (final provider in state.providers) {
            if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
              for (final method in provider.metodosPago!) {
                if (method.id == state.selectedMethodId) {
                  metodoPago = method;
                  metodoPagoNombre = method.nombre;
                  break;
                }
              }
              if (metodoPago != null) break;
            }
          }
        }
      }

      // Datos de facturación
      final datosFacturacion = productosCubit.state.datosFacturacionModel?.isNotEmpty == true
          ? productosCubit.state.datosFacturacionModel!.first
          : null;

      // Canal de venta y caja
      final canalVenta = productosCubit.state.canalVenta ?? 'Mostrador';
      final cajaId = 1; // Valor por defecto, idealmente sería configurable

      // Domicilio de entrega
      // Nota: Como estamos en la página principal, no tenemos acceso a _datosEnvio
      // que está en FormaCobroPage. En este caso, dejaremos este valor como null.
      String? domicilioEntrega = null;

      // Crear el objeto de venta
      final sale = Sale(
        fecha: DateTime.now(),
        comercioId: comercioId,
        clienteId: cliente?.idCliente != null ? int.tryParse(cliente!.idCliente!) : null,
        domicilioEntrega: domicilioEntrega,
        tipoComprobante: productosCubit.state.tipoFactura ?? 'Ticket',
        datosFacturacionId: datosFacturacion?.id,
        subtotal: subtotal,
        iva: iva,
        total: total,
        descuento: montoDescuento,
        recargo: 0.0, // No estamos manejando recargos por ahora
        metodoPago: metodoPagoNombre,
        metodoPagoDetalles: metodoPago?.descripcion,
        sincronizado: 0, // No sincronizado inicialmente
        eliminado: 0,
        estado: 'completada', // Estado inicial
        userId: userId,
        canalVenta: canalVenta,
        cajaId: cajaId,
        notaInterna: null, // Aquí podríamos agregar una nota interna si la UI lo permite
        observaciones: null, // Aquí podríamos agregar observaciones si la UI lo permite
      );

      // Crear detalles de venta para cada producto
      final detalles = productos.map((producto) {
        final porcentajeIva = (producto.iva ?? 0.0) > 0
            ? ((producto.iva ?? 0.0) / (producto.precioLista ?? 1.0)) * 100
            : 0.0;

        return SaleDetail.calculate(
          ventaId: 0, // Se actualizará después de insertar la venta
          productoId: producto.producto?.id ?? 0,
          codigoProducto: producto.producto?.barcode,
          nombreProducto: producto.producto?.name ?? 'Producto sin nombre',
          descripcion: null,
          cantidad: 1.0, // Por defecto 1, pero debería ser configurable
          precioUnitario: producto.precioLista ?? 0.0,
          porcentajeIva: porcentajeIva,
          descuento: 0.0, // No manejamos descuentos individuales por ahora
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

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta #$ventaId guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navegar a la página de sincronización de ventas
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PageVentasSincronizacion(),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error al guardar venta: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ocultar indicador de carga
        });
      }
    }
  }


}
class dropButtonDatosFact extends StatelessWidget {
  const dropButtonDatosFact({
    super.key,
    required this.datosFacturacion,
  });

  final List<DatosFacturacionModel> datosFacturacion;

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que el valor actual exista en la lista
    DatosFacturacionModel? selected = DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty
        ? DatosFacturacionModel.datosFacturacionCurrent.first
        : null;

    // Si el valor actual no está en la lista, agregarlo
    if (selected != null && !datosFacturacion.contains(selected)) {
      selected = null;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DropdownButton<DatosFacturacionModel>(
        value: selected,
        onChanged: (DatosFacturacionModel? selectedFactura) {
          if (selectedFactura != null) {
            DatosFacturacionModel.datosFacturacionCurrent
              ..clear()
              ..add(selectedFactura);

            context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);

            print("Seleccionado: ${selectedFactura.razonSocial} - ${selectedFactura.condicionIva}");
          }
        },
        items: datosFacturacion.map((factura) {
          String condicionIvaText = factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';
          return DropdownMenuItem<DatosFacturacionModel>(
            value: factura,
            key: Key(factura.id.toString()),
            child: Text(
              '${factura.razonSocial?.isNotEmpty == true ? factura.razonSocial : 'Sin razón social'} - $condicionIvaText',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
            ),
          );
        }).toList(),
        isExpanded: false,
        iconSize: 20,
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}



// Página de nueva venta
class NuevaVentaPage extends StatefulWidget {
  const NuevaVentaPage({super.key});

  @override
  _NuevaVentaPageState createState() => _NuevaVentaPageState();
}

class _NuevaVentaPageState extends State<NuevaVentaPage> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // Contenido principal
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuscarClienteWidget(
                  clearProductsOnSelection: true,
                  showSelectedClient: true,
                ),
                const SizedBox(height: 16.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: BuscarProductoScanner(),
                    ),
                    const SizedBox(width: 8.0), // Espaciado entre widgets
                    Expanded(
                      flex:2,
                      child: BuscarProductoWidget(),
                    ),
                    Expanded(
                      flex: 1,
                      child: Hero(
                        // Asignar tag único para este botón que navega al catálogo
                        tag: 'ver_catalogo_button',
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CatalogoPage()),
                            );
                              
                            if (result != null) {
                              await context.read<ProductosCubit>().agregarProducto(result);
                            }
                          },
                          child: const Text('Ver catálogo'),
                        ),
                      ),
                    )
              ],
            ),

            const SizedBox(height: 16.0),
            // Usamos dos BlocBuilders anidados para asegurar que siempre tenemos la información más actualizada
            BlocBuilder<ClientesMostradorCubit, ClientesMostradorState>(
              buildWhen: (previous, current) => previous.clienteSeleccionado?.listaPrecio != current.clienteSeleccionado?.listaPrecio,
              builder: (context, clienteState) {
                // BlocBuilder anidado para acceder también a la información de las listas de precios
                return BlocBuilder<ListaPreciosCubit, ListaPreciosState>(
                  builder: (context, listasState) {
                    // Por defecto, mostrar 'Precio base'
                    String listaPrecioNombre = 'Precio base';
                    
                    // Si hay un cliente seleccionado, intentar obtener el nombre de su lista de precios
                    if (clienteState.clienteSeleccionado != null && clienteState.clienteSeleccionado!.listaPrecio != null) {
                      final listaId = clienteState.clienteSeleccionado!.listaPrecio!;
                      
                      try {
                        // Buscar la lista de precios por su ID
                        final listaDelCliente = listasState.currentList.firstWhere(
                          (lista) => lista.id == listaId,
                        );
                        
                        if (listaDelCliente.nombre != null) {
                          listaPrecioNombre = listaDelCliente.nombre!;
                          print('Mostrando lista: ${listaDelCliente.nombre} (ID: ${listaDelCliente.id})');
                        }
                      } catch (e) {
                        print('Lista de precio no encontrada: $e');
                      }
                    }
                    
                    return Text('Lista de precios: $listaPrecioNombre');
                  },
                );
              },
            ),
            const SizedBox(height: 16.0),
            ListaPrecios(),
            const SizedBox(height: 16.0),
            _buildNotasYObservaciones(),
          ],
        ),
      ),
      // Indicador de carga que se muestra sobre el contenido
      _isLoading
        ? Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  )
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20.0),
                  Text(
                    'Cargando producto...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.0),
                  Text('Calculando precios y costos'),
                ],
              ),
            ),
          ),
        )
        : Container(), // Widget vacío cuando no está cargando
      ],
    ),
  );
  }

  Widget _buildNotasYObservaciones() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Nota interna',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16.0),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
