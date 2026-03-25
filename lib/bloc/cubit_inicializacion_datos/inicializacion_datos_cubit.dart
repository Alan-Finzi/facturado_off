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
        userCompleto = await dbHelper.getUserByEmail(user.email ?? user.username!);
        if (userCompleto == null) {
          userCompleto = user;
        }
        User.setCurrencyUser(userCompleto);
      } catch (e) {
        userCompleto = user;
      }

      // 2. Cargar datos de facturación
      emit(InicializacionDatosEnProgreso(mensaje: "Cargando datos de facturación...", progreso: 0.4));
      try {
        await _cargarDatosFacturacion(userCompleto, dbHelper);
      } catch (e) {
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
        await dbHelper.loadAllCurrencyModels(userCompleto);
      } catch (e) {
        // No es crítico, continuamos igual
      }

      emit(InicializacionDatosExitosa());
    } catch (e) {
      emit(InicializacionDatosError("Error general: $e"));
    }
  }

  Future<void> _cargarDatosFacturacion(User user, DatabaseHelper dbHelper) async {
    DatosFacturacionModel.datosFacturacionCurrent.clear();

    final prefs = await SharedPreferences.getInstance();
    final savedComercioId = prefs.getString('datos_facturacion_comercio_id');
    int comercioId = 0;

    if (user.comercioId != null && user.comercioId!.isNotEmpty) {
      comercioId = int.tryParse(user.comercioId!) ?? 0;
    } else if (savedComercioId != null && savedComercioId.isNotEmpty && savedComercioId != '0') {
      comercioId = int.tryParse(savedComercioId) ?? 0;
    }

    List<DatosFacturacionModel> datosList = [];

    try {
      // MEJORA: Añadimos manejo de errores más robusto y reintentos
      int intentos = 0;
      const maxIntentos = 3;
      bool exito = false;
      Exception? ultimoError;

      while (intentos < maxIntentos && !exito) {
        intentos++;
        try {
          datosList = await dbHelper.getAllDatosFacturacionCommerce(comercioId);
          if (datosList.isNotEmpty) {
            await prefs.setString('datos_facturacion_comercio_id', comercioId.toString());
            exito = true;
            break;
          } else {
            await Future.delayed(Duration(milliseconds: 500));
          }
        } catch (e) {
          ultimoError = e as Exception;
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      // Si después de todos los intentos no tuvimos éxito, lanzamos el último error
      if (!exito && ultimoError != null && datosList.isEmpty) {
        throw ultimoError;
      }
    } catch (e) {
      datosList = [];
    }

    if (datosList.isEmpty) {
      try {
        final todosLosDatos = await dbHelper.getAllDatosFacturacion();
        if (todosLosDatos.isNotEmpty) {
          datosList = todosLosDatos;
          if (datosList.first.comercioId != null) {
            await prefs.setString('datos_facturacion_comercio_id', datosList.first.comercioId.toString());
          }
        }
      } catch (e) {
        // Error al buscar datos alternativos
      }
    }

    if (datosList.isEmpty) {

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

      try {
        await dbHelper.insertDatosFacturacion(datoEmergencia);
        if (datoEmergencia.comercioId != null) {
          await prefs.setString('datos_facturacion_comercio_id', datoEmergencia.comercioId.toString());
        }
      } catch (e) {
        // Continuamos con el dato en memoria aunque no se pueda guardar
      }
    }

    DatosFacturacionModel.datosFacturacionCurrent.addAll(datosList);

    if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
      throw Exception('CRÍTICO: No se pudieron cargar datos de facturación en memoria');
    }
  }

  bool _verificarDatosCargados() {
    return DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty &&
        User.currencyUser != null;
  }
}