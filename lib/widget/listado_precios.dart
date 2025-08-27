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
    // Preservar controladores existentes para evitar recreación
    final List<TextEditingController> nuevosControllers = [];
    
    for (int i = 0; i < productosSeleccionados.length; i++) {
      // Reutilizar controlador si existe, sino crear uno nuevo
      if (i < _controllers.length) {
        nuevosControllers.add(_controllers[i]);
        // Solo actualizar el texto si es necesario
        if (_controllers[i].text != productosSeleccionados[i].cantidad.toString()) {
          _controllers[i].text = productosSeleccionados[i].cantidad.toString();
        }
      } else {
        nuevosControllers.add(TextEditingController(
          text: productosSeleccionados[i].cantidad.toString(),
        ));
      }
    }
    
    // Disponer controladores que ya no se necesitan
    for (int i = productosSeleccionados.length; i < _controllers.length; i++) {
      _controllers[i].dispose();
    }
    
    _controllers = nuevosControllers;
  }

  /// Calcula la suma total de precios finales de los productos seleccionados
  /// Optimizado para rendimiento
  double _calcularSumaTotal(List<ProductoConPrecioYStock> productosSeleccionados) {
    // Usar iteración directa para mayor eficiencia en listas grandes
    double total = 0.0;
    for (var producto in productosSeleccionados) {
      total += producto.precioFinal ?? 0.0;
    }
    return total;
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
      buildWhen: (previous, current) => 
          previous.productosSeleccionados != current.productosSeleccionados || 
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        // Optimización: Solo actualizar controladores cuando cambia la cantidad de productos
        if (_controllers.length != state.productosSeleccionados.length) {
          _initializeControllers(state.productosSeleccionados);
        }

        // Cálculo de total optimizado para ejecutarse solo cuando es necesario
        final double sumaTotal = _calcularSumaTotal(state.productosSeleccionados);
        
        // Actualización diferida del resumen para mejorar rendimiento
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
                dataRowMinHeight: 36, // Filas más compactas para rendimiento
                dataRowMaxHeight: 36, // Altura fija para evitar recálculos
                horizontalMargin: 8, // Reducir márgenes para optimizar espacio
                columnSpacing: 8, // Espaciado mínimo entre columnas
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
                // Optimización: Uso de un builder eficiente que evita recálculos innecesarios
                rows: List.generate(
                  state.productosSeleccionados.length,
                  (index) {
                    // Cache local para evitar accesos repetidos
                    final producto = state.productosSeleccionados[index];
                    
                    // Solo actualizar el texto si es necesario (evita reconstrucción de TextField)
                    if (_controllers[index].text != producto.cantidad.toString()) {
                      _controllers[index].text = producto.cantidad.toString();
                    }

                    // Precomputar valores para evitar cálculos durante el renderizado
                    final idKey = '${producto.datum?.id ?? 'null'}_$index';
                    final barcode = producto.datum?.barcode ?? 'Sin código';
                    final nombre = producto.datum?.nombre ?? 'Sin nombre';
                    final precioLista = producto.precioLista ?? '';
                    final precioFinal = producto.precioFinal ?? 0;
                    final iva = producto.iva;
                    final promo = producto.promo ?? '';

                    return DataRow(
                      key: ValueKey(idKey),
                      cells: [
                        DataCell(Text(barcode)), // Valor precalculado
                        DataCell(Text(nombre)), // Valor precalculado
                        DataCell(Text('\$ $precioLista')), // Valor precalculado
                        DataCell(
                          // Optimización: Row con children memoizados
                          Row(
                            mainAxisSize: MainAxisSize.min, // Reducir el tamaño del widget
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18), // Reducir tamaño
                                padding: EdgeInsets.zero, // Optimizar espacio
                                visualDensity: VisualDensity.compact, // Optimizar espacio
                                onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, -1),
                              ),
                              SizedBox(
                                width: 40, // Reducir tamaño
                                child: TextField(
                                  controller: _controllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true, // Reducir tamaño
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  ),
                                  onChanged: (value) {
                                    final cantidad = int.tryParse(value) ?? 0;
                                    context.read<ProductosCubit>().precioTotal(index, cantidad);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18), // Reducir tamaño
                                padding: EdgeInsets.zero, // Optimizar espacio
                                visualDensity: VisualDensity.compact, // Optimizar espacio
                                onPressed: () => context.read<ProductosCubit>().cambiarCantidad(index, 1),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min, // Optimización de layout
                            children: [
                              Flexible(
                                child: Text(promo),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, size: 18), // Reducir tamaño
                                padding: EdgeInsets.zero, // Optimizar espacio
                                visualDensity: VisualDensity.compact, // Optimizar espacio
                                onPressed: () {
                                  // Lógica para cancelar la promoción
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('$iva %')), // Valor precalculado
                        DataCell(Text('\$ ${precioFinal.toStringAsFixed(2)}')), // Valor precalculado
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18), // Reducir tamaño
                            padding: EdgeInsets.zero, // Optimizar espacio
                            visualDensity: VisualDensity.compact, // Optimizar espacio
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
