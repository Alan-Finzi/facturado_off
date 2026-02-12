import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Method to load invoicing data - mejorado con recuperación de errores
  Future<void> _cargarDatosFacturacion() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Verificar si ya hay datos cargados en memoria (variable estática)
      if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
        print('✅ Usando datos de facturación ya cargados en memoria: ${DatosFacturacionModel.datosFacturacionCurrent.length} registros');

        if (mounted) {
          setState(() {
            datosFacturacion = List<DatosFacturacionModel>.from(DatosFacturacionModel.datosFacturacionCurrent);
            _datosFacturacionCargados = true;
            _isLoading = false;
          });

          // Actualizar ProductosCubit con los datos
          context.read<ProductosCubit>().updateDatosFacturacion(datosFacturacion);
          return;
        }
      }

      // 2. Intentar obtener el comercioId
      String? comercioId;
      final loginCubit = context.read<LoginCubit>();

      // Intentar obtener del usuario
      if (loginCubit.state.user != null && loginCubit.state.user!.comercioId != null) {
        comercioId = (loginCubit.state.user!.comercioId == "1")
            ? loginCubit.state.user!.id.toString()
            : loginCubit.state.user!.comercioId!;
        print('🔍 Usando comercioId desde usuario: $comercioId');
      }

      // Si no hay comercioId del usuario, intentar desde SharedPreferences
      if (comercioId == null || comercioId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedComercioId = prefs.getString('datos_facturacion_comercio_id');
        if (savedComercioId != null && savedComercioId.isNotEmpty) {
          comercioId = savedComercioId;
          print('🔍 Usando comercioId desde SharedPreferences: $comercioId');
        } else {
          comercioId = "1"; // Valor por defecto
          print('⚠️ Usando comercioId por defecto: 1');
        }
      }

      // 3. Buscar datos para este comercioId
      List<DatosFacturacionModel> datos = [];

      try {
        datos = await DatabaseHelper.instance.getAllDatosFacturacionCommerce(int.tryParse(comercioId) ?? 0);
        print('📊 Se encontraron ${datos.length} registros para comercioId=$comercioId');
      } catch (dbError) {
        print('❌ Error al buscar datos para comercioId=$comercioId: $dbError');
      }

      // 4. Si no hay datos específicos, intentar con cualquier dato disponible
      if (datos.isEmpty) {
        print('⚠️ No se encontraron datos específicos. Buscando cualquier dato de facturación...');
        try {
          datos = await DatabaseHelper.instance.getAllDatosFacturacion();
          if (datos.isNotEmpty) {
            print('✅ Se encontraron ${datos.length} datos alternativos');
          }
        } catch (allError) {
          print('❌ Error al buscar todos los datos: $allError');
        }
      }

      // 5. Si aún no hay datos, crear dato de emergencia
      if (datos.isEmpty) {
        print('⚠️ No hay datos disponibles. Creando dato de emergencia...');
        final datoEmergencia = DatosFacturacionModel(
          id: 999,
          razonSocial: "Datos de Emergencia",
          comercioId: int.tryParse(comercioId) ?? 1,
          condicionIva: CondicionIva.MONOTRIBUTO,
          cuit: "00000000000",
          ptoVenta: "1",
          predeterminado: 1
        );

        try {
          await DatabaseHelper.instance.insertDatosFacturacion(datoEmergencia);
          print('✅ Dato de emergencia guardado en BD');

          // Actualizar SharedPreferences con este comercioId
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('datos_facturacion_comercio_id', comercioId);
        } catch (saveError) {
          print('❌ Error al guardar dato de emergencia: $saveError');
        }

        datos = [datoEmergencia];
      }

      // 6. Asegurarse de que los datos estén en la variable estática
      if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty && datos.isNotEmpty) {
        DatosFacturacionModel.datosFacturacionCurrent.addAll(datos);
        print('✅ ${datos.length} datos cargados en variable estática');
      }

      // 7. Actualizar estado
      if (mounted) {
        setState(() {
          datosFacturacion = datos;
          _datosFacturacionCargados = true;
          _isLoading = false;
        });

        // Actualizar ProductosCubit con los datos
        if (datos.isNotEmpty) {
          context.read<ProductosCubit>().updateDatosFacturacion(datos);
        }
      }
    } catch (e) {
      print('Error crítico al cargar datos de facturación: $e');

      // Intento final de recuperación
      try {
        // Crear dato de emergencia en memoria
        final datoEmergencia = DatosFacturacionModel(
          id: 999,
          razonSocial: "Recuperación de Error",
          comercioId: 1,
          condicionIva: CondicionIva.MONOTRIBUTO,
          cuit: "00000000000",
          ptoVenta: "1",
          predeterminado: 1
        );

        // Añadir a la variable estática
        if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
          DatosFacturacionModel.datosFacturacionCurrent.add(datoEmergencia);
        }

        if (mounted) {
          setState(() {
            datosFacturacion = [datoEmergencia];
            _datosFacturacionCargados = true;
            _isLoading = false;
          });

          // Actualizar ProductosCubit
          context.read<ProductosCubit>().updateDatosFacturacion([datoEmergencia]);
        }
      } catch (finalError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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