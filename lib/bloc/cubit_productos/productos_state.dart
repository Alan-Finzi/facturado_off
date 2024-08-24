part of 'productos_cubit.dart';

class ProductosState extends Equatable {
 final List<ProductoModel> currentListProductCubit;
 final List<ProductoModel>? filteredListProductCubit;
 final List<String> categorias;
 final String categoriaSeleccionada;
 late final bool precioTotal;
 final List<Map<String, dynamic>> productosSeleccionados; // Añadido para manejar productos seleccionados

  ProductosState({
  required this.currentListProductCubit,
  this.filteredListProductCubit,
  this.categorias = const [],
  this.categoriaSeleccionada = '',
  this.precioTotal = false,
  this.productosSeleccionados = const [], // Inicializar con lista vacía
 });

 ProductosState copyWith({
  List<ProductoModel>? currentListProductCubit,
  List<ProductoModel>? filteredListProductCubit,
  List<String>? categorias,
  String? categoriaSeleccionada,
  bool? precioTotal,
  List<Map<String, dynamic>>? productosSeleccionados, // Añadido para manejar productos seleccionados
 }) {
  return ProductosState(
   currentListProductCubit: currentListProductCubit ?? this.currentListProductCubit,
   filteredListProductCubit: filteredListProductCubit ?? this.filteredListProductCubit,
   categorias: categorias ?? this.categorias,
   categoriaSeleccionada: categoriaSeleccionada ?? this.categoriaSeleccionada,
   productosSeleccionados: productosSeleccionados ?? this.productosSeleccionados,
   precioTotal: precioTotal ?? this.precioTotal,
  );
 }

 @override
 List<Object?> get props => [
  currentListProductCubit,
  filteredListProductCubit,
  categorias,
  categoriaSeleccionada,
  precioTotal,
  productosSeleccionados,
 ];
}
