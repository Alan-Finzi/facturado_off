import 'package:flutter/material.dart';
import 'package:facturador_offline/models/clientes_mostrador.dart';

/// Widget que permite seleccionar el tipo de entrega para una venta
/// Incluye opciones de retiro por sucursal, envío a domicilio del cliente
/// y envío a otro domicilio, con los campos necesarios para cada caso.
class SelectorEntregaWidget extends StatefulWidget {
  final String value;
  final void Function(String?)? onChanged;
  final void Function(Map<String, dynamic>)? onEnvioDataChanged;
  final ClientesMostrador? cliente;
  final List<String> opciones;

  const SelectorEntregaWidget({
    Key? key,
    required this.value,
    this.onChanged,
    this.onEnvioDataChanged,
    this.cliente,
    this.opciones = const ['Retiro por sucursal', 'Envío a domicilio del cliente', 'Envío a otro domicilio'],
  }) : super(key: key);

  @override
  State<SelectorEntregaWidget> createState() => _SelectorEntregaWidgetState();
}

class _SelectorEntregaWidgetState extends State<SelectorEntregaWidget> {
  // Controladores para los campos de texto
  final _calleController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pisoController = TextEditingController();
  final _deptoController = TextEditingController();
  final _localidadController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _cpController = TextEditingController();
  final _barrioController = TextEditingController();

  // Mapa para almacenar los datos de envío
  Map<String, dynamic> _datosEnvio = {};

  @override
  void initState() {
    super.initState();
    // Inicializar datos de envío como retiro por sucursal (opción por defecto)
    _datosEnvio = {'tipo_envio': 'retiro_sucursal'};
    // Diferir la notificación al padre para evitar setState() durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notificarDatosEnvio();
    });
  }

  @override
  void dispose() {
    // Liberar controladores
    _calleController.dispose();
    _alturaController.dispose();
    _pisoController.dispose();
    _deptoController.dispose();
    _localidadController.dispose();
    _provinciaController.dispose();
    _cpController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Tipo de envío:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Selector de tipo de envío
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: widget.value,
                icon: const Icon(Icons.keyboard_arrow_down),
                onChanged: (String? newValue) {
                  if (newValue != null && widget.onChanged != null) {
                    widget.onChanged!(newValue);
                    _handleTipoEnvioChanged(newValue);
                  }
                },
                items: widget.opciones.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
            ),
          ),

          // Mostrar campos adicionales según el tipo de envío seleccionado
          const SizedBox(height: 8),
          _buildCamposAdicionales(),
        ],
      ),
    );
  }

  // Construye los campos adicionales según el tipo de envío seleccionado
  Widget _buildCamposAdicionales() {
    // Si es retiro por sucursal, no mostrar campos adicionales
    if (widget.value == 'Retiro por sucursal') {
      return const SizedBox.shrink();
    }

    // Si es envío a domicilio del cliente
    if (widget.value == 'Envío a domicilio del cliente') {
      // Verificar si el cliente tiene dirección completa
      if (widget.cliente != null && _verificarDireccionCompleta(widget.cliente!)) {
        // Si tiene dirección completa, mostrarla
        return _buildDireccionCliente(widget.cliente!);
      } else {
        // Si no tiene dirección completa, mostrar formulario para completarla
        return _buildFormularioDireccion(
          titulo: 'Completar dirección del cliente',
          precargarCliente: widget.cliente,
          tipoEnvio: 'domicilio_cliente',
        );
      }
    }

    // Si es envío a otro domicilio
    return _buildFormularioDireccion(
      titulo: 'Dirección de envío',
      tipoEnvio: 'otro_domicilio',
    );
  }

  // Construye un widget para mostrar la dirección del cliente
  Widget _buildDireccionCliente(ClientesMostrador cliente) {
    // Capturar datos del cliente para envío
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
    // Diferir notificación para evitar setState() durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notificarDatosEnvio();
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dirección del cliente:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('${cliente.direccion ?? ""} ${cliente.altura ?? ""}'),
          if (cliente.piso != null || cliente.depto != null)
            Text('Piso: ${cliente.piso ?? ""}, Depto: ${cliente.depto ?? ""}'),
          Text('${cliente.localidad ?? ""}, ${cliente.provincia ?? ""}'),
          if (cliente.codigoPostal != null) Text('CP: ${cliente.codigoPostal}'),

          // Botón para editar dirección
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Prellenar formulario con datos del cliente
              _calleController.text = cliente.direccion ?? '';
              _alturaController.text = cliente.altura ?? '';
              _pisoController.text = cliente.piso ?? '';
              _deptoController.text = cliente.depto ?? '';
              _localidadController.text = cliente.localidad ?? '';
              _provinciaController.text = cliente.provincia ?? '';
              _cpController.text = cliente.codigoPostal ?? '';
              _barrioController.text = cliente.barrio ?? '';

              // Mostrar diálogo de edición
              _mostrarDialogoFormulario(
                context,
                'Editar dirección del cliente',
                tipoEnvio: 'domicilio_cliente',
                clienteId: cliente.idCliente,
              );
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar dirección'),
          ),
        ],
      ),
    );
  }

  // Construye un formulario para ingresar o editar dirección
  Widget _buildFormularioDireccion({
    required String titulo,
    required String tipoEnvio,
    ClientesMostrador? precargarCliente,
  }) {
    // Si hay un cliente para precargar y no se han inicializado los controladores
    if (precargarCliente != null && _calleController.text.isEmpty) {
      _calleController.text = precargarCliente.direccion ?? '';
      _alturaController.text = precargarCliente.altura ?? '';
      _pisoController.text = precargarCliente.piso ?? '';
      _deptoController.text = precargarCliente.depto ?? '';
      _localidadController.text = precargarCliente.localidad ?? '';
      _provinciaController.text = precargarCliente.provincia ?? '';
      _cpController.text = precargarCliente.codigoPostal ?? '';
      _barrioController.text = precargarCliente.barrio ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Calle y altura en la misma fila
          Row(
            children: [
              // Calle (70%)
              Expanded(
                flex: 7,
                child: TextField(
                  controller: _calleController,
                  decoration: const InputDecoration(
                    labelText: 'Calle *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Altura (30%)
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _alturaController,
                  decoration: const InputDecoration(
                    labelText: 'Altura *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Piso y depto en la misma fila
          Row(
            children: [
              // Piso (50%)
              Expanded(
                child: TextField(
                  controller: _pisoController,
                  decoration: const InputDecoration(
                    labelText: 'Piso',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Depto (50%)
              Expanded(
                child: TextField(
                  controller: _deptoController,
                  decoration: const InputDecoration(
                    labelText: 'Depto',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Localidad y provincia en la misma fila
          Row(
            children: [
              // Localidad (50%)
              Expanded(
                child: TextField(
                  controller: _localidadController,
                  decoration: const InputDecoration(
                    labelText: 'Localidad *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Provincia (50%)
              Expanded(
                child: TextField(
                  controller: _provinciaController,
                  decoration: const InputDecoration(
                    labelText: 'Provincia *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CP y barrio en la misma fila
          Row(
            children: [
              // CP (40%)
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _cpController,
                  decoration: const InputDecoration(
                    labelText: 'Código Postal',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Barrio (60%)
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _barrioController,
                  decoration: const InputDecoration(
                    labelText: 'Barrio',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // Botones de acción
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _guardarDatosDomicilio(tipoEnvio, precargarCliente?.idCliente),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Guardar dirección'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método para guardar los datos del formulario de domicilio
  void _guardarDatosDomicilio(String tipoEnvio, String? clienteId) {
    // Validar campos obligatorios
    if (_calleController.text.isEmpty ||
        _alturaController.text.isEmpty ||
        _localidadController.text.isEmpty ||
        _provinciaController.text.isEmpty) {

      // Mostrar error si faltan campos obligatorios
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos obligatorios (calle, altura, localidad y provincia)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Construir mapa de datos de envío
    _datosEnvio = {
      'tipo_envio': tipoEnvio,
      'cliente_id': clienteId,
      'calle': _calleController.text,
      'altura': _alturaController.text,
      'piso': _pisoController.text.isNotEmpty ? _pisoController.text : null,
      'depto': _deptoController.text.isNotEmpty ? _deptoController.text : null,
      'localidad': _localidadController.text,
      'provincia': _provinciaController.text,
      'codigo_postal': _cpController.text.isNotEmpty ? _cpController.text : null,
      'barrio': _barrioController.text.isNotEmpty ? _barrioController.text : null,
    };

    // Notificar cambios
    _notificarDatosEnvio();

    // Forzar rebuild del widget
    setState(() {});
  }

  // Método para mostrar diálogo con formulario
  void _mostrarDialogoFormulario(
    BuildContext context,
    String titulo, {
    required String tipoEnvio,
    String? clienteId,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calle
              TextField(
                controller: _calleController,
                decoration: const InputDecoration(
                  labelText: 'Calle *',
                  hintText: 'Ej: Av. Rivadavia',
                ),
              ),
              const SizedBox(height: 8),

              // Altura
              TextField(
                controller: _alturaController,
                decoration: const InputDecoration(
                  labelText: 'Altura *',
                  hintText: 'Ej: 1234',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              // Piso y Depto en la misma fila
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pisoController,
                      decoration: const InputDecoration(
                        labelText: 'Piso',
                        hintText: 'Ej: 3',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _deptoController,
                      decoration: const InputDecoration(
                        labelText: 'Depto',
                        hintText: 'Ej: B',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Localidad
              TextField(
                controller: _localidadController,
                decoration: const InputDecoration(
                  labelText: 'Localidad *',
                  hintText: 'Ej: San Miguel',
                ),
              ),
              const SizedBox(height: 8),

              // Provincia
              TextField(
                controller: _provinciaController,
                decoration: const InputDecoration(
                  labelText: 'Provincia *',
                  hintText: 'Ej: Buenos Aires',
                ),
              ),
              const SizedBox(height: 8),

              // CP y Barrio en la misma fila
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cpController,
                      decoration: const InputDecoration(
                        labelText: 'CP',
                        hintText: 'Ej: 1663',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _barrioController,
                      decoration: const InputDecoration(
                        labelText: 'Barrio',
                        hintText: 'Ej: Centro',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Guardar datos
              _guardarDatosDomicilio(tipoEnvio, clienteId);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Maneja el cambio de tipo de envío
  void _handleTipoEnvioChanged(String tipoEnvio) {
    switch (tipoEnvio) {
      case 'Retiro por sucursal':
        _datosEnvio = {'tipo_envio': 'retiro_sucursal'};
        _notificarDatosEnvio();
        break;

      case 'Envío a domicilio del cliente':
        // Si el cliente tiene dirección completa, usarla
        if (widget.cliente != null && _verificarDireccionCompleta(widget.cliente!)) {
          _datosEnvio = {
            'tipo_envio': 'domicilio_cliente',
            'cliente_id': widget.cliente!.idCliente,
            'calle': widget.cliente!.direccion,
            'altura': widget.cliente!.altura,
            'piso': widget.cliente!.piso,
            'depto': widget.cliente!.depto,
            'localidad': widget.cliente!.localidad,
            'provincia': widget.cliente!.provincia,
            'codigo_postal': widget.cliente!.codigoPostal,
            'barrio': widget.cliente!.barrio,
          };
          _notificarDatosEnvio();
        }
        // Si no, el formulario se encargará de solicitar los datos
        break;

      case 'Envío a otro domicilio':
        // Limpiar controladores para nuevo domicilio
        _calleController.text = '';
        _alturaController.text = '';
        _pisoController.text = '';
        _deptoController.text = '';
        _localidadController.text = '';
        _provinciaController.text = '';
        _cpController.text = '';
        _barrioController.text = '';
        // Los datos se completarán cuando el usuario llene el formulario
        break;
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

  // Notifica al padre sobre cambios en los datos de envío
  void _notificarDatosEnvio() {
    if (widget.onEnvioDataChanged != null) {
      widget.onEnvioDataChanged!(_datosEnvio);
    }
  }
}