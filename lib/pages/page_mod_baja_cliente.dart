import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../widget/build_text_field.dart';
//ModBajaCliente
class ModBajaCliente extends StatefulWidget {
  final ClientesMostrador cliente; // El cliente existente

  ModBajaCliente({required this.cliente});

  @override
  _ModBajaClienteState createState() => _ModBajaClienteState();
}

class _ModBajaClienteState extends State<ModBajaCliente> {
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
    _populateFields();
  }

  void _populateFields() {
    _codClienteController.text = widget.cliente.idCliente!;
    _nombreController.text = widget.cliente.nombre!;
    _telefonoController.text = widget.cliente.telefono!;
    _emailController.text = widget.cliente.email!;
    _cuitController.text = widget.cliente.dni!;
    _paisController.text = widget.cliente.pais!;
    _ciudadController.text = widget.cliente.localidad!;
    _barrioController.text = widget.cliente.barrio!;
    _calleController.text = widget.cliente.direccion!;
    _alturaController.text = widget.cliente.altura!;
    _pisoController.text = widget.cliente.piso!;
    _deptoController.text = widget.cliente.depto!;
    _codPostalController.text = widget.cliente.codigoPostal!;
    _selectedProvince = widget.cliente.provincia;
    _selectedPriceListId = widget.cliente.listaPrecio.toString();
    _sucursalController.text = widget.cliente.sucursalId.toString();
    _plazoCtaCteController.text = widget.cliente.plazoCuentaCorriente.toString();
    _montoMaximoCtaCteController.text = widget.cliente.montoMaximoCuentaCorriente.toString();
    _saldoInicialCtaCteController.text = widget.cliente.saldoInicialCuentaCorriente.toString();
    _fechaSaldoInicialCtaCteController.text = widget.cliente.fechaInicialCuentaCorriente!.toIso8601String().substring(0, 10);
    _observacionesController.text = widget.cliente.observaciones!;
  }

  void _fetchPriceList() async {
    List<ListaPreciosModel> priceList = await DatabaseHelper.instance.getListaPrecios();
    setState(() {
      _priceList = priceList;
      if (_priceList.isNotEmpty) {
        _selectedPriceListId ??= _priceList[0].wcKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientesCubit = context.watch<ClientesMostradorCubit>();
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EDITAR CLIENTE',
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
                        value: model.wcKey,
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
                    labelText: 'Saldo inicial en cuenta corriente',
                    hintText: '\$',
                    keyboardType: TextInputType.number,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _fechaSaldoInicialCtaCteController,
                    labelText: 'Fecha del saldo inicial',
                    hintText: 'YYYY-MM-DD',
                  )),
                ],
              ),
              SizedBox(height: 16),
              const Text(
                'Observaciones:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              CustomTextField(
                controller: _observacionesController,
                labelText: 'Observaciones',
                hintText: 'Observaciones',
                maxLines: 4,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final updatedCliente = ClientesMostrador(
                        idCliente: _codClienteController.text,
                        nombre: _nombreController.text,
                        telefono: _telefonoController.text,
                        email: _emailController.text,
                        dni: _cuitController.text,
                        pais: _paisController.text,
                        provincia: _selectedProvince ?? '',
                        localidad: _ciudadController.text,
                        barrio: _barrioController.text,
                        direccion: _calleController.text,
                        altura: _alturaController.text,
                        piso: _pisoController.text,
                        depto: _deptoController.text,
                        codigoPostal: _codPostalController.text,
                        listaPrecio: int.parse(_selectedPriceListId ?? '0'),
                        sucursalId: int.parse(_sucursalController.text),
                        plazoCuentaCorriente: int.parse(_plazoCtaCteController.text),
                        montoMaximoCuentaCorriente: double.parse(_montoMaximoCtaCteController.text),
                        saldoInicialCuentaCorriente: double.parse(_saldoInicialCtaCteController.text),
                        fechaInicialCuentaCorriente: DateTime.parse(_fechaSaldoInicialCtaCteController.text),
                        observaciones: _observacionesController.text,
                      );
                      clientesCubit.updateCliente(updatedCliente);
                      Navigator.pop(context);
                    },
                    child: Text('Guardar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      clientesCubit.deleteCliente(widget.cliente.idCliente!);
                      Navigator.pop(context);
                    },
                    child: Text('Dar de Baja'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }}