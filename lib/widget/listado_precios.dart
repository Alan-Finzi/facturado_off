// lista_precios.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../models/Producto_precio_stock.dart';

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

  void _initializeControllers(List<ProductoConPrecioYStock> productos) {
    // Ajusta la lista de controladores al tamaño de los productos
    if (_controllers.isEmpty) {
      _controllers = List.generate(
        productos.length,
            (i) => TextEditingController(text: productos[i].cantidad.toString()),
      );
      return;
    }

    final currentLength = _controllers.length;
    final newLength = productos.length;

    if (newLength > currentLength) {
      _controllers.addAll(List.generate(
        newLength - currentLength,
            (i) => TextEditingController(text: productos[currentLength + i].cantidad.toString()),
      ));
    } else if (newLength < currentLength) {
      for (int i = newLength; i < currentLength; i++) {
        _controllers[i].dispose();
      }
      _controllers = _controllers.sublist(0, newLength);
    }

    for (int i = 0; i < newLength; i++) {
      _controllers[i].text = productos[i].cantidad.toString();
    }
  }

  double _calcularSumaTotal(List<ProductoConPrecioYStock> productos) {
    return productos.fold(0.0, (total, p) => total + (p.precioFinal ?? 0));
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductosCubit, ProductosState>(
      buildWhen: (prev, curr) =>
      prev.productosSeleccionados != curr.productosSeleccionados ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        if (_controllers.length != state.productosSeleccionados.length) {
          _initializeControllers(state.productosSeleccionados);
        }

        final sumaTotal = _calcularSumaTotal(state.productosSeleccionados);

        Future.microtask(() {
          context.read<ResumenCubit>().changResumen(
            descuentoPromoTotal: 0,
            descuentoTotal: 0,
            ivaTotal: 0,
            ivaIncl: true,
            subtotal: 0,
            totalFacturar: sumaTotal,
            totalSinDescuento: 0,
            percepciones: 0,
            totalConDescuentoYPercepciones: 0,
          );
        });

        return Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dataTextStyle: const TextStyle(fontSize: 11),
                headingTextStyle: const TextStyle(fontSize: 12),
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
                rows: List.generate(
                  state.productosSeleccionados.length,
                      (index) {
                    final p = state.productosSeleccionados[index];
                    final cantidadText = p.cantidad.toString();
                    if (_controllers[index].text != cantidadText) {
                      _controllers[index].text = cantidadText;
                    }

                    return DataRow(
                      key: ValueKey('${p.datum?.id ?? 'null'}_$index'),
                      cells: [
                        DataCell(Text(p.datum?.barcode ?? 'Sin código')),
                        DataCell(Text(p.datum?.nombre ?? 'Sin nombre')),
                        DataCell(Text('\$ ${p.precioLista ?? ''}')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, -1),
                              ),
                              SizedBox(
                                width: 50,
                                child: TextField(
                                  controller: _controllers[index],
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => context
                                      .read<ProductosCubit>()
                                      .precioTotal(index, int.tryParse(v) ?? 0),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, 1),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Flexible(child: Text(p.promo ?? '')),
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${p.iva} %')),
                        DataCell(Text('\$ ${(p.precioFinal ?? 0).toStringAsFixed(2)}')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => context.read<ProductosCubit>().eliminarProducto(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (state.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
