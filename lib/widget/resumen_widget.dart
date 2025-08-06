
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';



class ResumenTabla extends StatelessWidget {
    const ResumenTabla({super.key});

    @override
    Widget build(BuildContext context) {
        return BlocBuilder<ProductosCubit, ProductosState>(
            builder: (context, state) {
                final productos = state.productosSeleccionados;

                double subtotal = 0;
                double totalIva = 0;
                double totalFinal = 0;

                for (var producto in productos) {
                    final precioLista = producto.precioLista ?? 0;
                    final cantidad = producto.cantidad ?? 1;
                    final precioFinal = producto.precioFinal ?? 0;

                    subtotal += precioLista * cantidad;
                    totalFinal += precioFinal;
                    totalIva += (precioFinal - (precioLista * cantidad));
                }

                // En este punto podés conectar descuentos reales si los tenés
                const descuentoPromos = 0.0;
                const descuentoGral = 0.0;
                const recargo = 0.0;

                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                        },
                        children: [
                            TableRow(
                                children: [
                                    const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('\$${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                            TableRow(
                                children: [
                                    const Text('- Descuento promociones', style: TextStyle(fontSize: 10)),
                                    Text('- \$${descuentoPromos.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                            TableRow(
                                children: [
                                    Text('- Descuento Gral (${_porcentaje(descuentoGral, subtotal)}%)', style: const TextStyle(fontSize: 10)),
                                    Text('- \$${descuentoGral.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                            TableRow(
                                children: [
                                    const Text('+ Recargo (0%)', style: TextStyle(fontSize: 10)),
                                    Text('+ \$${recargo.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                            TableRow(
                                children: [
                                    const Text('+ IVA'),
                                    Text('+ \$${totalIva.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                            const TableRow(
                                children: [
                                    SizedBox(height: 8.0),
                                    SizedBox(height: 8.0),
                                ],
                            ),
                            TableRow(
                                children: [
                                    const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('\$${totalFinal.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                ],
                            ),
                        ],
                    ),
                );
            },
        );
    }

    static String _porcentaje(double valor, double base) {
        if (base == 0) return '0';
        final porcentaje = (valor / base) * 100;
        return porcentaje.toStringAsFixed(1);
    }
}