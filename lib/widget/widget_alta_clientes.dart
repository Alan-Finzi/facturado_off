import 'package:facturador_offline/models/clientes_mostrador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../helper/database_helper.dart';
import '../models/lista_precio_model.dart';
import 'build_text_field.dart';
class AltaClienteDialog extends StatefulWidget {
  @override
  _AltaClienteDialogState createState() => _AltaClienteDialogState();
}

class _AltaClienteDialogState extends State<AltaClienteDialog> {
  String? _selectedProvince;
  String? _selectedPriceList;
  String? _selectedPriceListId;

  List<ListaPreciosModel> _priceList = [];
  List<String> _provinces = [
    'Buenos Aires', 'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes',
    'Entre Ríos', 'Formosa', 'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza',
    'Misiones', 'Neuquén', 'Río Negro', 'Salta', 'San Juan', 'San Luis',
    'Santa Cruz', 'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego',
    'Tucumán'
  ];

  final _codClienteController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _cuitController = TextEditingController();
  final _paisController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _barrioController = TextEditingController();
  final _calleController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pisoController = TextEditingController();
  final _deptoController = TextEditingController();
  final _codPostalController = TextEditingController();
  final _sucursalController = TextEditingController();
  final _plazoCtaCteController = TextEditingController();
  final _montoMaximoCtaCteController = TextEditingController();
  final _saldoInicialCtaCteController = TextEditingController();
  final _fechaSaldoInicialCtaCteController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPriceList();
  }

  void _fetchPriceList() async {
    // Asume que DatabaseHelper está configurado y tiene un método para obtener la lista de precios
    List<ListaPreciosModel> priceList = await DatabaseHelper.instance.getListaPrecios();
    setState(() {
      _priceList = priceList;
      // Asegúrate de inicializar `_selectedPriceListId` con un valor válido si hay datos
      if (_priceList.isNotEmpty) {
        _selectedPriceListId = _priceList[0].wcKey; // O cualquier valor que quieras usar como predeterminado
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientesCubit = context.watch<ClientesMostradorCubit>();
    final userCubit = context.watch<LoginCubit>();
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AGREGAR CLIENTE',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _codClienteController,
                labelText: 'Cod del cliente',
                hintText: 'Ej: 12345678901',
                maxLength: 11,
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _nombreController,
                    labelText: 'Nombre del cliente',
                    hintText: 'Ej: Juan Perez',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _telefonoController,
                    labelText: 'Telefono',
                    hintText: 'Ej: 351 115 9550',
                  )),
                ],
              ),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Ej: juanperez@gmail.com',
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _cuitController,
                    labelText: 'CUIT',
                    hintText: 'Ej: 12345678901',
                    maxLength: 11,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _paisController,
                    labelText: 'Pais',
                    hintText: 'Ej: Argentina',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    onChanged: (newValue) => setState(() {
                      _selectedProvince = newValue;
                    }),
                    items: _provinces.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Provincia'),
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _ciudadController,
                    labelText: 'Ciudad',
                    hintText: 'Ej: Córdoba',
                  )),
                ],
              ),
              CustomTextField(
                controller: _barrioController,
                labelText: 'Barrio',
                hintText: 'Ej: Nueva Cordoba',
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _calleController,
                    labelText: 'Calle',
                    hintText: 'Ej: Independencia',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _alturaController,
                    labelText: 'Altura',
                    hintText: 'Ej: 105',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _pisoController,
                    labelText: 'Piso',
                    hintText: 'Ej: 6',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _deptoController,
                    labelText: 'Depto',
                    hintText: 'Ej: A',
                  )),
                ],
              ),
              CustomTextField(
                controller: _codPostalController,
                labelText: 'Cod Postal',
                hintText: 'Ej: 5000',
              ),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _selectedPriceListId,
                    onChanged: (newValue) => setState(() {
                      _selectedPriceListId = newValue;
                    }),
                    items: _priceList.map<DropdownMenuItem<String>>((ListaPreciosModel model) {
                      return DropdownMenuItem<String>(
                        value: model.wcKey, // Suponiendo que el modelo tiene un campo `id`
                        child: Text(model.nombre!),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Lista de precios del cliente'),
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _sucursalController,
                    labelText: 'Sucursal',
                    hintText: 'DEMO',
                  )),
                ],
              ),
              SizedBox(height: 16),
              const Text(
                'Cuenta corriente:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _plazoCtaCteController,
                    labelText: 'Plazo cuenta corriente',
                    hintText: 'DIAS',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _montoMaximoCtaCteController,
                    labelText: 'Monto maximo en cta cte',
                    hintText: '\$',
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
               Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _saldoInicialCtaCteController,
                    labelText: 'Saldo inicial en cta cte',
                    hintText: '\$',
                    keyboardType: TextInputType.number,
                  )),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fechaSaldoInicialCtaCteController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de saldo inicial',
                        hintText: '15/08/2024',
                      ),
                      readOnly: true, // Hace que el campo sea de solo lectura para abrir el DatePicker
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _fechaSaldoInicialCtaCteController.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              CustomTextField(
                controller: _observacionesController,
                labelText: 'Observaciones',
                hintText: '',
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final nuevoCliente = ClientesMostrador(
                          creadorId: userCubit.state.user!.id?? 1,
                          comercioId: userCubit.state.user!.sucursal,
                          idCliente: _codClienteController.text ,
                          wcCustomerId: _codClienteController.text,
                          nombre: _nombreController.text,
                          telefono: _telefonoController.text ?? '',
                          email: _emailController.text ?? '',
                          dni: _cuitController.text ?? '',
                          pais: _paisController.text ?? '',
                          provincia:_selectedProvince ?? 'Córdoba',
                          localidad: _ciudadController.text?? '',
                          barrio: _barrioController.text?? '',
                          direccion: _calleController.text?? '',
                          altura: _alturaController.text?? '',
                          piso: _pisoController.text?? '',
                          depto: _deptoController.text?? '',
                          codigoPostal: _codPostalController.text?? '',
                          listaPrecio: int.parse(_selectedPriceListId!),
                          sucursalId:userCubit.state.user!.sucursal?? 1,
                          plazoCuentaCorriente:_plazoCtaCteController.text.isNotEmpty ? int.tryParse(_plazoCtaCteController.text): 0,
                          montoMaximoCuentaCorriente: _montoMaximoCtaCteController.text.isNotEmpty? double.parse(_montoMaximoCtaCteController.text) : 0,
                          saldoInicialCuentaCorriente: _saldoInicialCtaCteController.text.isNotEmpty ? double.parse(_saldoInicialCtaCteController.text) : 0,
                          fechaInicialCuentaCorriente:_fechaSaldoInicialCtaCteController.text.isNotEmpty? DateTime.parse(_fechaSaldoInicialCtaCteController.text): DateTime.parse('1989-01-20'),
                          observaciones: _observacionesController.text,
                        );

                        final dbHelper = DatabaseHelper.instance;
                        await dbHelper.insertCliente(nuevoCliente);
                        // Inicializa la lista de clientes cuando se construye el widget
                        clientesCubit.getClientesBD();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CLIENTE AGREGADO CON EXITO')),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        // Manejo de errores de conversión y otros errores
                        print('Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ERROR AL GUARDAR CLIENTE')),
                        );
                      }
                    },
                    child: Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
