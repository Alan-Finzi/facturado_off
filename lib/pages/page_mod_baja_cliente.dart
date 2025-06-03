import 'package:flutter/material.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/productos_maestro.dart';
import '../widget/build_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // para firstWhereOrNull
import 'package:diacritic/diacritic.dart'; // para remover acentos

class ModBajaCliente extends StatefulWidget {
  final ClientesMostrador cliente;

  const ModBajaCliente({required this.cliente, super.key});

  @override
  State<ModBajaCliente> createState() => _ModBajaClienteState();
}

class _ModBajaClienteState extends State<ModBajaCliente> {
  String? _selectedProvince;
  String? _selectedPriceList;
  String? _selectedPriceListId;

  List<Lista> _priceList = [];
  final List<String> _provinces = [
    'Buenos Aires', 'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes',
    'Entre Ríos', 'Formosa', 'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza',
    'Misiones', 'Neuquén', 'Río Negro', 'Salta', 'San Juan', 'San Luis',
    'Santa Cruz', 'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego',
    'Tucumán'
  ];

  String? normalizarProvincia(String? entrada) {
    if (entrada == null) return null;

    final entradaNormalizada = removeDiacritics(entrada.toLowerCase().trim());

    return _provinces.firstWhereOrNull((prov) {
      final provNormalizada = removeDiacritics(prov.toLowerCase());
      return provNormalizada == entradaNormalizada;
    });
  }

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
    _populateFields();
    _fetchPriceList();
  }

  void _populateFields() {
    _codClienteController.text = widget.cliente.idCliente ?? '';
    _nombreController.text = widget.cliente.nombre ?? '';
    _telefonoController.text = widget.cliente.telefono ?? '';
    _emailController.text = widget.cliente.email ?? '';
    _cuitController.text = widget.cliente.dni ?? '';
    _paisController.text = widget.cliente.pais ?? '';
    _ciudadController.text = widget.cliente.localidad ?? '';
    _barrioController.text = widget.cliente.barrio ?? '';
    _calleController.text = widget.cliente.direccion ?? '';
    _alturaController.text = widget.cliente.altura ?? '';
    _pisoController.text = widget.cliente.piso ?? '';
    _deptoController.text = widget.cliente.depto ?? '';
    _codPostalController.text = widget.cliente.codigoPostal ?? '';
    _selectedProvince = normalizarProvincia(
        (widget.cliente.provincia?.isNotEmpty ?? false)
            ? widget.cliente.provincia
            : 'Córdoba'
    );

    _selectedPriceListId = widget.cliente.listaPrecio?.toString();
    _sucursalController.text = widget.cliente.sucursalId?.toString() ?? '';
    _plazoCtaCteController.text = widget.cliente.plazoCuentaCorriente?.toString() ?? '';
    _montoMaximoCtaCteController.text = widget.cliente.montoMaximoCuentaCorriente?.toString() ?? '';
    _saldoInicialCtaCteController.text = widget.cliente.saldoInicialCuentaCorriente?.toString() ?? '';
    _fechaSaldoInicialCtaCteController.text = widget.cliente.fechaInicialCuentaCorriente != null
        ? widget.cliente.fechaInicialCuentaCorriente!.toIso8601String().substring(0, 10)
        : '';
    _observacionesController.text = widget.cliente.observaciones ?? '';
  }

  Future<void> _fetchPriceList() async {
    List<Lista> priceList = await DatabaseHelper.instance.getListaPrecios();

    String? selectedName;
    if (widget.cliente.listaPrecio != null) {
      selectedName = priceList.firstWhere(
            (p) => p.id == widget.cliente.listaPrecio.toString(),
        orElse: () => Lista(id: 1, nombre: 'Sin lista'),
      ).nombre;
    }

    setState(() {
      _priceList = priceList;
      _selectedPriceList = selectedName ?? (priceList.isNotEmpty ? priceList.first.nombre : 'Sin lista');
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientesCubit = context.watch<ClientesMostradorCubit>();

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'EDITAR CLIENTE',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _codClienteController,
              labelText: 'Cod del cliente',
              hintText: 'Ej: 12345678901',
              maxLength: 11,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _nombreController,
                    labelText: 'Nombre del cliente',
                    hintText: 'Ej: Juan Perez',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _telefonoController,
                    labelText: 'Telefono',
                    hintText: 'Ej: 351 115 9550',
                  ),
                ),
              ],
            ),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Ej: juanperez@gmail.com',
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cuitController,
                    labelText: 'CUIT',
                    hintText: 'Ej: 12345678901',
                    maxLength: 11,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _paisController,
                    labelText: 'Pais',
                    hintText: 'Ej: Argentina',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    onChanged: (value) {
                      setState(() => _selectedProvince = value);
                    },
                    items: _provinces.map((String province) {
                      return DropdownMenuItem<String>(
                        value: province,
                        child: Text(province),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Provincia'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _ciudadController,
                    labelText: 'Ciudad',
                    hintText: 'Ej: Córdoba',
                  ),
                ),
              ],
            ),
            CustomTextField(
              controller: _barrioController,
              labelText: 'Barrio',
              hintText: 'Ej: Nueva Córdoba',
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _calleController,
                    labelText: 'Calle',
                    hintText: 'Ej: Independencia',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _alturaController,
                    labelText: 'Altura',
                    hintText: 'Ej: 105',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _pisoController,
                    labelText: 'Piso',
                    hintText: 'Ej: 6',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _deptoController,
                    labelText: 'Depto',
                    hintText: 'Ej: A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriceList,
              items: _priceList.map((item) {
                return DropdownMenuItem<String>(
                  value: item.nombre ?? 'Sin info',
                  child: Text(item.nombre ?? 'Sin info'),
                );
              }).toList()
                ..insert(0, const DropdownMenuItem<String>(
                  value: 'Sin lista',
                  child: Text('Sin lista'),
                )),
              onChanged: (value) {
                setState(() {
                  _selectedPriceList = value;
                  final selected = _priceList.firstWhere(
                        (e) => e.nombre == value,
                    orElse: () => Lista( id: 1),
                  );
                  _selectedPriceListId = selected.id.toString();
                });
              },
              decoration: const InputDecoration(labelText: 'Lista de precios'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // guardar lógica aquí
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
