import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../helper/database_helper.dart';
import '../models/datos_facturacion_model.dart';

import '../bloc/cubit_productos/productos_cubit.dart';
import '../helper/database_helper.dart';
import '../models/datos_facturacion_model.dart';

class VentaDropdownsWidget extends StatelessWidget {
    final String comercioId;

    const VentaDropdownsWidget({super.key, required this.comercioId});

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<List<DatosFacturacionModel>>(
            future: DatabaseHelper.instance.getAllDatosFacturacionCommerce(int.parse(comercioId)),
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar datos'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No hay datos de facturación', style: TextStyle(color: Colors.black)),
                    );
                }

                final datosFacturacion = snapshot.data!;
                
                // Accedemos al cubit
                final productosCubit = context.watch<ProductosCubit>();
                final state = productosCubit.state;

                // Obtener datos del estado si están disponibles, sino usar el primero por defecto
                if (state.datosFacturacionModel != null && state.datosFacturacionModel!.isNotEmpty) {
                    // Actualizamos datosFacturacionCurrent desde el estado guardado
                    DatosFacturacionModel.datosFacturacionCurrent.clear();
                    DatosFacturacionModel.datosFacturacionCurrent.addAll(state.datosFacturacionModel!);
                } else if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
                    // Si no hay datos en el estado ni en la variable estática, usar el primero
                    DatosFacturacionModel.datosFacturacionCurrent.add(datosFacturacion.first);
                    // Y guardarlo también en el estado
                    productosCubit.updateDatosFacturacion([datosFacturacion.first]);
                }

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // ▼ Dropdown de Datos de Facturación
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                                'Seleccione un dato de facturación:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ),
                        DropButtonDatosFact(datosFacturacion: datosFacturacion),

                        const SizedBox(height: 16.0),

                        // ▼ Categoría IVA
                        const Text("Categoría IVA:"),
                        DropdownButton<String>(
                            value: state.categoriaIvaUser ?? 'Seleccionar',
                            onChanged: (String? newValue) {
                                if (newValue != null) {
                                    productosCubit.updateCategoriaIvaUser(newValue);
                                }
                            },
                            items: ['Monotributo', 'Responsable Inscripto', 'Consumidor Final']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                        ),

                        const SizedBox(height: 16.0),

                        // ▼ Tipo de Factura
                        const Text("Tipo de factura:"),
                        DropdownButton<String>(
                            value: state.tipoFactura ?? 'Factura C',
                            onChanged: (String? newValue) {
                                if (newValue != null) {
                                    productosCubit.updateTipoFactura(newValue);
                                }
                            },
                            items: ['Factura A', 'Factura B', 'Factura C']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                        ),

                        const SizedBox(height: 16.0),

                        // ▼ Caja seleccionada
                        const Text("Caja:"),
                        DropdownButton<String>(
                            value: state.cajaSeleccionada ?? 'Caja seleccionada: # 1',
                            onChanged: (String? newValue) {
                                if (newValue != null) {
                                    productosCubit.updateCajaSeleccionada(newValue);
                                }
                            },
                            items: [
                                'Caja seleccionada: # 1',
                                'Caja seleccionada: # 2',
                                'Caja seleccionada: # 3',
                            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                        ),

                        const SizedBox(height: 16.0),

                        // ▼ Estado del pedido (puede ser interactivo en el futuro)
                        const Text('Estado del pedido:'),
                        ElevatedButton(
                            onPressed: () {}, // Lógica futura
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Entregado'),
                        ),

                        const SizedBox(height: 16.0),

                        // ▼ Canal de venta
                        const Text("Canal de venta:"),
                        DropdownButton<String>(
                            value: state.canalVenta ?? 'Mostrador',
                            onChanged: (String? newValue) {
                                if (newValue != null) {
                                    productosCubit.updateCanalVenta(newValue);
                                }
                            },
                            items: ['Mostrador', 'Online', 'Teléfono']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                        ),

                        const SizedBox(height: 16.0),

                        // ▼ Descuento
                        const Text("Descuento:"),
                        Builder(builder: (context) {
                            // Convertir a entero y luego a string para que no muestre decimales
                            final controller = TextEditingController(text: state.descuentoGeneral.round().toString());
                            // Asegurar que el cursor siempre quede al final
                            controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length)
                            );
                            return TextField(
                                decoration: const InputDecoration(
                                    suffixText: '%',
                                    prefixIcon: Icon(Icons.discount),
                                ),
                                keyboardType: TextInputType.number,
                                controller: controller,
                                // Utilizar inputFormatters para garantizar que solo se ingresen números enteros
                                inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                    // Convertir a entero
                                    int? descuento = int.tryParse(value);
                                    if (descuento != null) {
                                        // Asegurarse de que el descuento no sea mayor a 100%
                                        if (descuento > 100) descuento = 100;
                                        productosCubit.updateDescuentoGeneral(descuento.toDouble());
                                    }
                                },
                            );
                        }),
                    ],
                );
            },
        );
    }
}

/// Widget reutilizable para desplegar los datos de facturación en dropdown
class DropButtonDatosFact extends StatelessWidget {
    final List<DatosFacturacionModel> datosFacturacion;

    const DropButtonDatosFact({super.key, required this.datosFacturacion});

    @override
    Widget build(BuildContext context) {
        return BlocBuilder<ProductosCubit, ProductosState>(
          builder: (context, state) {
            // Obtener el valor seleccionado, priorizando el estado del cubit
            DatosFacturacionModel? selected;
            
            if (state.datosFacturacionModel != null && state.datosFacturacionModel!.isNotEmpty) {
                // Usar el valor del estado
                selected = state.datosFacturacionModel!.first;
            } else if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
                // Si no hay en el estado, usar la variable estática
                selected = DatosFacturacionModel.datosFacturacionCurrent.first;
            }
            
            // Verificar que el valor seleccionado esté en la lista disponible
            if (selected != null && !datosFacturacion.contains(selected)) {
                // Si no está en la lista, intentar encontrar uno por ID
                try {
                  // Intentar encontrar por ID
                  if (selected!.id != null) {
                    final matchById = datosFacturacion.firstWhere(
                      (df) => df.id == selected?.id,
                      orElse: () => datosFacturacion.first,
                    );
                    selected = matchById;
                  } else {
                    // Si no tiene ID, usar el primero
                    selected = datosFacturacion.isNotEmpty ? datosFacturacion.first : null;
                  }
                } catch (e) {
                  // En caso de error, asignar el primer elemento si existe
                  selected = datosFacturacion.isNotEmpty ? datosFacturacion.first : null;
                }
            }

            return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DropdownButton<DatosFacturacionModel>(
                value: selected,
                onChanged: (DatosFacturacionModel? selectedFactura) {
                    if (selectedFactura != null) {
                        DatosFacturacionModel.datosFacturacionCurrent
                            ..clear()
                            ..add(selectedFactura);

                        context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);

                        print("Seleccionado: ${selectedFactura.razonSocial} - ${selectedFactura.condicionIva}");
                    }
                },
                items: datosFacturacion.map((factura) {
                    String condicionIvaText =
                        factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';
                    return DropdownMenuItem<DatosFacturacionModel>(
                        value: factura,
                        key: Key(factura.id.toString()),
                        child: Text(
                            '${factura.razonSocial?.isNotEmpty == true ? factura.razonSocial : 'Sin razón social'} - $condicionIvaText',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                        ),
                    );
                }).toList(),
                isExpanded: false,
                iconSize: 20,
                style: const TextStyle(fontSize: 14),
                ),
            );
          },
        );
    }
}
