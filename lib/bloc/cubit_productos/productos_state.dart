part of 'productos_cubit.dart';

class ProductosState extends Equatable {
 /// Lista completa de productos obtenidos (sin filtrar)
 final List<ProductoModel> currentListProductCubit;

 /// Lista filtrada de productos según búsqueda/categoría
 final List<ProductoModel>? filteredListProductCubit;

 /// Lista de categorías extraídas de los productos
 final List<String> categorias;

 /// Categoría actualmente seleccionada para filtrar productos
 final String categoriaSeleccionada;

 /// Categoría IVA del usuario (Ej: Monotributo, Responsable Inscripto)
 final String categoriaIvaUser;

 /// Tipo de factura (Ej: Factura A, Factura B, Factura C)
 final String? tipoFactura;

 /// Caja seleccionada para la operación
 final String? cajaSeleccionada;

 /// Canal de venta (Ej: Mostrador, Online, Teléfono)
 final String? canalVenta;

 /// Flag para forzar recálculo o redibujo de precios totales (usado en la UI)
 final bool precioTotal;

 /// Datos de facturación como condición IVA, relación precio-IVA, etc.
 final List<DatosFacturacionModel>? datosFacturacionModel;

 /// Lista de productos que el usuario ha seleccionado para vender/facturar
 final List<ProductoConPrecioYStock> productosSeleccionados;

 ProductosState({
  required this.currentListProductCubit,
  this.filteredListProductCubit,
  this.categoriaIvaUser = "Seleccionar",
  this.tipoFactura = "Factura C",
  this.cajaSeleccionada = "Caja seleccionada: # 1",
  this.canalVenta = "Mostrador",
  this.datosFacturacionModel = const [],
  this.categorias = const [],
  this.categoriaSeleccionada = '',
  this.precioTotal = false,
  this.productosSeleccionados = const [],
 });

 /// Permite crear una nueva copia del estado con algunas propiedades actualizadas
 ProductosState copyWith({
  List<ProductoModel>? currentListProductCubit,
  List<ProductoModel>? filteredListProductCubit,
  List<DatosFacturacionModel>? datosFacturacionModel,
  List<String>? categorias,
  String? categoriaSeleccionada,
  String? categoriaIvaUser,
  String? tipoFactura,
  String? cajaSeleccionada,
  String? canalVenta,
  bool? precioTotal,
  List<ProductoConPrecioYStock>? productosSeleccionados,
 }) {
  return ProductosState(
   currentListProductCubit: currentListProductCubit ?? this.currentListProductCubit,
   filteredListProductCubit: filteredListProductCubit ?? this.filteredListProductCubit,
   datosFacturacionModel: datosFacturacionModel ?? this.datosFacturacionModel,
   categorias: categorias ?? this.categorias,
   categoriaIvaUser: categoriaIvaUser ?? this.categoriaIvaUser,
   tipoFactura: tipoFactura ?? this.tipoFactura,
   cajaSeleccionada: cajaSeleccionada ?? this.cajaSeleccionada,
   canalVenta: canalVenta ?? this.canalVenta,
   categoriaSeleccionada: categoriaSeleccionada ?? this.categoriaSeleccionada,
   productosSeleccionados: productosSeleccionados ?? this.productosSeleccionados,
   precioTotal: precioTotal ?? this.precioTotal,
  );
 }

 /// Equatable: permite comparar estados correctamente y optimizar el renderizado
 @override
 List<Object?> get props => [
  currentListProductCubit,
  filteredListProductCubit,
  datosFacturacionModel,
  categorias,
  categoriaSeleccionada,
  precioTotal,
  productosSeleccionados,
  categoriaIvaUser,
  tipoFactura,
  cajaSeleccionada,
  canalVenta,
 ];
}
