part of 'productos_cubit.dart';

class ProductosState extends Equatable {
 final List<ProductoModel> currentListProductCubit;
 final List<ProductoModel>? filteredListProductCubit;
 final List<String> categorias;
 final String categoriaSeleccionada;
 final String categoriaIvaUser;
 late final bool precioTotal;
 final  List<DatosFacturacionModel>? datosFacturacionModel;
 final List<ProductoConPrecioYStock> productosSeleccionados; // Añadido para manejar productos seleccionados

  ProductosState({
  required this.currentListProductCubit,
  this.filteredListProductCubit,
   this.categoriaIvaUser="Seleccionar",
  this.datosFacturacionModel=const [],
  this.categorias = const [],
  this.categoriaSeleccionada = '',
  this.precioTotal = false,
  this.productosSeleccionados = const [],
   // Inicializar con lista vacía
 });

 ProductosState copyWith({
  List<ProductoModel>? currentListProductCubit,
  List<ProductoModel>? filteredListProductCubit,
  List<DatosFacturacionModel>? datosFacturacionModel,
  List<String>? categorias,
  String? categoriaSeleccionada,
  String? categoriaIvaUser,
  bool? precioTotal,
  List<ProductoConPrecioYStock>? productosSeleccionados, // Añadido para manejar productos seleccionados
 }) {
  return ProductosState(
   currentListProductCubit: currentListProductCubit ?? this.currentListProductCubit,
   filteredListProductCubit: filteredListProductCubit ?? this.filteredListProductCubit,
   datosFacturacionModel: datosFacturacionModel?? this.datosFacturacionModel ,
   categorias: categorias ?? this.categorias,
   categoriaIvaUser: categoriaIvaUser?? this.categoriaIvaUser,
   categoriaSeleccionada: categoriaSeleccionada ?? this.categoriaSeleccionada,
   productosSeleccionados: productosSeleccionados ?? this.productosSeleccionados,
   precioTotal: precioTotal ?? this.precioTotal,
  );
 }

 @override
 List<Object?> get props => [
  currentListProductCubit,
  filteredListProductCubit,
  datosFacturacionModel,
  categorias,
  categoriaSeleccionada,
  precioTotal,
  productosSeleccionados,
  categoriaIvaUser
 ];
}
