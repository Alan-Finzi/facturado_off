import 'package:flutter/material.dart';

class ClientesMostradorPage extends StatefulWidget {
  @override
  _ClientesMostradorPageState createState() => _ClientesMostradorPageState();
}

class _ClientesMostradorPageState extends State<ClientesMostradorPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text fields
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _plazoCuentaCorrienteController =
  TextEditingController();
  final TextEditingController _montoMaximoCuentaCorrienteController =
  TextEditingController();
  final TextEditingController _saldoInicialCuentaCorrienteController =
  TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();
  final TextEditingController _deptoController = TextEditingController();
  final TextEditingController _pisoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _wcCustomerIdController = TextEditingController();

  int? _sucursalId;
  int? _listaPrecio;
  int? _comercioId;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Cliente')),
      floatingActionButton: SizedBox(
        height: 100,
        width: 100,
        child: FloatingActionButton(
          elevation: 5,
          mini: false,
          onPressed: (){
              if (_formKey.currentState!.validate()) {
                // Process data
              }
          },
          child: const Text(" Crear Cliente "),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _sucursalId,
                decoration: const InputDecoration(labelText: 'Sucursal'),
                items: const [
                  DropdownMenuItem<int>(value: 1, child: Text('Sucursal 1')),
                  DropdownMenuItem<int>(value: 2, child: Text('Sucursal 2')),
                  // Add more items as needed
                ],
                onChanged: (value) {
                  setState(() {
                    _sucursalId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione una sucursal';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _listaPrecio,
                decoration: const InputDecoration(labelText: 'Lista de Precio'),
                items: const [
                  DropdownMenuItem<int>(value: 1, child: Text('Lista 1')),
                  DropdownMenuItem<int>(value: 2, child: Text('Lista 2')),
                  // Add more items as needed
                ],
                onChanged: (value) {
                  setState(() {
                    _listaPrecio = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione una lista de precio';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _comercioId,
                decoration: InputDecoration(labelText: 'Comercio'),
                items: const [
                  DropdownMenuItem<int>(value: 1, child: Text('Comercio 1')),
                  DropdownMenuItem<int>(value: 2, child: Text('Comercio 2')),
                  // Add more items as needed
                ],
                onChanged: (value) {
                  setState(() {
                    _comercioId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un comercio';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _plazoCuentaCorrienteController,
                decoration: InputDecoration(labelText: 'Plazo Cuenta Corriente'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _montoMaximoCuentaCorrienteController,
                decoration:
                InputDecoration(labelText: 'Monto Máximo Cuenta Corriente'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _saldoInicialCuentaCorrienteController,
                decoration:
                InputDecoration(labelText: 'Saldo Inicial Cuenta Corriente'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _paisController,
                decoration: InputDecoration(labelText: 'País'),
              ),
              TextFormField(
                controller: _codigoPostalController,
                decoration: InputDecoration(labelText: 'Código Postal'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _deptoController,
                decoration: InputDecoration(labelText: 'Depto'),
              ),
              TextFormField(
                controller: _pisoController,
                decoration: InputDecoration(labelText: 'Piso'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _alturaController,
                decoration: InputDecoration(labelText: 'Altura'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _observacionesController,
                decoration: InputDecoration(labelText: 'Observaciones'),
              ),
              TextFormField(
                controller: _localidadController,
                decoration: InputDecoration(labelText: 'Localidad'),
              ),
              TextFormField(
                controller: _barrioController,
                decoration: InputDecoration(labelText: 'Barrio'),
              ),
              TextFormField(
                controller: _provinciaController,
                decoration: InputDecoration(labelText: 'Provincia'),
              ),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _dniController,
                decoration: InputDecoration(labelText: 'DNI'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _statusController,
                decoration: InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(labelText: 'Image'),
              ),
              TextFormField(
                controller: _wcCustomerIdController,
                decoration: InputDecoration(labelText: 'WC Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}