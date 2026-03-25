import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:facturador_offline/services/service_api.dart';
import 'dart:async';
import '../../helper/database_helper.dart';
import '../cubit_login/login_cubit.dart';

part 'synchronization_state.dart';


class SynchronizationCubit extends Cubit<SynchronizationState> {
  SynchronizationCubit() : super(SynchronizationInitial());
  ApiServices apiServices = ApiServices();

  Future<void> startSynchronization(String token, String email, LoginCubit loginCubit) async {
    try {
      // La aplicación confía en la configuración del dispositivo para mantener la pantalla encendida
      // Se muestra un mensaje al usuario en la interfaz

      emit(SynchronizationInProgress(progress: 0.0, currentTask: "Iniciando sincronización"));

      // Obtener datos de usuario primero para tener acceso al comercio_id actual
      await apiServices.fetchUsersData(token, email, loginCubit);
      emit(const SynchronizationInProgress(progress: 0.1, currentTask: "Sincronización de Usuarios"));

      // Verificar si hubo un cambio de comercio para limpiar datos relacionados
      final String? currentComercioId = loginCubit.state.user?.comercioId;
      if (currentComercioId != null) {
        emit(const SynchronizationInProgress(progress: 0.15, currentTask: "Preparando base de datos"));
      }

      await apiServices.fetchProductosIvas(token);
      emit(const SynchronizationInProgress(progress: 0.2, currentTask: "Sincronización Productos Ivas"));

      await apiServices.fetchDatosFacturacion(token);
      emit(const SynchronizationInProgress(progress: 0.3, currentTask: "Sincronización Datos Facturación"));

      // fetchVariaciones ahora verificará si hay cambio de comercio y limpiará la base de datos si es necesario
      await apiServices.fetchVariaciones(token); // Esta llamada obtiene todos los productos con su stock y precios
      emit(const SynchronizationInProgress(progress: 0.5, currentTask: "Sincronización de Productos"));

      await apiServices.fetchClientesMostrador(token);
      emit(const SynchronizationInProgress(progress: 0.6, currentTask: "Sincronización Clientes"));

      await apiServices.fetchCategorias(token);
      emit(const SynchronizationInProgress(progress: 0.7, currentTask: "Sincronización Categorías"));

      // Agregar la sincronización de métodos de pago
      try {
        emit(const SynchronizationInProgress(progress: 0.8, currentTask: "Sincronización Métodos de Pago"));
        await apiServices.fetchMetodosPago(token);
      } catch (e) {
        // Si falla la obtención de métodos de pago, continuar con la sincronización
      }

      emit(SynchronizationInProgress(progress: 1, currentTask: "Sincronización completada"));
      emit(SynchronizationCompleted());
    } catch (error) {

      emit(SynchronizationFailed(errorMessage: "Error al sincronizar: ${error.toString()}"));
    }
  }

}