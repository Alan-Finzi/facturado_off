import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/Producto.dart';
import '../../services/user_repository.dart';

part 'productos_state.dart';


class ProductosCubit extends Cubit<ProductosState> {
  ProductosCubit(this.userRepository, {required List<ProductoModel> currentListProductCubit})
      : super(ProductosState(currentListProductCubit: currentListProductCubit));

  final UserRepository userRepository;

  Future<void> getProductsBD() async {
    final listProduct = await userRepository.getProductos();
    if (listProduct.isNotEmpty) {
      emit(ProductosState(
        currentListProductCubit: listProduct,
        filteredListProductCubit: listProduct,
        categorias: ['Todas las categorías'] + _extractCategorias(listProduct),
      ));
    }
  }

  void filterProducts(String query, String categoriaSeleccionada) {
    final filteredList = state.currentListProductCubit.where((producto) {
      final matchesQuery = producto.name?.toLowerCase().contains(query.toLowerCase()) ?? false ||
          producto.barcode!.toLowerCase().contains(query.toLowerCase()) ?? false;
      final matchesCategoria = categoriaSeleccionada == 'Todas las categorías' || producto.tipoProducto == categoriaSeleccionada;
      return matchesQuery && matchesCategoria;
    }).toList();
    emit(state.copyWith(filteredListProductCubit: filteredList, categoriaSeleccionada: categoriaSeleccionada));
  }

  void setCategoriaSeleccionada(String categoria) {
    filterProducts('', categoria);
  }

  static List<String> _extractCategorias(List<ProductoModel> productos) {
    return productos.map((producto) => producto.tipoProducto ?? 'Sin categoría').toSet().toList();
  }
}