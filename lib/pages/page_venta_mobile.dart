import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widget/venta_mobile/venta_mobile_page.dart'; // Importar la nueva implementación modular

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

        // Update ProductosCubit with invoicing data
        if (datos.isNotEmpty) {
          context.read<ProductosCubit>().updateDatosFacturacion(datos);
        }
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
    // Si estamos cargando datos, mostrar un indicador de carga
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si los datos de facturación están cargados, mostrar la página principal
    if (_datosFacturacionCargados) {
      // Usar la nueva implementación modular
      return const VentaMobilePage();
    } else {
      // Si aún no se han cargado los datos, mostrar un mensaje de error
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al cargar datos de facturación'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarDatosFacturacion,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
  }
}