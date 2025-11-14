import 'package:flutter/material.dart';
import '../models/pago_parcial_model.dart';

/// Widget para mostrar un pago parcial en la lista de pagos
class PagoParcialItem extends StatelessWidget {
  /// Pago parcial a mostrar
  final PagoParcial pago;

  /// Índice del pago en la lista (usado para eliminación)
  final int index;

  /// Callback para cuando se solicita eliminar el pago
  final Function(int) onDelete;

  /// Constructor
  const PagoParcialItem({
    Key? key,
    required this.pago,
    required this.index,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Columna izquierda: información del método de pago
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pago.tipoCobroNombre ?? 'Sin tipo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    pago.formaCobroNombre ?? 'Sin forma',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Columna derecha: información del monto
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${pago.montoPago.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (pago.montoRecargo > 0)
                    Text(
                      '+ \$${pago.montoRecargo.toStringAsFixed(2)} (${pago.porcentajeRecargo.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Botón para eliminar
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => onDelete(index),
              tooltip: 'Eliminar pago',
            )
          ],
        ),
      ),
    );
  }
}