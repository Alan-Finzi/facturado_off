// lista_precios.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
class ListaPrecios extends StatefulWidget {
  @override
  _ListaPreciosState createState() => _ListaPreciosState();
}

class _ListaPreciosState extends State<ListaPrecios> {
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final productosCubit = context.read<ProductosCubit>();
   context.read<ResumenCubit>().changResumen(descuentoPromoTotal: 0, descuentoTotal: 0, ivaTotal: 0, ivaIncl: true, subtotal: 0, totalFacturar: 0);
    _initializeControllers(productosCubit.state.productosSeleccionados);
  }

  void _initializeControllers(List<Map<String, dynamic>> productosSeleccionados) {
    _controllers = List.generate(
      productosSeleccionados.length,
          (index) => TextEditingController(
        text: productosSeleccionados[index]['cantidad'].toString(),
      ),
    );
  }

  double _calcularSumaTotal(List<Map<String, dynamic>> productosSeleccionados) {
    return productosSeleccionados.fold(0.0, (total, producto) {
      return total + (producto['precioTotal'] ?? 0.0);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double sumaTotal =0;
    return BlocBuilder<ProductosCubit, ProductosState>(

      builder: (context, state) {
        // Asegúrate de que los controladores se inicialicen correctamente
        if (_controllers.length != state.productosSeleccionados.length) {
          _initializeControllers(state.productosSeleccionados);
        }

        // Calcular sumaTotal
        double sumaTotal = _calcularSumaTotal(state.productosSeleccionados);
        context.read<ResumenCubit>().changResumen(
          descuentoPromoTotal: 0,
          descuentoTotal: 0,
          ivaTotal: 0,
          ivaIncl: true,
          subtotal: 0,
          totalFacturar: sumaTotal,
        );

        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('CÓDIGO')),
              DataColumn(label: Text('NOMBRE')),
              DataColumn(label: Text('PRECIO')),
              DataColumn(label: Text('  CANT')),
              DataColumn(label: Text('PROMO')),
              DataColumn(label: Text('IVA')),
              DataColumn(label: Text('TOTAL')),
              DataColumn(label: Text('ACCIONES')),
            ],
            rows: List<DataRow>.generate(
              state.productosSeleccionados.length,
                  (index) {
                final producto = state.productosSeleccionados[index];
                _controllers[index].text = producto['cantidad'].toString();
                return DataRow(
                  cells: [
                    DataCell(Text(producto['codigo']?? '')),
                    DataCell(Text(producto['nombre']?? '')),
                    DataCell(Text('\$ ${producto['precio']?? ''}')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, -1),
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _controllers[index],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final cantidad = int.tryParse(value) ?? 1;
                                context.read<ProductosCubit>().precioTotal(index, cantidad);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, 1),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Row(
                      children: [
                        Text('${producto['promoName'] ?? ''}'), // Aquí el nombre de la promoción
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            // Aquí va la lógica para cancelar la promoción
                          },
                        ),
                      ],
                    )),
                    DataCell(Text('${producto['iva']} %')),
                    DataCell(Text('\$ ${(producto['precioTotal'] ?? 0).toStringAsFixed(2)}')),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => context.read<ProductosCubit>().eliminarProducto(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}