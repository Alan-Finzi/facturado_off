part of 'productos_cubit.dart';

/// Estado para el cubit de productos que almacena toda la información necesaria
/// para la gestión de productos, facturación y ventas
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

 /// Indica si se está procesando la adición de un producto
 final bool isLoading;

 /// Datos de facturación como condición IVA, relación precio-IVA, etc.
 final List<DatosFacturacionModel>? datosFacturacionModel;

 /// Lista de productos que el usuario ha seleccionado para vender/facturar
 final List<ProductoConPrecioYStock> productosSeleccionados;

 /// ID de la lista de precios actualmente seleccionada
 final int? listaPrecios;

 /// Nombre de la lista de precios actualmente seleccionada
 final String? nombreListaPrecios;

 /// Porcentaje de descuento general a aplicar
 final double descuentoGeneral;

 /// Constructor del estado con valores por defecto para la mayoría de propiedades
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
  this.isLoading = false,
  this.productosSeleccionados = const [],
  this.listaPrecios = 1,
  this.nombreListaPrecios = 'Precio base',
 this.descuentoGeneral = 0.0,
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
  bool? isLoading,
  List<ProductoConPrecioYStock>? productosSeleccionados,
  int? listaPrecios,
  String? nombreListaPrecios,
  double? descuentoGeneral,
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
   listaPrecios: listaPrecios ?? this.listaPrecios,
   nombreListaPrecios: nombreListaPrecios ?? this.nombreListaPrecios,
   descuentoGeneral: descuentoGeneral ?? this.descuentoGeneral,
   precioTotal: precioTotal ?? this.precioTotal,
   isLoading: isLoading ?? this.isLoading,
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
  isLoading,
  productosSeleccionados,
  categoriaIvaUser,
  tipoFactura,
  cajaSeleccionada,
  canalVenta,
  listaPrecios,
  nombreListaPrecios,
  descuentoGeneral,
 ];
}
