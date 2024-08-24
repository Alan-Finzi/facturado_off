import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'resumen_state.dart';

class ResumenCubit extends Cubit<ResumenState> {
  ResumenCubit({
    final double subtotal =0,
    final bool ivaIncl =false,
    final double descuentoTotal =0,
    final double descuentoPromoTotal=0,
    final double ivaTotal =0,
    final double totalFacturar=0   }) :
        super(
          ResumenState(
            ivaIncl: ivaIncl,
              descuentoPromoTotal: descuentoPromoTotal,
              descuentoTotal:descuentoTotal,
              ivaTotal:ivaTotal,
              subtotal: subtotal,
              totalFacturar:  totalFacturar,

          ));

  void changResumen(
      { required double descuentoPromoTotal,
       required double descuentoTotal,
       required double ivaTotal,
       required bool ivaIncl,
       required double subtotal,
       required double totalFacturar}){
    emit( ResumenState(descuentoPromoTotal: descuentoPromoTotal, descuentoTotal: descuentoTotal, ivaTotal: ivaTotal, ivaIncl: ivaIncl, subtotal: subtotal, totalFacturar: totalFacturar));
  }
}


