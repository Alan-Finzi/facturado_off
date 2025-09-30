import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../models/clientes_mostrador.dart';
import '../widget/buscar_cliente.dart';

class FormaCobroPage extends StatefulWidget {
  final VoidCallback onBackPressed; // Callback para manejar el botón "Anterior"

  FormaCobroPage({required this.onBackPressed});

  @override
  _FormaCobroPageState createState() => _FormaCobroPageState();
}

class _FormaCobroPageState extends State<FormaCobroPage> {
  bool isPagoParcial = false;

  // Tipo de envío seleccionado (0: retiro por sucursal, 1: envío a domicilio, 2: otro domicilio)
  int _selectedTipoEnvio = 0;

  // Controladores para el formulario de nuevo domicilio
  final _calleController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pisoController = TextEditingController();
  final _deptoController = TextEditingController();
  final _localidadController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _cpController = TextEditingController();
  final _barrioController = TextEditingController();

  // Datos de envío para guardar
  Map<String, dynamic> _datosEnvio = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forma de Cobro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Sección Cliente - Usando el widget de búsqueda unificado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: BuscarClienteWidget(
                    clearProductsOnSelection: false, // No limpiar productos al seleccionar
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendedor'),
                      ElevatedButton.icon(
                        icon: Icon(Icons.person),
                        label: Text('DEMO'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Sección Forma de Cobro
            Text(
              'Forma de cobro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isPagoParcial = false;
                      });
                    },
                    child: Text('Pago total'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isPagoParcial ? Colors.grey : null,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isPagoParcial = true;
                      });
                    },
                    child: Text('Pago parcial / pago dividido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPagoParcial ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            if (isPagoParcial)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agregar Método de Pago
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '+ Agregar Método de Pago',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  const Row(
                    children: [
                      // Monto Total
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Monto Total',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16.0),
                      // A Cobrar Total
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'A cobrar total',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text('Deuda: \$ 0,00'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monto a Pagar
                  TextField(
                    decoration: InputDecoration(
                      labelText:
                      'Ingresa el monto con el que va a pagar tu cliente',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Vuelto a entregar',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ],
              ),
            SizedBox(height: 16.0),

            // Sección Tipo de Envío
            Text(
              'Tipo de envío',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            RadioListTile(
              value: 0,
              groupValue: _selectedTipoEnvio,
              onChanged: (int? value) {
                setState(() {
                  _selectedTipoEnvio = value ?? 0;
                  _datosEnvio = {'tipo_envio': 'retiro_sucursal'};
                });
              },
              title: Text('Retiro por sucursal'),
            ),
            RadioListTile(
              value: 1,
              groupValue: _selectedTipoEnvio,
              onChanged: (int? value) {
                setState(() {
                  _selectedTipoEnvio = value ?? 1;
                });
                _validarDomicilioCliente();
              },
              title: Text('Envío a domicilio del cliente'),
            ),
            RadioListTile(
              value: 2,
              groupValue: _selectedTipoEnvio,
              onChanged: (int? value) {
                setState(() {
                  _selectedTipoEnvio = value ?? 2;
                });
                _mostrarFormularioDomicilio();
              },
              title: Text('Envío a otro domicilio'),
            ),

            // Mostrar información según tipo de envío seleccionado
            if (_selectedTipoEnvio == 1) _buildDomicilioClienteInfo(),
            if (_selectedTipoEnvio == 2) _buildOtroDomicilioInfo(),
            SizedBox(height: 20),

            // Botones Anterior y Guardar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onBackPressed, // Usamos el callback aquí
                  child: Text('Anterior'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _guardarVentaConEnvio();
                  },
                  child: Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      )),
    );
  }

  // Widget para mostrar información del domicilio del cliente
  Widget _buildDomicilioClienteInfo() {
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;

    if (cliente == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          'Por favor seleccione un cliente primero',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // Verificar si el cliente tiene domicilio completo
    final tieneDireccionCompleta = _verificarDireccionCompleta(cliente);

    if (!tieneDireccionCompleta) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El cliente no tiene una dirección completa',
              style: TextStyle(color: Colors.orange),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () => _mostrarFormularioCompletarDomicilio(cliente),
              child: Text('Completar dirección'),
            ),
          ],
        ),
      );
    } else {
      // Cliente tiene dirección completa, mostrarla y asignar a datos de envío
      _datosEnvio = {
        'tipo_envio': 'domicilio_cliente',
        'cliente_id': cliente.idCliente,
        'calle': cliente.direccion,
        'altura': cliente.altura,
        'piso': cliente.piso,
        'depto': cliente.depto,
        'localidad': cliente.localidad,
        'provincia': cliente.provincia,
        'codigo_postal': cliente.codigoPostal,
        'barrio': cliente.barrio,
      };

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dirección de envío:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8.0),
              Text('${cliente.direccion ?? ""} ${cliente.altura ?? ""}'),
              if (cliente.piso != null || cliente.depto != null)
                Text('Piso: ${cliente.piso ?? ""} Depto: ${cliente.depto ?? ""}'),
              Text('${cliente.localidad ?? ""}, ${cliente.provincia ?? ""}'),
              if (cliente.codigoPostal != null)
                Text('CP: ${cliente.codigoPostal}'),
            ],
          ),
        ),
      );
    }
  }

  // Widget para mostrar información de otro domicilio
  Widget _buildOtroDomicilioInfo() {
    if (_datosEnvio.isEmpty || _datosEnvio['tipo_envio'] != 'otro_domicilio') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ElevatedButton(
          onPressed: () => _mostrarFormularioDomicilio(),
          child: Text('Ingresar domicilio de envío'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      );
    } else {
      // Mostrar domicilio ingresado
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Domicilio ingresado:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8.0),
              Text('${_datosEnvio['calle'] ?? ""} ${_datosEnvio['altura'] ?? ""}'),
              if (_datosEnvio['piso'] != null || _datosEnvio['depto'] != null)
                Text('Piso: ${_datosEnvio['piso'] ?? ""} Depto: ${_datosEnvio['depto'] ?? ""}'),
              Text('${_datosEnvio['localidad'] ?? ""}, ${_datosEnvio['provincia'] ?? ""}'),
              if (_datosEnvio['codigo_postal'] != null)
                Text('CP: ${_datosEnvio['codigo_postal']}'),
              SizedBox(height: 8.0),
              TextButton(
                onPressed: () => _mostrarFormularioDomicilio(),
                child: Text('Editar domicilio'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Verifica si el cliente tiene una dirección completa
  bool _verificarDireccionCompleta(ClientesMostrador cliente) {
    return cliente.direccion != null &&
           cliente.direccion!.isNotEmpty &&
           cliente.localidad != null &&
           cliente.localidad!.isNotEmpty &&
           cliente.provincia != null &&
           cliente.provincia!.isNotEmpty;
  }

  // Valida si el cliente seleccionado tiene domicilio
  void _validarDomicilioCliente() {
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final cliente = clienteCubit.state.clienteSeleccionado;

    if (cliente == null) {
      // No hay cliente seleccionado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor seleccione un cliente primero'))
      );
      return;
    }

    // Si el cliente no tiene dirección completa, mostrar formulario para completarla
    if (!_verificarDireccionCompleta(cliente)) {
      _mostrarFormularioCompletarDomicilio(cliente);
    } else {
      // Cliente tiene dirección completa
      _datosEnvio = {
        'tipo_envio': 'domicilio_cliente',
        'cliente_id': cliente.idCliente,
        'calle': cliente.direccion,
        'altura': cliente.altura,
        'piso': cliente.piso,
        'depto': cliente.depto,
        'localidad': cliente.localidad,
        'provincia': cliente.provincia,
        'codigo_postal': cliente.codigoPostal,
        'barrio': cliente.barrio,
      };

      setState(() {});
    }
  }

  // Muestra el formulario para completar domicilio del cliente
  void _mostrarFormularioCompletarDomicilio(ClientesMostrador cliente) {
    // Prellenar los controladores con la información existente
    _calleController.text = cliente.direccion ?? '';
    _alturaController.text = cliente.altura ?? '';
    _pisoController.text = cliente.piso ?? '';
    _deptoController.text = cliente.depto ?? '';
    _localidadController.text = cliente.localidad ?? '';
    _provinciaController.text = cliente.provincia ?? '';
    _cpController.text = cliente.codigoPostal ?? '';
    _barrioController.text = cliente.barrio ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Completar dirección del cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _calleController,
                decoration: InputDecoration(
                  labelText: 'Calle *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _alturaController,
                decoration: InputDecoration(
                  labelText: 'Altura *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pisoController,
                      decoration: InputDecoration(
                        labelText: 'Piso',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _deptoController,
                      decoration: InputDecoration(
                        labelText: 'Depto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _localidadController,
                decoration: InputDecoration(
                  labelText: 'Localidad *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _provinciaController,
                decoration: InputDecoration(
                  labelText: 'Provincia *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _cpController,
                decoration: InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _barrioController,
                decoration: InputDecoration(
                  labelText: 'Barrio',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validar campos obligatorios
              if (_calleController.text.isEmpty ||
                  _localidadController.text.isEmpty ||
                  _provinciaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor complete los campos obligatorios')),
                );
                return;
              }

              // Actualizar cliente con la nueva dirección
              final clienteCubit = context.read<ClientesMostradorCubit>();
              final clienteActualizado = ClientesMostrador(
                idCliente: cliente.idCliente,
                nombre: cliente.nombre,
                direccion: _calleController.text,
                altura: _alturaController.text,
                piso: _pisoController.text.isNotEmpty ? _pisoController.text : null,
                depto: _deptoController.text.isNotEmpty ? _deptoController.text : null,
                localidad: _localidadController.text,
                provincia: _provinciaController.text,
                codigoPostal: _cpController.text.isNotEmpty ? _cpController.text : null,
                barrio: _barrioController.text.isNotEmpty ? _barrioController.text : null,
                // Mantener otros datos del cliente
                creadorId: cliente.creadorId,
                sucursalId: cliente.sucursalId,
                listaPrecio: cliente.listaPrecio,
                comercioId: cliente.comercioId,
                email: cliente.email,
                telefono: cliente.telefono,
                dni: cliente.dni,
                activo: cliente.activo,
                modificado: 1, // Marcar como modificado para sincronización
              );

              // Actualizar el cliente en la base de datos
              clienteCubit.updateCliente(clienteActualizado).then((_) {
                // Guardar datos para envío
                _datosEnvio = {
                  'tipo_envio': 'domicilio_cliente',
                  'cliente_id': cliente.idCliente,
                  'calle': _calleController.text,
                  'altura': _alturaController.text,
                  'piso': _pisoController.text.isNotEmpty ? _pisoController.text : null,
                  'depto': _deptoController.text.isNotEmpty ? _deptoController.text : null,
                  'localidad': _localidadController.text,
                  'provincia': _provinciaController.text,
                  'codigo_postal': _cpController.text.isNotEmpty ? _cpController.text : null,
                  'barrio': _barrioController.text.isNotEmpty ? _barrioController.text : null,
                };

                // Actualizar UI
                setState(() {});

                // Cerrar diálogo
                Navigator.pop(context);

                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dirección actualizada correctamente')),
                );
              });
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Muestra el formulario para ingresar un nuevo domicilio
  void _mostrarFormularioDomicilio() {
    // Limpiar los controladores
    _calleController.text = '';
    _alturaController.text = '';
    _pisoController.text = '';
    _deptoController.text = '';
    _localidadController.text = '';
    _provinciaController.text = '';
    _cpController.text = '';
    _barrioController.text = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo domicilio de envío'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _calleController,
                decoration: InputDecoration(
                  labelText: 'Calle *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _alturaController,
                decoration: InputDecoration(
                  labelText: 'Altura *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pisoController,
                      decoration: InputDecoration(
                        labelText: 'Piso',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _deptoController,
                      decoration: InputDecoration(
                        labelText: 'Depto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _localidadController,
                decoration: InputDecoration(
                  labelText: 'Localidad *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _provinciaController,
                decoration: InputDecoration(
                  labelText: 'Provincia *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _cpController,
                decoration: InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _barrioController,
                decoration: InputDecoration(
                  labelText: 'Barrio',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validar campos obligatorios
              if (_calleController.text.isEmpty ||
                  _alturaController.text.isEmpty ||
                  _localidadController.text.isEmpty ||
                  _provinciaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor complete los campos obligatorios')),
                );
                return;
              }

              // Obtener cliente seleccionado (si existe)
              final clienteCubit = context.read<ClientesMostradorCubit>();
              final cliente = clienteCubit.state.clienteSeleccionado;

              // Guardar datos para envío
              _datosEnvio = {
                'tipo_envio': 'otro_domicilio',
                'cliente_id': cliente?.idCliente,
                'calle': _calleController.text,
                'altura': _alturaController.text,
                'piso': _pisoController.text.isNotEmpty ? _pisoController.text : null,
                'depto': _deptoController.text.isNotEmpty ? _deptoController.text : null,
                'localidad': _localidadController.text,
                'provincia': _provinciaController.text,
                'codigo_postal': _cpController.text.isNotEmpty ? _cpController.text : null,
                'barrio': _barrioController.text.isNotEmpty ? _barrioController.text : null,
              };

              // Actualizar UI
              setState(() {});

              // Cerrar diálogo
              Navigator.pop(context);

              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dirección de envío guardada')),
              );
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Guarda la venta con la información de envío
  void _guardarVentaConEnvio() {
    // Validar que hay tipo de envío
    if (_selectedTipoEnvio == 1 && (_datosEnvio.isEmpty || _datosEnvio['tipo_envio'] != 'domicilio_cliente')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor complete la información del domicilio del cliente')),
      );
      return;
    }

    if (_selectedTipoEnvio == 2 && (_datosEnvio.isEmpty || _datosEnvio['tipo_envio'] != 'otro_domicilio')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingrese un domicilio de envío')),
      );
      return;
    }

    // Aquí irá la lógica para guardar la venta con los datos de envío
    // Por ahora, solo mostramos los datos que se guardarían
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Venta guardada con datos de envío: ${_datosEnvio['tipo_envio'] ?? "retiro_sucursal"}')),
    );

    print('Datos de envío: $_datosEnvio');
  }
}