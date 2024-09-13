import 'package:equatable/equatable.dart';

import '../../models/productos_lista_precios_model.dart';

class ProductosListaPreciosState extends Equatable {
  final List<ProductosListaPreciosModel> currentList;

  const ProductosListaPreciosState({required this.currentList});

  // Método para copiar el estado con cambios
  ProductosListaPreciosState copyWith({
    List<ProductosListaPreciosModel>? currentList,
  }) {
    return ProductosListaPreciosState(
      currentList: currentList ?? this.currentList,
    );
  }

  @override
  List<Object?> get props => [currentList];
}
