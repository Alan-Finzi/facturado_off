part of 'resumen_cubit.dart';

 class ResumenState extends Equatable {
  final double subtotal;
  final double descuentoTotal;
  final double descuentoPromoTotal;
  final bool ivaIncl;
  final double ivaTotal;
  final double totalFacturar;

 const ResumenState({
   required this.descuentoPromoTotal,
   required this.descuentoTotal,
   required this.ivaTotal,
   required this.ivaIncl,
   required this.subtotal,
   required this.totalFacturar

 });

  @override
  List<Object> get props => [
    descuentoPromoTotal,
    descuentoTotal,
    ivaIncl,
    ivaTotal,
    subtotal,
    totalFacturar
  ];
}


