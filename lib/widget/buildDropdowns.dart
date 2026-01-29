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
    final List<DatosFacturacionModel>? datosFacturacionPrecargados;

    const VentaDropdownsWidget({
        super.key,
        required this.comercioId,
        this.datosFacturacionPrecargados,
    });

    // Método para crear datos de facturación de emergencia
    DatosFacturacionModel _crearDatoEmergencia() {
        return DatosFacturacionModel(
            id: -1, // ID negativo indica dato de emergencia
            razonSocial: "Datos de emergencia",
            comercioId: int.tryParse(comercioId) ?? 0,
            condicionIva: CondicionIva.ELEGIR,
            cuit: "",
            ptoVenta: "1",
            predeterminado: 1,
        );
    }

    // Método para mostrar diálogo de error con opciones
    void _mostrarDialogoError(BuildContext context, String mensaje) {
        if (!context.mounted) return;

        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                title: const Text('Error al cargar datos'),
                content: Text('$mensaje\n\n¿Qué desea hacer?'),
                actions: [
                    TextButton(
                        onPressed: () {
                            Navigator.pop(context);
                            // Forzar reconstrucción del widget
                            if (context.mounted) {
                                (context as Element).markNeedsBuild();
                            }
                        },
                        child: const Text('Reintentar'),
                    ),
                    TextButton(
                        onPressed: () {
                            Navigator.pop(context);
                            // Solicitar sincronización
                            if (context.mounted) {
                                context.read<LoginCubit>().requestSynchronization();
                            }
                        },
                        child: const Text('Ir a Sincronización'),
                    ),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        // Si tenemos datos precargados, los usamos directamente sin hacer una llamada a la base de datos
        if (datosFacturacionPrecargados != null && datosFacturacionPrecargados!.isNotEmpty) {
            return _buildDropdowns(context, datosFacturacionPrecargados!);
        }

        // De lo contrario, usamos FutureBuilder como antes
        return FutureBuilder<List<DatosFacturacionModel>>(
            future: DatabaseHelper.instance.getAllDatosFacturacionCommerce(int.tryParse(comercioId) ?? 0),
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                }

                // CASO 1: Error explícito - Mostrar datos de emergencia y diálogo
                if (snapshot.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mostrarDialogoError(context, 'Error al cargar datos: ${snapshot.error}');
                    });

                    // Crear y usar datos de emergencia para que la UI funcione
                    final datosEmergencia = [_crearDatoEmergencia()];
                    return _buildDropdowns(context, datosEmergencia);
                }

                // CASO 2: Sin datos - Mostrar datos de emergencia y diálogo
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mostrarDialogoError(context, 'No se encontraron datos de facturación');
                    });

                    // Crear y usar datos de emergencia para que la UI funcione
                    final datosEmergencia = [_crearDatoEmergencia()];
                    return _buildDropdowns(context, datosEmergencia);
                }

                final datosFacturacion = snapshot.data!;
                return _buildDropdowns(context, datosFacturacion);
            },
        );
    }

    // Método para construir los dropdowns con datos precargados
    Widget _buildDropdowns(BuildContext context, List<DatosFacturacionModel> datosFacturacion) {
        // VERIFICACIÓN DE SEGURIDAD ADICIONAL: Si la lista de datosFacturacion está vacía
        // a pesar de todas las protecciones anteriores, creamos un modelo de emergencia
        if (datosFacturacion.isEmpty) {
            // Crear datos de emergencia como último recurso
            final emergencyData = DatosFacturacionModel(
                id: -999, // ID muy negativo indica dato de super emergencia
                razonSocial: "⚠️ Datos de emergencia",
                comercioId: int.tryParse(comercioId) ?? 0,
                condicionIva: CondicionIva.ELEGIR,
                cuit: "",
                ptoVenta: "1",
                predeterminado: 1,
            );

            // Usar estos datos de emergencia
            datosFacturacion = [emergencyData];

            // Notificar al usuario con un SnackBar persistente
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('ADVERTENCIA: Usando datos de emergencia. Se recomienda sincronizar la aplicación.'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 10),
                            behavior: SnackBarBehavior.floating,
                        )
                    );
                }
            });

            // Intentar registrar el error (método silencioso que no debe fallar)
            try {
                print("ERROR CRÍTICO: datosFacturacion está vacío en _buildDropdowns a pesar de todas las protecciones.");
            } catch (_) {}
        }

        // Accedemos al cubit
        final productosCubit = context.watch<ProductosCubit>();
        final state = productosCubit.state;

        // Obtener datos del estado si están disponibles, sino usar el primero por defecto
        if (state.datosFacturacionModel != null && state.datosFacturacionModel!.isNotEmpty) {
            try {
                // Actualizamos datosFacturacionCurrent desde el estado guardado (con try-catch)
                DatosFacturacionModel.datosFacturacionCurrent.clear();
                DatosFacturacionModel.datosFacturacionCurrent.addAll(state.datosFacturacionModel!);
            } catch (e) {
                print("Error al actualizar datosFacturacionCurrent desde estado: $e");
            }
        } else if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
            // Si no hay datos en el estado ni en la variable estática,
            // verificar que la lista de datos de facturación no esté vacía
            if (datosFacturacion.isNotEmpty) {
                try {
                    DatosFacturacionModel.datosFacturacionCurrent.add(datosFacturacion.first);
                    // Y guardarlo también en el estado
                    productosCubit.updateDatosFacturacion([datosFacturacion.first]);
                } catch (e) {
                    print("Error al guardar primer dato de facturación: $e");
                }
            } else {
                // Este caso no debería ocurrir por la verificación inicial, pero por si acaso:
                // Si no hay datos de facturación, crear uno temporal
                try {
                    final tempDatosFact = DatosFacturacionModel(
                        id: -1, // ID temporal
                        razonSocial: "Sin datos de facturación",
                        comercioId: 0,
                        condicionIva: CondicionIva.ELEGIR
                    );

                    DatosFacturacionModel.datosFacturacionCurrent.add(tempDatosFact);
                    productosCubit.updateDatosFacturacion([tempDatosFact]);

                    // Mostrar un mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No se encontraron datos de facturación. Por favor sincronice la aplicación.'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 5),
                        )
                    );
                } catch (e) {
                    print("Error al crear dato de facturación temporal: $e");
                }
            }
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

                // ▼ Descuento con botón aplicar
                const Text("Descuento:"),
                Builder(builder: (context) {
                    // Convertir a entero y luego a string para que no muestre decimales
                    final controller = TextEditingController(text: state.descuentoGeneral.round().toString());
                    // Asegurar que el cursor siempre quede al final
                    controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length)
                    );

                    // Variable para almacenar temporalmente el valor del descuento
                    TextEditingController valueController = controller;

                    return Row(
                        children: [
                            // TextField para ingresar el porcentaje
                            Expanded(
                                child: TextField(
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
                                ),
                            ),

                            // Botón Aplicar
                            Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton(
                                    onPressed: () {
                                        // Convertir a entero
                                        int? descuento = int.tryParse(controller.text);
                                        if (descuento != null) {
                                            // Asegurarse de que el descuento no sea mayor a 100%
                                            if (descuento > 100) {
                                                descuento = 100;
                                                // Actualizar el controller para reflejar el valor máximo
                                                controller.text = '100';
                                            }
                                            // Actualizar el estado con el nuevo valor
                                            productosCubit.updateDescuentoGeneral(descuento.toDouble());
                                        }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Aplicar'),
                                ),
                            ),
                        ],
                    );
                }),
            ],
        );
    }
}

/// Widget reutilizable para desplegar los datos de facturación en dropdown
class DropButtonDatosFact extends StatelessWidget {
    final List<DatosFacturacionModel> datosFacturacion;

    const DropButtonDatosFact({super.key, required this.datosFacturacion});

    // Método para crear un dato de facturación seguro
    DatosFacturacionModel _crearDatoSeguro() {
        return DatosFacturacionModel(
            id: -2,  // ID negativo indica dato de emergencia
            razonSocial: "Dato de facturación por defecto",
            comercioId: 0,
            condicionIva: CondicionIva.ELEGIR,
            cuit: "",
            ptoVenta: "1"
        );
    }

    @override
    Widget build(BuildContext context) {
        // VERIFICACIÓN DE SEGURIDAD: Si la lista está vacía a pesar de todas las protecciones,
        // crear un dato de facturación por defecto
        List<DatosFacturacionModel> datosFacturacionSeguros = datosFacturacion;
        if (datosFacturacionSeguros.isEmpty) {
            datosFacturacionSeguros = [_crearDatoSeguro()];
        }

        return BlocBuilder<ProductosCubit, ProductosState>(
          builder: (context, state) {
            // Obtener el valor seleccionado, priorizando el estado del cubit
            DatosFacturacionModel? selected;

            try {
                if (state.datosFacturacionModel != null && state.datosFacturacionModel!.isNotEmpty) {
                    // Usar el valor del estado
                    selected = state.datosFacturacionModel!.first;
                } else if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
                    // Si no hay en el estado, usar la variable estática
                    selected = DatosFacturacionModel.datosFacturacionCurrent.first;
                }
            } catch (e) {
                print("Error al obtener dato seleccionado: $e");
            }

            // Si no se pudo obtener un valor seleccionado, usar el primero de la lista segura
            if (selected == null) {
                selected = datosFacturacionSeguros.first;

                // Intentar actualizar el estado y la variable estática
                try {
                    // Actualizar la variable estática
                    if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty) {
                        DatosFacturacionModel.datosFacturacionCurrent.add(selected);
                    }

                    // Actualizar el estado
                    context.read<ProductosCubit>().updateDatosFacturacion([selected]);
                } catch (e) {
                    print("Error al actualizar estado con valor por defecto: $e");
                }
            }

            // Verificar que el valor seleccionado esté en la lista disponible
            bool encontrado = false;
            try {
                encontrado = datosFacturacionSeguros.any((df) => df.id == selected?.id);
            } catch (e) {
                print("Error al verificar si el valor está en la lista: $e");
            }

            if (!encontrado) {
                try {
                    // Si no está en la lista, intentar encontrar uno por ID
                    if (selected?.id != null) {
                        try {
                            final matchById = datosFacturacionSeguros.firstWhere(
                                (df) => df.id == selected?.id,
                                orElse: () => datosFacturacionSeguros.first,
                            );
                            selected = matchById;
                        } catch (e) {
                            selected = datosFacturacionSeguros.first;
                        }
                    } else {
                        // Si no tiene ID, usar el primero
                        selected = datosFacturacionSeguros.first;
                    }
                } catch (e) {
                    // En caso de error, asignar el primer elemento
                    selected = datosFacturacionSeguros.first;
                }
            }

            return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DropdownButton<DatosFacturacionModel>(
                    value: selected,
                    onChanged: (DatosFacturacionModel? selectedFactura) {
                        if (selectedFactura != null) {
                            try {
                                DatosFacturacionModel.datosFacturacionCurrent.clear();
                                DatosFacturacionModel.datosFacturacionCurrent.add(selectedFactura);
                                context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);
                                print("Seleccionado: ${selectedFactura.razonSocial} - ${selectedFactura.condicionIva}");
                            } catch (e) {
                                print("Error al actualizar dato seleccionado: $e");
                            }
                        }
                    },
                    items: datosFacturacionSeguros.map((factura) {
                        String condicionIvaText = 'IVA: No disponible';
                        try {
                            condicionIvaText = factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';
                        } catch (e) {
                            print("Error al obtener condición IVA: $e");
                        }

                        String razonSocialText = 'Sin razón social';
                        try {
                            razonSocialText = factura.razonSocial?.isNotEmpty == true ? factura.razonSocial! : 'Sin razón social';
                        } catch (e) {
                            print("Error al obtener razón social: $e");
                        }

                        return DropdownMenuItem<DatosFacturacionModel>(
                            value: factura,
                            key: Key((factura.id ?? -1).toString()),
                            child: Text(
                                '$razonSocialText - $condicionIvaText',
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
