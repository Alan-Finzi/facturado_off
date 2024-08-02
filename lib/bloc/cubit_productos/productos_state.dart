part of 'productos_cubit.dart';


class ProductosState extends Equatable {
 final List<ProductoModel> currentListProductCubit;
 final List<ProductoModel>? filteredListProductCubit;
 final List<String> categorias;
 final String categoriaSeleccionada;

 const ProductosState({
  required this.currentListProductCubit,
  this.filteredListProductCubit,
  this.categorias = const [],
  this.categoriaSeleccionada = '',
 });

 ProductosState copyWith({
  List<ProductoModel>? filteredListProductCubit,
  List<String>? categorias,
  String? categoriaSeleccionada,
 }) {
  return ProductosState(
   currentListProductCubit: this.currentListProductCubit,
   filteredListProductCubit: filteredListProductCubit ?? this.filteredListProductCubit,
   categorias: categorias ?? this.categorias,
   categoriaSeleccionada: categoriaSeleccionada ?? this.categoriaSeleccionada,
  );
 }

 @override
 List<Object?> get props => [currentListProductCubit, filteredListProductCubit, categorias, categoriaSeleccionada];
}

