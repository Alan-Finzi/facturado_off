import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/metodo_pago_model.dart';
import '../widget/buscar_cliente.dart';

// Modelo para agrupar los métodos de pago por tipo
class TipoCobro {
  final int id;
  final String nombre;
  final List<MetodoPagoModel> metodosPago;

  TipoCobro({required this.id, required this.nombre, required this.metodosPago});
}

class FormaCobroPage extends StatefulWidget {
  final VoidCallback onBackPressed; // Callback para manejar el botón "Anterior"

  FormaCobroPage({required this.onBackPressed});

  @override
  _FormaCobroPageState createState() => _FormaCobroPageState();
}

class _FormaCobroPageState extends State<FormaCobroPage> {
  bool isPagoParcial = false;

  // Variables para los métodos de pago
  List<TipoCobro> tiposCobro = [];
  TipoCobro? tipoCobroSeleccionado;
  MetodoPagoModel? formaCobroSeleccionada;

  // IDs y recargo para guardar en la base de datos
  int? tipoCobroId;
  int? formaCobroId;
  double recargoSeleccionado = 0.0;

  // Estado de carga
  bool isLoading = true;

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
  void initState() {
    super.initState();
    // Cargar los métodos de pago desde la base de datos
    _cargarMetodosPago();
  }

  // Método para cargar los métodos de pago desde la base de datos
  Future<void> _cargarMetodosPago() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Obtener todos los métodos de pago de la base de datos
      List<MetodoPagoModel> metodosPago = await DatabaseHelper.instance.getMetodosPago();

      if (metodosPago.isEmpty) {
        // Si no hay métodos de pago en la base de datos, crear algunos por defecto
        // Este es un fallback por si la base de datos está vacía
        metodosPago = [
          MetodoPagoModel(id: 0, nombre: 'Efectivo', porcentajeRecargo: 0.0, acreditacionInmediata: 1),
          MetodoPagoModel(id: 1, nombre: 'Tarjeta de Débito', porcentajeRecargo: 0.0, acreditacionInmediata: 1),
          MetodoPagoModel(id: 2, nombre: 'Tarjeta de Crédito', porcentajeRecargo: 10.0, acreditacionInmediata: 0),
        ];
      }

      // Agrupar los métodos de pago por tipo
      Map<String, List<MetodoPagoModel>> metodosAgrupados = {};

      for (var metodo in metodosPago) {
        String tipoNombre = _obtenerTipoDeMetodo(metodo);

        if (!metodosAgrupados.containsKey(tipoNombre)) {
          metodosAgrupados[tipoNombre] = [];
        }

        metodosAgrupados[tipoNombre]!.add(metodo);
      }

      // Convertir el mapa a la lista de TipoCobro
      List<TipoCobro> tipos = [];
      int idTipo = 0;

      metodosAgrupados.forEach((nombre, metodos) {
        tipos.add(TipoCobro(
          id: idTipo++,
          nombre: nombre,
          metodosPago: metodos,
        ));
      });

      // Asegurarse de que "Efectivo" esté primero si existe
      tipos.sort((a, b) {
        if (a.nombre == 'Efectivo') return -1;
        if (b.nombre == 'Efectivo') return 1;
        return a.nombre.compareTo(b.nombre);
      });

      setState(() {
        tiposCobro = tipos;

        // Seleccionar el primer tipo por defecto si existe
        if (tipos.isNotEmpty) {
          tipoCobroSeleccionado = tipos.first;
          tipoCobroId = tipoCobroSeleccionado?.id;

          // Seleccionar el primer método del tipo por defecto si existe
          if (tipoCobroSeleccionado!.metodosPago.isNotEmpty) {
            formaCobroSeleccionada = tipoCobroSeleccionado!.metodosPago.first;
            formaCobroId = formaCobroSeleccionada?.id;
            recargoSeleccionado = formaCobroSeleccionada?.porcentajeRecargo ?? 0.0;
          }
        }

        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar métodos de pago: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para determinar el tipo de cobro a partir del método de pago
  String _obtenerTipoDeMetodo(MetodoPagoModel metodo) {
    // Extraer el tipo del nombre del método
    final nombre = metodo.nombre ?? '';

    // Tipos de cobro conocidos (bancos y otros medios)
    final tiposConocidos = [
      'Efectivo',
      'Banco Provincia',
      'Banco Galicia',
      'Mercado Pago',
      'Tarjeta',
      'Transferencia',
    ];

    // Verificar si el nombre contiene alguno de los tipos conocidos
    for (var tipo in tiposConocidos) {
      if (nombre.contains(tipo)) {
        return tipo;
      }
    }

    // Si no se encuentra un tipo conocido, usar la primera palabra del nombre
    if (nombre.contains(' ')) {
      return nombre.split(' ')[0];
    }

    return nombre;  // Si no hay espacios, usar el nombre completo
  }

  // Método para actualizar la selección del tipo de cobro
  void _onTipoCobroChanged(TipoCobro? newValue) {
    setState(() {
      // Actualizar el tipo de cobro seleccionado
      tipoCobroSeleccionado = newValue;
      tipoCobroId = newValue?.id;

      // Resetear la forma de cobro y el recargo
      formaCobroSeleccionada = null;
      formaCobroId = null;
      recargoSeleccionado = 0.0;

      // Preseleccionar el primer método de pago si existe
      if (tipoCobroSeleccionado != null && tipoCobroSeleccionado!.metodosPago.isNotEmpty) {
        formaCobroSeleccionada = tipoCobroSeleccionado!.metodosPago.first;
        formaCobroId = formaCobroSeleccionada?.id;
        recargoSeleccionado = formaCobroSeleccionada?.porcentajeRecargo ?? 0.0;
      }
    });
  }

  // Método para actualizar la selección de forma de cobro
  void _onFormaCobroChanged(MetodoPagoModel? newValue) {
    setState(() {
      // Actualizar la forma de cobro seleccionada
      formaCobroSeleccionada = newValue;
      formaCobroId = newValue?.id;

      // Actualizar el recargo
      if (newValue?.porcentajeRecargo != null) {
        recargoSeleccionado = newValue!.porcentajeRecargo!;
      } else {
        recargoSeleccionado = 0.0;
      }

      // Actualizar el estado global con los datos de la forma de pago
      final productosCubit = context.read<ProductosCubit>();
      productosCubit.updateFormaPago(
        formaCobroId,
        formaCobroSeleccionada?.nombre,
        recargoSeleccionado
      );

      print('Forma de cobro seleccionada: ${newValue?.nombre}, Recargo: $recargoSeleccionado%');
    });
  }

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isPagoParcial ? Colors.grey[800] : Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 20),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: Text('Pago total'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPagoParcial ? Colors.grey[800] : Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 20),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: Text('Pago dividido o en Cuenta Corriente'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              if (!isPagoParcial)
              // === UI para Pago Total ===
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Columna izquierda: Método de cobro ----
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Método de cobro',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              // Dropdown para seleccionar el tipo de cobro
                              isLoading
                                ? Center(child: CircularProgressIndicator())
                                : DropdownButtonFormField<TipoCobro>(
                                    value: tipoCobroSeleccionado,
                                    items: tiposCobro.map((tipo) =>
                                      DropdownMenuItem<TipoCobro>(
                                        value: tipo,
                                        child: Text(tipo.nombre),
                                      )
                                    ).toList(),
                                    onChanged: _onTipoCobroChanged,
                                    decoration: InputDecoration(
                                      labelText: 'Tipo de cobro',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                              SizedBox(height: 8),
                              // Dropdown para seleccionar la forma de cobro
                              isLoading
                                ? Center(child: CircularProgressIndicator())
                                : DropdownButtonFormField<MetodoPagoModel>(
                                    value: formaCobroSeleccionada,
                                    items: tipoCobroSeleccionado?.metodosPago.map((metodo) =>
                                      DropdownMenuItem<MetodoPagoModel>(
                                        value: metodo,
                                        child: Text(metodo.nombre ?? 'Sin nombre'),
                                      )
                                    ).toList() ?? [],
                                    onChanged: _onFormaCobroChanged,
                                    decoration: InputDecoration(
                                      labelText: 'Forma de cobro',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                              // Mostrar el recargo si hay alguno
                              if (recargoSeleccionado > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Recargo: ${recargoSeleccionado.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),

                        // ---- Columna derecha: Monto a pagar ----
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monto a pagar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText:
                                        'Ingresa el monto con el que va a pagar tu cliente',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Acción para llenar con el total
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                    child: Text('Paga el total'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Vuelto a entregar',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Nuevo: Resumen con recargo
                    SizedBox(height: 20),
                    Text(
                      'Resumen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mostrar recargo en el resumen
                            // Esto se implementará completo con el ResumenVentaConRecargo
                            if (recargoSeleccionado > 0)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'El recargo de ${recargoSeleccionado.toStringAsFixed(1)}% se aplicará al total',
                                  style: TextStyle(color: Colors.red),
                                ),
                                leading: Icon(Icons.warning, color: Colors.orange),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
              // === Bloque de pago parcial (actualizado) ===
                BlocBuilder<ProductosCubit, ProductosState>(
                  builder: (context, productosState) {
                    // Informar al cubit que estamos en modo de pago dividido
                    // Nota: esto debería llamarse solo una vez al iniciar
                    if (!productosState.esPagoDividido) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.read<ProductosCubit>().setPagoDividido(true);
                      });
                    }

                    // Calcular total a pagar
                    double totalAPagar = 0;
                    for (var producto in productosState.productosSeleccionados) {
                      totalAPagar += producto.precioFinal ?? 0;
                    }

                    // Aplicar descuento general
                    final descuentoGral = (productosState.descuentoGeneral / 100) * totalAPagar;
                    totalAPagar -= descuentoGral;

                    // Obtener pagos parciales y total pagado
                    final pagosParciales = productosState.pagosParciales;
                    final totalPagado = productosState.pagosParciales.fold(
                      0.0, (sum, pago) => sum + pago.montoTotal
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de pagos parciales ya agregados
                        if (pagosParciales.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pagos agregados',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              // Lista de pagos parciales
                              ...pagosParciales.asMap().entries.map((entry) {
                                int index = entry.key;
                                PagoParcial pago = entry.value;
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      '${pago.tipoCobroNombre} - ${pago.formaCobroNombre}',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: pago.porcentajeRecargo > 0
                                      ? Text('Recargo: ${pago.porcentajeRecargo.toStringAsFixed(1)}%')
                                      : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '\$${pago.montoPago.toStringAsFixed(2)}',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        if (pago.montoRecargo > 0)
                                          Text(
                                            ' + \$${pago.montoRecargo.toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            context.read<ProductosCubit>().eliminarPagoParcial(index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              SizedBox(height: 16),
                            ],
                          ),

                        // Formulario para agregar nuevo pago parcial
                        Text(
                          'Agregar nuevo pago',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Dropdown para tipo de cobro
                                DropdownButtonFormField<TipoCobro>(
                                  value: tipoCobroSeleccionado,
                                  items: tiposCobro.map((tipo) =>
                                    DropdownMenuItem<TipoCobro>(
                                      value: tipo,
                                      child: Text(tipo.nombre),
                                    )
                                  ).toList(),
                                  onChanged: _onTipoCobroChanged,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de cobro',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Dropdown para forma de cobro
                                DropdownButtonFormField<MetodoPagoModel>(
                                  value: formaCobroSeleccionada,
                                  items: tipoCobroSeleccionado?.metodosPago.map((metodo) =>
                                    DropdownMenuItem<MetodoPagoModel>(
                                      value: metodo,
                                      child: Text(metodo.nombre ?? 'Sin nombre'),
                                    )
                                  ).toList() ?? [],
                                  onChanged: _onFormaCobroChanged,
                                  decoration: InputDecoration(
                                    labelText: 'Forma de cobro',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Campo para monto
                                TextField(
                                  controller: TextEditingController(
                                    text: (totalAPagar - totalPagado).toStringAsFixed(2),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Monto a pagar',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                ),

                                // Mostrar recargo si aplica
                                if (recargoSeleccionado > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Recargo: ${recargoSeleccionado.toStringAsFixed(2)}%',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),

                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Obtener monto del campo de texto
                                    final montoText = (totalAPagar - totalPagado).toStringAsFixed(2);
                                    final monto = double.tryParse(montoText) ?? 0.0;

                                    // Crear pago parcial
                                    final pago = PagoParcial(
                                      tipoCobroId: tipoCobroId,
                                      tipoCobroNombre: tipoCobroSeleccionado?.nombre,
                                      formaCobroId: formaCobroId,
                                      formaCobroNombre: formaCobroSeleccionada?.nombre,
                                      montoPago: monto,
                                      porcentajeRecargo: recargoSeleccionado,
                                    );

                                    // Agregar al estado
                                    context.read<ProductosCubit>().agregarPagoParcial(pago);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 48),
                                  ),
                                  child: Text('Agregar pago'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Resumen de pagos
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumen de pagos',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total a pagar:'),
                                    Text(
                                      '\$${totalAPagar.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Pagado:'),
                                    Text('\$${totalPagado.toStringAsFixed(2)}'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Recargo total:'),
                                    Text(
                                      '\$${productosState.calcularTotalRecargoPesos().toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                                Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      totalAPagar - totalPagado > 0
                                      ? 'Saldo pendiente:'
                                      : 'Vuelto:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '\$${(totalAPagar - totalPagado).abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: totalAPagar - totalPagado > 0
                                          ? Colors.red
                                          : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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

  // Guarda la venta con la información de envío y cobro
  void _guardarVentaConEnvio() {
    final productosCubit = context.read<ProductosCubit>();

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

    // Validaciones según tipo de pago
    if (isPagoParcial) {
      // Validar pagos parciales
      final pagosParciales = productosCubit.state.pagosParciales;
      if (pagosParciales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor agregue al menos un método de pago')),
        );
        return;
      }

      // Verificar si se pagó el monto completo
      double totalAPagar = 0;
      for (var producto in productosCubit.state.productosSeleccionados) {
        totalAPagar += producto.precioFinal ?? 0;
      }

      // Aplicar descuento general
      final descuentoGral = (productosCubit.state.descuentoGeneral / 100) * totalAPagar;
      totalAPagar -= descuentoGral;

      // Calcular total pagado
      final totalPagado = productosCubit.calcularTotalPagado();

      // Verificar si hay saldo pendiente
      if (totalAPagar > totalPagado) {
        // Mostrar advertencia y preguntar si quiere continuar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Monto insuficiente'),
            content: Text('El monto total pagado (\$${totalPagado.toStringAsFixed(2)}) es menor que el total a pagar (\$${totalAPagar.toStringAsFixed(2)}). ¿Desea guardar la venta con saldo pendiente?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completarGuardado(productosCubit);
                },
                child: Text('Continuar'),
              ),
            ],
          ),
        );
        return;
      }

      // Si todo está bien, guardar
      _completarGuardado(productosCubit);

    } else {
      // Pago total - Validar que hay método de pago seleccionado
      if (formaCobroId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor seleccione una forma de cobro')),
        );
        return;
      }

      // Si todo está bien, guardar
      _completarGuardado(productosCubit);
    }
  }

  // Método auxiliar para completar el guardado de la venta
  void _completarGuardado(ProductosCubit productosCubit) {
    // Preparar datos según el tipo de pago
    Map<String, dynamic> datosCobro;

    if (isPagoParcial) {
      // Para pago dividido, guardar lista de pagos parciales
      final pagosParciales = productosCubit.state.pagosParciales;

      // Convertir pagos parciales a formato para guardar
      final pagosList = pagosParciales.map((pago) => pago.toMap()).toList();

      // Calcular recargo total en pesos
      final recargoTotalPesos = productosCubit.calcularTotalRecargoPesos();

      // Calcular el porcentaje efectivo de recargo
      final totalAPagar = productosCubit.state.productosSeleccionados.fold(
        0.0, (sum, producto) => sum + (producto.precioFinal ?? 0)
      );
      final porcentajeEfectivo = totalAPagar > 0 ? (recargoTotalPesos / totalAPagar) * 100 : 0.0;

      datosCobro = {
        'es_pago_dividido': true,
        'pagos_parciales': pagosList,
        'recargo_total_pesos': recargoTotalPesos,
        'recargo_porcentaje_efectivo': porcentajeEfectivo,
      };
    } else {
      // Para pago total, usar el método seleccionado
      datosCobro = {
        'es_pago_dividido': false,
        'tipo_cobro_id': tipoCobroId,
        'tipo_cobro_nombre': tipoCobroSeleccionado?.nombre,
        'forma_cobro_id': formaCobroId,
        'forma_cobro_nombre': formaCobroSeleccionada?.nombre,
        'recargo_porcentaje': recargoSeleccionado,
      };
    }

    // Combinar datos de envío con datos de cobro
    final datosCompletos = {
      ..._datosEnvio,
      'cobro': datosCobro,
      'pago_total': !isPagoParcial,
    };

    // Aquí irá la lógica para guardar la venta con los datos de envío y cobro
    // Por ahora, solo mostramos los datos que se guardarían
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venta guardada: ${isPagoParcial ? "Pago dividido" : "Pago total"}, ' +
          (isPagoParcial
            ? '${productosCubit.state.pagosParciales.length} métodos de pago, ' +
              'Recargo total: \$${productosCubit.calcularTotalRecargoPesos().toStringAsFixed(2)}'
            : 'Método: ${formaCobroSeleccionada?.nombre ?? "Ninguno"}, ' +
              'Recargo: ${recargoSeleccionado.toStringAsFixed(2)}%'
          )
        ),
      ),
    );

    print('Datos completos de la venta:');
    print('- Envío: ${_datosEnvio['tipo_envio'] ?? "retiro_sucursal"}');

    if (isPagoParcial) {
      print('- Pago dividido con ${productosCubit.state.pagosParciales.length} métodos de pago');
      print('- Recargo total: \$${productosCubit.calcularTotalRecargoPesos().toStringAsFixed(2)}');

      for (int i = 0; i < productosCubit.state.pagosParciales.length; i++) {
        final pago = productosCubit.state.pagosParciales[i];
        print('  Pago ${i+1}: ${pago.tipoCobroNombre} - ${pago.formaCobroNombre}');
        print('    Monto: \$${pago.montoPago.toStringAsFixed(2)}');
        print('    Recargo: ${pago.porcentajeRecargo.toStringAsFixed(2)}% = \$${pago.montoRecargo.toStringAsFixed(2)}');
      }
    } else {
      print('- Método de pago: ${formaCobroSeleccionada?.nombre ?? "No seleccionado"}');
      print('- Recargo: ${recargoSeleccionado.toStringAsFixed(2)}%');
      print('- IDs para BD: tipoCobroId=$tipoCobroId, formaCobroId=$formaCobroId');
    }

    print('- Datos completos: $datosCompletos');
  }
}