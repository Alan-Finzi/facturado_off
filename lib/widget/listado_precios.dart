// lista_precios.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../models/Producto_precio_stock.dart';

/// Este archivo contiene la implementación del widget que muestra la lista de precios
/// y permite manipular productos seleccionados, cantidades y precios.
/// Es clave en la sincronización de precios cuando se selecciona un cliente.
/// Widget que muestra y gestiona la lista de productos seleccionados con sus precios
/// Permite modificar cantidades, eliminar productos y actualiza automáticamente el total
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
    context.read<ResumenCubit>().changResumen(
      descuentoPromoTotal: 0,
      descuentoTotal: 0,
      ivaTotal: 0,
      ivaIncl: true,
      subtotal: 0,
      totalFacturar: 0,
      totalSinDescuento: 0,
      percepciones: 0,
      totalConDescuentoYPercepciones: 0,
    );
    _initializeControllers(productosCubit.state.productosSeleccionados);
  }

  /// Inicializa los controladores de texto para las cantidades de productos
  /// @param productosSeleccionados Lista de productos seleccionados
  void _initializeControllers(List<ProductoConPrecioYStock> productosSeleccionados) {
    _controllers = List.generate(
      productosSeleccionados.length,
          (index) => TextEditingController(
        text: productosSeleccionados[index].cantidad.toString(),
      ),
    );
  }

  /// Calcula la suma total de precios finales de los productos seleccionados
  /// @param productosSeleccionados Lista de productos seleccionados
  /// @return Suma total de los precios finales
  double _calcularSumaTotal(List<ProductoConPrecioYStock> productosSeleccionados) {
    return productosSeleccionados.fold(0.0, (total, producto) {
      return total + (producto.precioFinal ?? 0.0);
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
    return BlocBuilder<ProductosCubit, ProductosState>(
      builder: (context, state) {
        if (_controllers.length != state.productosSeleccionados.length) {
          _initializeControllers(state.productosSeleccionados);
        }

        // Calcular el total y actualizar el estado del resumen
        double sumaTotal = _calcularSumaTotal(state.productosSeleccionados);
        
        // Sincronizar el total calculado con el Cubit de resumen
        // Esta actualización asegura que el UI refleje el precio total correcto
        context.read<ResumenCubit>().changResumen(
          descuentoPromoTotal: 0,
          descuentoTotal: 0,
          ivaTotal: 0,
          ivaIncl: true,
          subtotal: 0,
          totalFacturar: sumaTotal,  // El precio total a facturar
          totalSinDescuento: 0,
          percepciones: 0,
          totalConDescuentoYPercepciones: 0,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataTextStyle: TextStyle(fontSize: 11),
            headingTextStyle: TextStyle(fontSize: 12),
            columns: const [
              DataColumn(label: Text('CÓDIGO')),
              DataColumn(label: Text('NOMBRE')),
              DataColumn(label: Text('PRECIO')),
              DataColumn(label: Text('CANT')),
              DataColumn(label: Text('PROMO')),
              DataColumn(label: Text('IVA')),
              DataColumn(label: Text('TOTAL')),
              DataColumn(label: Text('ACCIONES')),
            ],
            // Usar ListView.builder para listas largas sería más eficiente, 
            // pero para mantener el diseño usamos DataTable con optimización
            rows: List<DataRow>.generate(
              state.productosSeleccionados.length,
                  (index) {
                // Solo procesar los elementos visibles o cerca del área visible
                final producto = state.productosSeleccionados[index];
                _controllers[index].text = producto.cantidad.toString();
                // Usar un key basado en el producto para mejorar la eficiencia de renderizado
                return DataRow(
                  // Asegurar que la clave sea única combinando id del producto con el índice
                  key: ValueKey('${producto.datum?.id ?? 'null'}_$index'),
                  cells: [
                    DataCell(Text(producto.datum?.barcode ?? 'Sin código')),
                    DataCell(Text(producto.datum?.nombre ?? 'Sin nombre')),

                    DataCell(Text('\$ ${producto.precioLista ?? ''}')),
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
                                final cantidad = int.parse(value);
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
                        Flexible(
                          child: Text(producto.promo ?? ''),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            // Lógica para cancelar la promoción
                          },
                        ),
                      ],
                    )),
                    DataCell(Text('${producto.iva} %')),
                    DataCell(Text('\$ ${(producto.precioFinal ?? 0).toStringAsFixed(2)}')),
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
