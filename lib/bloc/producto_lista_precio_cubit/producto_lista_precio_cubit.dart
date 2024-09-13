import 'package:facturador_offline/bloc/producto_lista_precio_cubit/producto_lista_precio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/productos_lista_precios_model.dart';
import '../../services/user_repository.dart';

class ProductosListaPreciosCubit extends Cubit<ProductosListaPreciosState> {
  final UserRepository userRepository;

  ProductosListaPreciosCubit(this.userRepository)
      : super(ProductosListaPreciosState(currentList: []));

  // Método para obtener la lista de productos en una lista de precios desde la base de datos
  Future<void> getProductosListaPreciosBD(int listaId) async {
    try {
      // Llamamos al método del repositorio para obtener la lista de productos en una lista de precios
      final list = await userRepository.fetchProductosListaPrecios(listaId);

      // Emitimos un nuevo estado con la lista de productos obtenida
      emit(ProductosListaPreciosState(currentList: list));
    } catch (e) {

      print("Error al obtener productos de la lista de precios: $e");

      // También podrías emitir un estado de error, si tienes un estado definido para eso
      // emit(ProductosListaPreciosStateError());
    }
  }

  // Método para agregar un producto a la lista de precios
  void addProductoListaPrecio(ProductosListaPreciosModel producto) {
    final updatedList = List<ProductosListaPreciosModel>.from(state.currentList);
    updatedList.add(producto);
    emit(state.copyWith(currentList: updatedList));
  }

  // Método para eliminar un producto de la lista de precios
  void removeProductoListaPrecio(int productId) {
    final updatedList = state.currentList.where((item) => item.productId != productId).toList();
    emit(state.copyWith(currentList: updatedList));
  }
}
