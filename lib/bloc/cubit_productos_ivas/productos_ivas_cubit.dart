import 'package:equatable/equatable.dart';
import 'package:facturador_offline/bloc/cubit_productos_ivas/productos_ivas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/productos_ivas_model.dart';
import '../../services/user_repository.dart';


class ProductosIvasCubit extends Cubit<ProductosIvasState> {
  final UserRepository userRepository;

  ProductosIvasCubit(this.userRepository)
      : super(ProductosIvasState(currentList: []));

// Método para obtener la lista de productos_ivas desde la base de datos
  Future<void> getProductosIvasBD() async {
    try {
      final list = await userRepository.fetchProductosIvas();
      emit(ProductosIvasState(currentList: list));
    } catch (e) {
      print("Error al obtener productos IVAs: $e");
    }
  }

// Método para agregar un producto IVA a la lista y la base de datos
  Future<void> addProductoIva(ProductosIvasModel productoIva) async {
    try {
      await userRepository.addProductoIva(productoIva);
      final updatedList = List<ProductosIvasModel>.from(state.currentList);
      updatedList.add(productoIva);
      emit(state.copyWith(currentList: updatedList));
    } catch (e) {
      print("Error al agregar producto IVA: $e");
    }
  }
}
