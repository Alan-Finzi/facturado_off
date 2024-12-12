import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:facturador_offline/services/service_api.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import '../../helper/database_helper.dart';
import '../cubit_login/login_cubit.dart';

part 'synchronization_state.dart';


class SynchronizationCubit extends Cubit<SynchronizationState> {
  SynchronizationCubit() : super(SynchronizationInitial());
  ApiServices apiServices = ApiServices();

  Future<void> startSynchronization(String token, String email, LoginCubit loginCubit) async {
    try {

      emit(SynchronizationInProgress(progress: 0.0, currentTask: "Iniciando sincronización"));

      await apiServices.fetchUsersData(token, email, loginCubit);
      await apiServices.fetchProductos(token);

      emit(const SynchronizationInProgress(progress: 0.1, currentTask: "Sincronización de Productos"));

      await apiServices.fetchProductosIvas(token);
      emit(const SynchronizationInProgress(progress: 0.2, currentTask: "Sincronización Productos Ivas"));

      await apiServices.fetchProductosListaPrecio(token);
      emit(const SynchronizationInProgress(progress: 0.3, currentTask: "Sincronización Productos Lista Precio"));

      await apiServices.fetchDatosFacturacion(token);
      emit(const SynchronizationInProgress(progress: 0.4, currentTask: "Sincronización Datos Facturacion" ));

      await apiServices.fetchProductosStockSucursals(token);
      emit(const SynchronizationInProgress(progress: 0.6, currentTask: "Sincronización Stock Sucursales"));

      await apiServices.fetchClientesMostrador(token);
      emit(const SynchronizationInProgress(progress: 0.7, currentTask: "Sincronización Clientes"));

      await apiServices.fetchListaPrecio(token);
      emit(const SynchronizationInProgress(progress: 0.8, currentTask: "Sincronización Lista Precio"));

      await apiServices.fetchCategorias(token);
      emit(const SynchronizationInProgress(progress: 0.9, currentTask: "Sincronización Categorías"));

      emit(SynchronizationInProgress(progress: 1, currentTask: "Sincronización completada"));
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'flaminco_appv1_DB.db');
      print('------------------------------');
      print(path.toString());
      print('--------------------------------');

      // Emitimos el estado de sincronización completada
      emit(SynchronizationCompleted());
    } catch (error) {
      emit(SynchronizationFailed(errorMessage: "Error al sincronizar: ${error.toString()}"));
    }
  }

}