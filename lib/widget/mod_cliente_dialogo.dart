import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/productos_maestro.dart';
import '../services/user_repository.dart';
import 'build_text_field.dart';


class Mod_baja_cliente extends StatefulWidget {
  @override
  _Mod_baja_clienteState createState() => _Mod_baja_clienteState();
}

class _Mod_baja_clienteState extends State<Mod_baja_cliente> {
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
  final UserRepository userRepository = UserRepository();
  String? _selectedProvince;
  String? _selectedPriceListId;
  List<Lista> _priceList = [];
  List<String> _provinces = [
    'Buenos Aires', 'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes',
    'Entre Ríos', 'Formosa', 'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza',
    'Misiones', 'Neuquén', 'Río Negro', 'Salta', 'San Juan', 'San Luis',
    'Santa Cruz', 'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego',
    'Tucumán'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPriceList();
  }

  void _fetchPriceList() async {
    List<Lista> priceList = await DatabaseHelper.instance.getListaPrecios();
    setState(() {
      _priceList = priceList;
      if (_priceList.isNotEmpty) {
        _selectedPriceListId = _priceList[0].id.toString();
      }
    });
  }

  void _searchCliente(String query) async {
    final clientesCubit = context.read<ClientesMostradorCubit>();
    await clientesCubit.buscarCliente(query);

    final cliente = clientesCubit.state.clientes.firstWhere(
          (cliente) => cliente.idCliente == query || cliente.dni == query,
      //orElse: () => //null,
    );

    if (cliente != null) {
      _populateFields(cliente);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente no encontrado')),
      );
    }
  }

  void _fetchClientData(String query) async {
    try {

      // Obtener la lista de clientes del repositorio
      final List<ClientesMostrador> clientes = await userRepository.fetchClientes();

      // Buscar el cliente que coincida con el idCliente o el dni
      final cliente = clientes.firstWhere(
            (cliente) => cliente.idCliente == query || cliente.dni == query,
       // orElse: () => null, // Devuelve null si no se encuentra el cliente
      );

      if (cliente != null) {
        _populateFields(cliente);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente no encontrado')),
        );
      }
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar cliente: $e')),
      );
    }
  }

  void _populateFields(ClientesMostrador cliente) {
    setState(() {
      _codClienteController.text = cliente.idCliente ?? '';
      _nombreController.text = cliente.nombre ?? '';
      _telefonoController.text = cliente.telefono ?? '';
      _emailController.text = cliente.email ?? '';
      _cuitController.text = cliente.dni ?? '';
      _paisController.text = cliente.pais ?? '';
      _ciudadController.text = cliente.localidad ?? '';
      _barrioController.text = cliente.barrio ?? '';
      _calleController.text = cliente.direccion ?? '';
      _alturaController.text = cliente.altura ?? '';
      _pisoController.text = cliente.piso ?? '';
      _deptoController.text = cliente.depto ?? '';
      _codPostalController.text = cliente.codigoPostal ?? '';
      _sucursalController.text = cliente.sucursalId?.toString() ?? '';
      _plazoCtaCteController.text = cliente.plazoCuentaCorriente?.toString() ?? '';
      _montoMaximoCtaCteController.text = cliente.montoMaximoCuentaCorriente?.toString() ?? '';
      _saldoInicialCtaCteController.text = cliente.saldoInicialCuentaCorriente?.toString() ?? '';
      _fechaSaldoInicialCtaCteController.text = cliente.fechaInicialCuentaCorriente?.toString().split(' ')[0] ?? '';
      _observacionesController.text = cliente.observaciones ?? '';
      _selectedProvince = cliente.provincia;
      _selectedPriceListId = cliente.listaPrecio?.toString();
    });
  }

  void _updateCliente() async {
    try {
      final updatedCliente = ClientesMostrador(
        idCliente: _codClienteController.text,
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        dni: _cuitController.text,
        pais: _paisController.text,
        provincia: _selectedProvince!,
        localidad: _ciudadController.text,
        barrio: _barrioController.text,
        direccion: _calleController.text,
        altura: _alturaController.text,
        piso: _pisoController.text,
        depto: _deptoController.text,
        codigoPostal: _codPostalController.text,
        listaPrecio: int.parse(_selectedPriceListId!),
        sucursalId: int.parse(_sucursalController.text),
        plazoCuentaCorriente: int.parse(_plazoCtaCteController.text),
        montoMaximoCuentaCorriente: double.parse(_montoMaximoCtaCteController.text),
        saldoInicialCuentaCorriente: double.parse(_saldoInicialCtaCteController.text),
        fechaInicialCuentaCorriente: DateTime.parse(_fechaSaldoInicialCtaCteController.text),
        observaciones: _observacionesController.text,
      );

      //await DatabaseHelper.instance.updateCliente(updatedCliente);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente actualizado con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar cliente')),
      );
    }
  }

  void _deleteCliente() async {
    try {
      final codCliente = _codClienteController.text;
      //await DatabaseHelper.instance.deleteCliente(int.parse(codCliente));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente eliminado con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar cliente')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MODIFICAR CLIENTE',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _codClienteController,
                      labelText: 'Cod del cliente o CUIT',
                      hintText: 'Ej: 12345678901',
                      maxLength: 11,
                      // onSubmitted: _fetchClientData, // Fetch client data on enter
                    ),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _fetchClientData(_codClienteController.text),
                  ),
                ],
              ),
              CustomTextField(
                controller: _nombreController,
                labelText: 'Nombre del cliente',
                hintText: 'Ej: Juan Perez',
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _telefonoController,
                    labelText: 'Telefono',
                    hintText: 'Ej: 351 115 9550',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Ej: juanperez@gmail.com',
                  )),
                ],
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
                    decoration: InputDecoration(
                      labelText: 'Provincia',
                      hintText: 'Seleccione una provincia',
                    ),
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _ciudadController,
                    labelText: 'Ciudad',
                    hintText: 'Ej: Córdoba',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _barrioController,
                    labelText: 'Barrio',
                    hintText: 'Ej: Centro',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _calleController,
                    labelText: 'Calle',
                    hintText: 'Ej: Av. Colón',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _alturaController,
                    labelText: 'Altura',
                    hintText: 'Ej: 1234',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _pisoController,
                    labelText: 'Piso',
                    hintText: 'Ej: 5',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _deptoController,
                    labelText: 'Depto',
                    hintText: 'Ej: A',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _codPostalController,
                    labelText: 'Cod Postal',
                    hintText: 'Ej: 5000',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _selectedPriceListId,
                    onChanged: (newValue) => setState(() {
                      _selectedPriceListId = newValue;
                    }),
                    items: _priceList.map<DropdownMenuItem<String>>((Lista value) {
                      return DropdownMenuItem<String>(
                        value: value.id.toString(),
                        child: Text(value.nombre!),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Lista de precios',
                      hintText: 'Seleccione una lista de precios',
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _sucursalController,
                    labelText: 'Sucursal',
                    hintText: 'Ej: 1',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _plazoCtaCteController,
                    labelText: 'Plazo cuenta corriente',
                    hintText: 'Ej: 30',
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(
                    controller: _montoMaximoCtaCteController,
                    labelText: 'Monto máximo cuenta corriente',
                    hintText: 'Ej: 10000.00',
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _saldoInicialCtaCteController,
                    labelText: 'Saldo inicial cuenta corriente',
                    hintText: 'Ej: 0.00',
                    keyboardType: TextInputType.number,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: CustomTextField(
                    controller: _fechaSaldoInicialCtaCteController,
                    labelText: 'Fecha saldo inicial',
                    hintText: 'YYYY-MM-DD',
                    keyboardType: TextInputType.datetime,
                  )),
                ],
              ),
              CustomTextField(
                controller: _observacionesController,
                labelText: 'Observaciones',
                hintText: 'Ej: Cliente preferencial',
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed:(){},// _modificarCliente,
                    child: Text('Modificar Cliente'),
                  ),
                  ElevatedButton(
                    onPressed:(){},//
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Eliminar Cliente'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
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