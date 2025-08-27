// lista_precios.dart

import 'dart:ui';
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
  /// Optimizado para reutilizar controladores existentes cuando es posible
  void _initializeControllers(List<ProductoConPrecioYStock> productosSeleccionados) {
    // Si no hay controladores o es la primera inicialización, crear todos nuevos
    if (_controllers.isEmpty) {
      _controllers = List.generate(
        productosSeleccionados.length,
        (index) => TextEditingController(
          text: productosSeleccionados[index].cantidad.toString(),
        ),
      );
      return;
    }
    
    // Si hay más productos que controladores, crear nuevos para los adicionales
    final int currentLength = _controllers.length;
    final int newLength = productosSeleccionados.length;
    
    if (newLength > currentLength) {
      // Mantener los controladores existentes y agregar nuevos para los productos adicionales
      final additionalControllers = List.generate(
        newLength - currentLength,
        (index) => TextEditingController(
          text: productosSeleccionados[currentLength + index].cantidad.toString(),
        ),
      );
      _controllers.addAll(additionalControllers);
    } else if (newLength < currentLength) {
      // Si hay menos productos, eliminar los controladores sobrantes
      for (int i = newLength; i < currentLength; i++) {
        _controllers[i].dispose();
      }
      _controllers = _controllers.sublist(0, newLength);
    }
    
    // Actualizar el texto de los controladores existentes
    for (int i = 0; i < newLength; i++) {
      _controllers[i].text = productosSeleccionados[i].cantidad.toString();
    }
  }

  /// Calcula la suma total de precios finales de los productos seleccionados
  /// Optimizado para rendimiento con iteración directa
  double _calcularSumaTotal(List<ProductoConPrecioYStock> productosSeleccionados) {
    // Usar iteración simple para mayor rendimiento en listas grandes
    double total = 0.0;
    final int length = productosSeleccionados.length;
    for (int i = 0; i < length; i++) {
      total += productosSeleccionados[i].precioFinal ?? 0.0;
    }
    return total;
  }

  @override
  void dispose() {
    // Liberar recursos de manera eficiente
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers = []; // Ayuda al recolector de basura
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductosCubit, ProductosState>(
      // Solo reconstruir el widget cuando cambian los productos o el estado de carga
      buildWhen: (previous, current) => 
          previous.productosSeleccionados != current.productosSeleccionados || 
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (_controllers.length != state.productosSeleccionados.length) {
          _initializeControllers(state.productosSeleccionados);
        }

        // Calcular el total y actualizar el estado del resumen
        double sumaTotal = _calcularSumaTotal(state.productosSeleccionados);

        // Sincronizar el total calculado con el Cubit de resumen en un microtask
        // para no bloquear la UI durante el cálculo
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
            // La tabla de productos
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
                // Optimizar generación de filas con memoización implícita
                rows: List<DataRow>.generate(
                  state.productosSeleccionados.length,
                  (index) {
                    final producto = state.productosSeleccionados[index];
                    // Solo actualizar el texto si ha cambiado para evitar reconstrucción innecesaria
                    final String cantidadActual = producto.cantidad.toString();
                    if (_controllers[index].text != cantidadActual) {
                      _controllers[index].text = cantidadActual;
                    }

                    return DataRow(
                      key: ValueKey('${producto.datum?.id ?? 'null'}_$index'),
                      cells: [
                        DataCell(Text(producto.datum?.barcode ?? 'Sin código')),
                        DataCell(Text(producto.datum?.nombre ?? 'Sin nombre')),
                        DataCell(Text('\$ ${producto.precioLista ?? ''}')),
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
                                  onChanged: (value) {
                                    final cantidad = int.tryParse(value) ?? 0;
                                    context.read<ProductosCubit>().precioTotal(index, cantidad);
                                  },
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
                              Flexible(
                                child: Text(producto.promo ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {
                                  // Lógica para cancelar la promoción
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${producto.iva} %')),
                        DataCell(Text('\$ ${(producto.precioFinal ?? 0).toStringAsFixed(2)}')),
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

            // Overlay de carga con spinner (collection if)
            if (state.isLoading)
              Positioned.fill(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.black.withOpacity(0.2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Actualizando lista de productos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
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
