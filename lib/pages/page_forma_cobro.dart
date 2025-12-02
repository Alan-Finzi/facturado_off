import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_state.dart';
import '../bloc/cubit_payment_methods/payment_methods_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../helper/sales_database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/sales/sale.dart';
import '../models/sales/sale_detail.dart';
import '../models/payment_method.dart';
import '../pages/page_ventas_sincronizacion.dart';
import '../widget/buscar_cliente.dart';
import '../widget/payment_methods_form_widget.dart';

class FormaCobroPage extends StatefulWidget {
  final VoidCallback onBackPressed; // Callback para manejar el botón "Anterior"

  FormaCobroPage({required this.onBackPressed});

  @override
  _FormaCobroPageState createState() => _FormaCobroPageState();
}

class _FormaCobroPageState extends State<FormaCobroPage> {
  bool isPagoParcial = false;
  bool _isLoading = false; // Para mostrar indicador de carga durante operaciones

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
    // Use the PaymentMethodsCubit provided by the parent widget
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Usamos directamente el callback proporcionado en widget.onGuardarPressed
    // para no depender de una clase privada de otro archivo

    return Builder(
      builder: (context) {
        // Using the shared PaymentMethodsCubit instance from parent

          return Scaffold(
            appBar: AppBar(
              title: Text('Forma de Cobro'),
            ),
            body: Stack(
            children: [
              Padding(
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
                    // Sección Forma de Cobro (usando el widget especializado)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaymentMethodsFormWidget(),
                      ),
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

                    // Ya no necesitamos estos botones aquí, la funcionalidad estará en el resumen de venta
                  ],
                ),
              ),
              ),
              // Indicador de carga que se muestra sobre todo cuando está cargando
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10.0,
                            spreadRadius: 2.0,
                          )
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 20.0),
                          Text(
                            'Guardando venta...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10.0),
                          Text('Procesando información'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          );
      },
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

  // Este método ya no es necesario y se puede eliminar completamente
  void _mostrarDatosFormulario() {
    // Obtener el estado de los productos (para validaciones)
    final productosCubit = context.read<ProductosCubit>();
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Lista para almacenar campos faltantes
    List<String> camposFaltantes = [];

    // 1. Validar cliente seleccionado
    if (clienteCubit.state.clienteSeleccionado == null) {
      camposFaltantes.add("Cliente");
    }

    // 2. Validar productos seleccionados
    if (productosCubit.state.productosSeleccionados.isEmpty) {
      camposFaltantes.add("Productos en la venta");
    }

    // 3. Validar método de pago
    bool tieneMetodoPago = false;
    if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
      final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
      tieneMetodoPago = state.selectedMethodId != null;
    }

    if (!tieneMetodoPago) {
      camposFaltantes.add("Método de pago");
    }

    // 4. Validar datos de facturación
    if (productosCubit.state.datosFacturacionModel == null ||
        productosCubit.state.datosFacturacionModel!.isEmpty) {
      camposFaltantes.add("Datos de facturación");
    }

    // 5. Validar tipo de envío
    if (_selectedTipoEnvio == 1 && (_datosEnvio.isEmpty || _datosEnvio['tipo_envio'] != 'domicilio_cliente')) {
      camposFaltantes.add("Domicilio de envío del cliente");
    }

    if (_selectedTipoEnvio == 2 && (_datosEnvio.isEmpty || _datosEnvio['tipo_envio'] != 'otro_domicilio')) {
      camposFaltantes.add("Domicilio de envío alternativo");
    }

    // Si hay campos faltantes, mostrar error
    if (camposFaltantes.isNotEmpty) {
      _mostrarErrorCamposFaltantes(camposFaltantes);
      return;
    }

    // Si todas las validaciones pasan, mostrar el popup de confirmación
    _mostrarPopupConfirmacionVenta();
  }

  // Muestra un popup con los campos faltantes
  void _mostrarErrorCamposFaltantes(List<String> campos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Información incompleta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por favor complete la siguiente información antes de guardar:'),
            SizedBox(height: 12),
            ...campos.map((campo) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(campo),
                ],
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Muestra un popup de confirmación de la venta con los detalles
  void _mostrarPopupConfirmacionVenta() {
    final productosCubit = context.read<ProductosCubit>();
    final clienteCubit = context.read<ClientesMostradorCubit>();
    final paymentMethodsCubit = context.read<PaymentMethodsCubit>();

    // Obtener datos para mostrar
    final cliente = clienteCubit.state.clienteSeleccionado;
    final productos = productosCubit.state.productosSeleccionados;
    final subtotal = productos.fold(0.0, (sum, producto) => sum + (producto.precioLista ?? 0.0));
    final descuento = productosCubit.state.descuentoGeneral;
    final montoDescuento = subtotal * (descuento / 100);
    final iva = productos.fold(0.0, (sum, producto) => sum + (producto.iva ?? 0.0));
    final total = subtotal - montoDescuento + iva;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirmar venta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Por favor confirme los detalles de la venta:'),
              SizedBox(height: 16),

              // Cliente
              Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cliente?.nombre ?? 'Consumidor final'),
              SizedBox(height: 8),

              // Productos
              Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...productos.map((producto) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(producto.producto?.name ?? 'Producto sin nombre'),
                    ),
                    Text('\$${producto.precioLista?.toStringAsFixed(2) ?? '0.00'}'),
                  ],
                ),
              )),
              Divider(),

              // Totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:'),
                  Text('\$${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              if (descuento > 0) Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Descuento (${descuento.toStringAsFixed(2)}%):'),
                  Text('-\$${montoDescuento.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IVA:'),
                  Text('\$${iva.toStringAsFixed(2)}'),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),

              // Método de pago
              SizedBox(height: 16),
              Text('Método de pago:', style: TextStyle(fontWeight: FontWeight.bold)),
              Builder(
                builder: (context) {
                  String methodName = 'No seleccionado';
                  if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
                    final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
                    if (state.selectedMethodId != null && state.selectedProviderId != null) {
                      // Buscar el método en los proveedores
                      for (final provider in state.providers) {
                        if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
                          for (final method in provider.metodosPago!) {
                            if (method.id == state.selectedMethodId) {
                              methodName = method.nombre;
                              break;
                            }
                          }
                        }
                      }
                    }
                  }
                  return Text(methodName);
                },
              ),

              // Tipo de envío
              SizedBox(height: 16),
              Text('Tipo de envío:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_selectedTipoEnvio == 0
                ? 'Retiro en sucursal'
                : _selectedTipoEnvio == 1
                  ? 'Envío a domicilio del cliente'
                  : 'Envío a otro domicilio'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cerrar el diálogo
              Navigator.of(context).pop();
              // Guardar la venta
              _guardarVentaEnBaseDeDatos();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Guardar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar guardar e imprimir
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función guardar e imprimir no implementada aún')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Guardar e imprimir'),
          ),
        ],
      ),
    );
  }

  // Guarda la venta en la base de datos
  Future<void> _guardarVentaEnBaseDeDatos() async {
    try {
      setState(() {
        _isLoading = true; // Mostrar indicador de carga
      });

      // Obtener los datos necesarios de los diferentes cubits
      final productosCubit = context.read<ProductosCubit>();
      final clienteCubit = context.read<ClientesMostradorCubit>();
      final paymentMethodsCubit = context.read<PaymentMethodsCubit>();
      final loginCubit = context.read<LoginCubit>();

      // Datos del usuario actual
      final userId = loginCubit.state.user?.id;
      final comercioId = loginCubit.state.user?.comercioId != null
          ? int.tryParse(loginCubit.state.user!.comercioId!) ?? 0
          : 0;

      // Productos seleccionados
      final productos = productosCubit.state.productosSeleccionados;

      // Calcular totales
      final subtotal = productos.fold(0.0, (sum, producto) => sum + (producto.precioLista ?? 0.0));
      final descuentoGeneral = productosCubit.state.descuentoGeneral;
      final montoDescuento = subtotal * (descuentoGeneral / 100);
      final iva = productos.fold(0.0, (sum, producto) => sum + (producto.iva ?? 0.0));
      final total = subtotal - montoDescuento + iva;

      // Cliente
      final cliente = clienteCubit.state.clienteSeleccionado;

      // Método de pago
      PaymentMethod? metodoPago;
      String metodoPagoNombre = 'Efectivo';

      // Obtener el método de pago seleccionado
      if (paymentMethodsCubit.state is PaymentMethodsLoaded) {
        final state = paymentMethodsCubit.state as PaymentMethodsLoaded;
        if (state.selectedMethodId != null && state.selectedProviderId != null) {
          // Buscar el método en los proveedores
          for (final provider in state.providers) {
            if (provider.id == state.selectedProviderId && provider.metodosPago != null) {
              for (final method in provider.metodosPago!) {
                if (method.id == state.selectedMethodId) {
                  metodoPago = method;
                  metodoPagoNombre = method.nombre;
                  break;
                }
              }
              if (metodoPago != null) break;
            }
          }
        }
      }
      // Aquí podríamos guardar detalles adicionales del método de pago como un JSON

      // Datos de facturación
      final datosFacturacion = productosCubit.state.datosFacturacionModel?.isNotEmpty == true
          ? productosCubit.state.datosFacturacionModel!.first
          : null;

      // Canal de venta y caja
      final canalVenta = productosCubit.state.canalVenta ?? 'Mostrador';
      final cajaId = 1; // Valor por defecto, idealmente sería configurable

      // Domicilio de entrega en formato JSON
      String? domicilioEntrega;
      if (_selectedTipoEnvio > 0 && _datosEnvio.isNotEmpty) {
        domicilioEntrega = _datosEnvio.toString();
      }

      // Crear el objeto de venta
      final sale = Sale(
        fecha: DateTime.now(),
        comercioId: comercioId,
        clienteId: cliente?.idCliente != null ? int.tryParse(cliente!.idCliente!) : null,
        domicilioEntrega: domicilioEntrega,
        tipoComprobante: productosCubit.state.tipoFactura ?? 'Ticket',
        datosFacturacionId: datosFacturacion?.id,
        subtotal: subtotal,
        iva: iva,
        total: total,
        descuento: montoDescuento,
        recargo: 0.0, // No estamos manejando recargos por ahora
        metodoPago: metodoPagoNombre,
        metodoPagoDetalles: metodoPago?.descripcion,
        sincronizado: 0, // No sincronizado inicialmente
        eliminado: 0,
        estado: 'completada', // Estado inicial
        userId: userId,
        canalVenta: canalVenta,
        cajaId: cajaId,
        notaInterna: null, // Aquí podríamos agregar una nota interna si la UI lo permite
        observaciones: null, // Aquí podríamos agregar observaciones si la UI lo permite
      );

      // Crear detalles de venta para cada producto
      final detalles = productos.map((producto) {
        final porcentajeIva = (producto.iva ?? 0.0) > 0
            ? ((producto.iva ?? 0.0) / (producto.precioLista ?? 1.0)) * 100
            : 0.0;

        return SaleDetail.calculate(
          ventaId: 0, // Se actualizará después de insertar la venta
          productoId: producto.producto?.id ?? 0,
          codigoProducto: producto.producto?.barcode,
          nombreProducto: producto.producto?.name ?? 'Producto sin nombre',
          descripcion: null,
          cantidad: 1.0, // Por defecto 1, pero debería ser configurable
          precioUnitario: producto.precioLista ?? 0.0,
          porcentajeIva: porcentajeIva,
          descuento: 0.0, // No manejamos descuentos individuales por ahora
          categoriaId: producto.producto?.tipoProducto != null
              ? int.tryParse(producto.producto!.tipoProducto!)
              : null,
          categoriaNombre: producto.categoria,
        );
      }).toList();

      // Asignar los detalles a la venta
      final ventaConDetalles = sale.copyWith(detalles: detalles);

      // Guardar la venta en la base de datos utilizando SalesDatabaseHelper
      final salesDatabaseHelper = SalesDatabaseHelper();
      final ventaId = await salesDatabaseHelper.saveSale(ventaConDetalles);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta #$ventaId guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navegar de vuelta a la página principal o a la página de ventas
        // Navigator.of(context).popUntil((route) => route.isFirst);

        // Alternativamente, navegar a la página de sincronización de ventas
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PageVentasSincronizacion(),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error al guardar venta: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ocultar indicador de carga
        });
      }
    }
  }
}