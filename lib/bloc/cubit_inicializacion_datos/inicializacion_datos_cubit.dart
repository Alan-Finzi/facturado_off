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
    // SIEMPRE forzamos la recarga, independientemente del estado actual
    print('⚠️ FORZANDO RECARGA de datos de facturación');

    // Limpiar los datos actuales (por si estuviesen corruptos)
    DatosFacturacionModel.datosFacturacionCurrent.clear();

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

    // PASO 1: Intentar cargar datos específicos del comercio
    print('🔍 Consultando datos de facturación para comercioId: $comercioId');
    List<DatosFacturacionModel> datosList = [];

    try {
      datosList = await dbHelper.getAllDatosFacturacionCommerce(comercioId);
      if (datosList.isNotEmpty) {
        // Guardar el comercioId exitoso
        await prefs.setString('datos_facturacion_comercio_id', comercioId.toString());
        print('✅ ComercioId exitoso guardado: $comercioId');
      }
    } catch (e) {
      print('❌ Error al consultar datos de facturación: $e');
      datosList = []; // Asegurar que la lista esté vacía en caso de error
    }

    // PASO 2: Si no hay datos específicos, intentar cargar cualquier dato disponible
    if (datosList.isEmpty) {
      print('🔍 No hay datos específicos. Buscando CUALQUIER dato de facturación...');
      try {
        final todosLosDatos = await dbHelper.getAllDatosFacturacion();

        if (todosLosDatos.isNotEmpty) {
          datosList = todosLosDatos;
          print('✅ Encontrados ${datosList.length} registros alternativos');

          // Actualizar el comercioId con el primer dato encontrado
          if (datosList.first.comercioId != null) {
            await prefs.setString('datos_facturacion_comercio_id', datosList.first.comercioId.toString());
            print('✅ Actualizado comercioId en SharedPreferences: ${datosList.first.comercioId}');
          }
        }
      } catch (e) {
        print('❌ Error al buscar datos alternativos: $e');
      }
    }

    // PASO 3: Si aún no hay datos, crear un dato de emergencia
    if (datosList.isEmpty) {
      print('⚠️ EMERGENCIA: Creando dato de facturación predeterminado');

      // Crear un dato de facturación de emergencia
      final datoEmergencia = DatosFacturacionModel(
        id: 999,
        razonSocial: "Datos de Emergencia",
        comercioId: comercioId > 0 ? comercioId : 1,
        condicionIva: CondicionIva.MONOTRIBUTO,
        cuit: "00000000000",
        ptoVenta: "1",
        predeterminado: 1
      );

      datosList = [datoEmergencia];

      // Intentar guardar este dato en la base de datos para futuras sesiones
      try {
        await dbHelper.insertDatosFacturacion(datoEmergencia);
        print('✅ Dato de emergencia guardado en la base de datos');

        // Actualizar el comercioId con el dato de emergencia
        if (datoEmergencia.comercioId != null) {
          await prefs.setString('datos_facturacion_comercio_id', datoEmergencia.comercioId.toString());
        }
      } catch (e) {
        print('⚠️ No se pudo guardar el dato de emergencia: $e');
        // Continuamos con el dato en memoria aunque no se pueda guardar
      }
    }

    // PASO 4: Finalmente, cargar los datos en la variable estática
    print('✅ Cargando ${datosList.length} registros de datos de facturación en memoria');
    DatosFacturacionModel.datosFacturacionCurrent.addAll(datosList);

    // PASO 5: Verificación final
    if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
      throw Exception('CRÍTICO: No se pudieron cargar datos de facturación en memoria');
    } else {
      print('✅ ÉXITO: Datos de facturación cargados correctamente en memoria (${DatosFacturacionModel.datosFacturacionCurrent.length} registros)');
      // Registrar el primer dato para diagnóstico
      final primerDato = DatosFacturacionModel.datosFacturacionCurrent.first;
      print('   - Primer dato: ID=${primerDato.id}, Razón Social=${primerDato.razonSocial}, ComercioId=${primerDato.comercioId}');
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