import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/datos_facturacion_model.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';

part 'inicializacion_datos_state.dart';

class InicializacionDatosCubit extends Cubit<InicializacionDatosState> {
  InicializacionDatosCubit() : super(InicializacionDatosInicial());

  Future<void> inicializarDatos(User user, String? token) async {
    emit(InicializacionDatosEnProgreso(
        mensaje: 'Iniciando carga de datos...', progreso: 0.05));

    try {
      final fs = FirestoreService.instance;

      // 1. Cargar usuario completo desde Firestore (cache offline disponible)
      emit(InicializacionDatosEnProgreso(
          mensaje: 'Cargando información de usuario...', progreso: 0.2));
      User? userCompleto;
      try {
        userCompleto =
            await fs.getUserByEmail(user.email ?? user.username ?? '');
        userCompleto ??= user;
        User.setCurrencyUser(userCompleto);
      } catch (_) {
        userCompleto = user;
      }

      // 2. Cargar datos de facturación
      emit(InicializacionDatosEnProgreso(
          mensaje: 'Cargando datos de facturación...', progreso: 0.4));
      try {
        await _cargarDatosFacturacion(userCompleto, fs);
      } catch (e) {
        emit(InicializacionDatosError('Error al cargar datos de facturación: $e'));
        return;
      }

      // 3. Verificar datos
      emit(InicializacionDatosEnProgreso(
          mensaje: 'Verificando datos...', progreso: 0.7));
      if (!_verificarDatosCargados()) {
        emit(InicializacionDatosError(
            'Los datos de facturación no pudieron ser cargados completamente'));
        return;
      }

      // 4. Datos adicionales (no críticos)
      emit(InicializacionDatosEnProgreso(
          mensaje: 'Cargando datos adicionales...', progreso: 0.9));

      emit(InicializacionDatosExitosa());
    } catch (e) {
      emit(InicializacionDatosError('Error general: $e'));
    }
  }

  Future<void> _cargarDatosFacturacion(
      User user, FirestoreService fs) async {
    DatosFacturacionModel.datosFacturacionCurrent.clear();

    final prefs = await SharedPreferences.getInstance();
    final savedComercioId = prefs.getString('datos_facturacion_comercio_id');
    int comercioId = 0;

    if (user.comercioId != null && user.comercioId!.isNotEmpty) {
      comercioId = int.tryParse(user.comercioId!) ?? 0;
    } else if (savedComercioId != null &&
        savedComercioId.isNotEmpty &&
        savedComercioId != '0') {
      comercioId = int.tryParse(savedComercioId) ?? 0;
    }

    List<DatosFacturacionModel> datosList = [];

    // Reintentos para esperar que Firestore tenga datos en cache
    for (int i = 0; i < 3; i++) {
      try {
        datosList = await fs.getDatosFacturacion(comercioId);
        if (datosList.isNotEmpty) {
          await prefs.setString(
              'datos_facturacion_comercio_id', comercioId.toString());
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (datosList.isEmpty) {
      datosList = await fs.getAllDatosFacturacion();
      if (datosList.isNotEmpty && datosList.first.comercioId != null) {
        await prefs.setString(
            'datos_facturacion_comercio_id',
            datosList.first.comercioId.toString());
      }
    }

    if (datosList.isEmpty) {
      final datoEmergencia = DatosFacturacionModel(
        id: 999,
        razonSocial: 'Datos de Emergencia',
        comercioId: comercioId > 0 ? comercioId : 1,
        condicionIva: CondicionIva.MONOTRIBUTO,
        cuit: '00000000000',
        ptoVenta: '1',
        predeterminado: 1,
      );
      datosList = [datoEmergencia];
      await fs.upsertDatosFacturacion(datoEmergencia);
    }

    DatosFacturacionModel.datosFacturacionCurrent.addAll(datosList);

    if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
      throw Exception('CRÍTICO: No se pudieron cargar datos de facturación');
    }
  }

  bool _verificarDatosCargados() {
    return DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty &&
        User.currencyUser != null;
  }
}
