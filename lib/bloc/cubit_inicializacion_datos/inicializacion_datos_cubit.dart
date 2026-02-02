import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/database_helper.dart';
import '../../models/datos_facturacion_model.dart';
import '../../models/user.dart';

part 'inicializacion_datos_state.dart';

class InicializacionDatosCubit extends Cubit<InicializacionDatosState> {
  InicializacionDatosCubit() : super(InicializacionDatosInicial());

  Future<void> inicializarDatos(User user, String? token) async {
    emit(InicializacionDatosEnProgreso(mensaje: "Iniciando carga de datos...", progreso: 0.05));

    try {
      final dbHelper = DatabaseHelper.instance;

      // 1. Cargar usuario completo
      emit(InicializacionDatosEnProgreso(mensaje: "Cargando información de usuario...", progreso: 0.2));
      User? userCompleto;
      try {
        userCompleto = await dbHelper.getUserByEmail(user.username!);
        if (userCompleto == null) {
          print('❌ No se encontró el usuario en la BD, usando el básico');
          userCompleto = user;
        } else {
          print('✅ Usuario completo cargado desde BD: ${userCompleto.username}');
        }

        // Establecer el usuario actual en memoria para toda la sesión
        User.setCurrencyUser(userCompleto);
        print('✅ Usuario establecido como currencyUser');
      } catch (e) {
        print('⚠️ Error al cargar usuario completo: $e, usando el usuario básico');
        userCompleto = user;
        // A pesar del error, intentamos continuar con el usuario básico
      }

      // 2. Cargar datos de facturación
      emit(InicializacionDatosEnProgreso(mensaje: "Cargando datos de facturación...", progreso: 0.4));
      try {
        await _cargarDatosFacturacion(userCompleto, dbHelper);
      } catch (e) {
        print('❌ Error al cargar datos de facturación: $e');
        emit(InicializacionDatosError("Error al cargar datos de facturación: $e"));
        return;
      }

      // 3. Verificar datos cargados
      emit(InicializacionDatosEnProgreso(mensaje: "Verificando datos...", progreso: 0.7));
      if (!_verificarDatosCargados()) {
        emit(InicializacionDatosError("Los datos de facturación no pudieron ser cargados completamente"));
        return;
      }

      // 4. Cargar otros datos necesarios (productos, clientes, etc.)
      emit(InicializacionDatosEnProgreso(mensaje: "Cargando datos adicionales...", progreso: 0.9));
      try {
        // Intentamos cargar todos los modelos currency
        await dbHelper.loadAllCurrencyModels(userCompleto);
      } catch (e) {
        print('⚠️ Error al cargar datos adicionales: $e');
        // No es crítico, continuamos igual
      }

      // 5. Finalizar con éxito
      print('✅ Inicialización de datos completada con éxito');
      emit(InicializacionDatosExitosa());
    } catch (e) {
      print('❌ Error general en inicialización de datos: $e');
      emit(InicializacionDatosError("Error general: $e"));
    }
  }

  Future<void> _cargarDatosFacturacion(User user, DatabaseHelper dbHelper) async {
    // Verificar si ya están cargados
    if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
      print('✓ Datos de facturación ya estaban cargados');
      return;
    }

    // Obtener el comercioId (preferimos el guardado en SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final savedComercioId = prefs.getString('datos_facturacion_comercio_id');
    int comercioId = 0;

    if (savedComercioId != null && savedComercioId.isNotEmpty) {
      comercioId = int.tryParse(savedComercioId) ?? 0;
      print('🔍 Usando comercioId desde SharedPreferences: $comercioId');
    } else if (user.comercioId != null && user.comercioId!.isNotEmpty) {
      comercioId = int.tryParse(user.comercioId!) ?? 0;
      print('🔍 Usando comercioId desde usuario: $comercioId');
    }

    // Cargar datos de facturación
    print('🔍 Consultando datos de facturación para comercioId: $comercioId');
    final datosList = await dbHelper.getAllDatosFacturacionCommerce(comercioId);

    if (datosList.isEmpty) {
      print('❌ No se encontraron datos de facturación para comercioId: $comercioId');

      // Intentar con cualquier dato de facturación disponible
      print('🔍 Buscando cualquier dato de facturación disponible...');
      final todosLosDatos = await dbHelper.getAllDatosFacturacion();

      if (todosLosDatos.isEmpty) {
        throw Exception('No se encontraron datos de facturación en la base de datos');
      }

      print('✅ Se encontraron ${todosLosDatos.length} registros de datos de facturación alternativos');

      // Usar el primer registro encontrado y actualizar el comercioId
      final primerDato = todosLosDatos.first;
      if (primerDato.comercioId != null) {
        await prefs.setString('datos_facturacion_comercio_id', primerDato.comercioId.toString());
        print('✅ Actualizado comercioId en SharedPreferences: ${primerDato.comercioId}');
      }

      // Cargar los datos alternativos
      DatosFacturacionModel.datosFacturacionCurrent.clear();
      DatosFacturacionModel.datosFacturacionCurrent.addAll(todosLosDatos);
      print('✅ Datos de facturación alternativos cargados: ${todosLosDatos.length} registros');
    } else {
      print('✅ Datos de facturación encontrados para comercioId $comercioId: ${datosList.length} registros');
      DatosFacturacionModel.datosFacturacionCurrent.clear();
      DatosFacturacionModel.datosFacturacionCurrent.addAll(datosList);
    }
  }

  bool _verificarDatosCargados() {
    // Verificar que los datos esenciales estén cargados
    final datosFacturacionOk = DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty;
    final userOk = User.currencyUser != null;

    print('✓ Verificación de datos cargados:');
    print('  - DatosFacturacionModel.datosFacturacionCurrent: ${datosFacturacionOk ? 'CARGADO ✅' : 'VACÍO ❌'} (${DatosFacturacionModel.datosFacturacionCurrent.length} registros)');
    print('  - User.currencyUser: ${userOk ? 'CARGADO ✅' : 'NULO ❌'} (${User.currencyUser?.username ?? "N/A"})');

    return datosFacturacionOk && userOk;
  }
}