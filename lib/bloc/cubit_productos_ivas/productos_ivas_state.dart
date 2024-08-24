import 'package:equatable/equatable.dart';

import '../../models/productos_ivas_model.dart';


class ProductosIvasState extends Equatable {
  final List<ProductosIvasModel> currentList;

  ProductosIvasState({required this.currentList});

  ProductosIvasState copyWith({List<ProductosIvasModel>? currentList}) {
    return ProductosIvasState(
      currentList: currentList ?? this.currentList,
    );
  }

  @override
  List<Object?> get props => [currentList];
}