import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../models/metodo_pago_model.dart';
import '../models/pago_parcial_model.dart';

/// Clase utilizada para representar un tipo de cobro con sus formas de pago
class TipoCobro {
  final int id;
  final String nombre;
  final List<MetodoPagoModel> metodosPago;

  TipoCobro({required this.id, required this.nombre, required this.metodosPago});
}

/// Widget para agregar un nuevo pago parcial
class AgregarPagoParcialWidget extends StatefulWidget {
  /// Lista de tipos de cobro disponibles
  final List<TipoCobro> tiposCobro;

  /// Total a pagar
  final double totalAPagar;

  /// Total ya pagado
  final double totalPagado;

  /// Constructor
  const AgregarPagoParcialWidget({
    Key? key,
    required this.tiposCobro,
    required this.totalAPagar,
    required this.totalPagado,
  }) : super(key: key);

  @override
  _AgregarPagoParcialWidgetState createState() => _AgregarPagoParcialWidgetState();
}

class _AgregarPagoParcialWidgetState extends State<AgregarPagoParcialWidget> {
  // Variables para los métodos de pago
  TipoCobro? tipoCobroSeleccionado;
  MetodoPagoModel? formaCobroSeleccionada;

  // IDs y recargo para guardar
  int? tipoCobroId;
  int? formaCobroId;
  double recargoSeleccionado = 0.0;

  // Controlador para el monto
  final TextEditingController _montoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Inicializar con el primer tipo de cobro si existe
    if (widget.tiposCobro.isNotEmpty) {
      tipoCobroSeleccionado = widget.tiposCobro.first;
      tipoCobroId = tipoCobroSeleccionado?.id;

      // Seleccionar el primer método del tipo por defecto si existe
      if (tipoCobroSeleccionado!.metodosPago.isNotEmpty) {
        formaCobroSeleccionada = tipoCobroSeleccionado!.metodosPago.first;
        formaCobroId = formaCobroSeleccionada?.id;
        recargoSeleccionado = formaCobroSeleccionada?.porcentajeRecargo ?? 0.0;
      }
    }

    // Sugerir pagar el saldo pendiente
    final saldoPendiente = widget.totalAPagar - widget.totalPagado;
    if (saldoPendiente > 0) {
      _montoController.text = saldoPendiente.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
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
    });
  }

  // Método para calcular el recargo en pesos
  double _calcularRecargoPesos() {
    double monto = double.tryParse(_montoController.text) ?? 0.0;
    return (recargoSeleccionado / 100) * monto;
  }

  // Método para agregar el pago parcial
  void _agregarPagoParcial() {
    // Validar entrada
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingrese un monto válido')),
      );
      return;
    }

    if (formaCobroSeleccionada == null || tipoCobroSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor seleccione el método de pago')),
      );
      return;
    }

    // Crear el pago parcial
    final nuevoPago = PagoParcial(
      tipoCobroId: tipoCobroId,
      tipoCobroNombre: tipoCobroSeleccionado?.nombre,
      formaCobroId: formaCobroId,
      formaCobroNombre: formaCobroSeleccionada?.nombre,
      montoPago: monto,
      porcentajeRecargo: recargoSeleccionado,
    );

    // Agregar al estado
    final productosCubit = context.read<ProductosCubit>();
    productosCubit.agregarPagoParcial(nuevoPago);

    // Limpiar el campo y mostrar mensaje
    _montoController.clear();

    // Calcular nuevo saldo y sugerir monto
    final totalPagado = productosCubit.calcularTotalPagado();
    final saldoPendiente = widget.totalAPagar - totalPagado;

    if (saldoPendiente > 0) {
      _montoController.text = saldoPendiente.toStringAsFixed(2);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pago agregado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recargoPesos = _calcularRecargoPesos();
    final montoConRecargo = (double.tryParse(_montoController.text) ?? 0.0) + recargoPesos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Dropdown para seleccionar el tipo de cobro
            DropdownButtonFormField<TipoCobro>(
              value: tipoCobroSeleccionado,
              items: widget.tiposCobro.map((tipo) =>
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

            // Dropdown para seleccionar la forma de cobro
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

            // Campo para ingresar monto
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
                hintText: 'Ingresa el monto',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),

            // Mostrar recargo calculado
            if (recargoSeleccionado > 0 && (double.tryParse(_montoController.text) ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recargo: ${recargoSeleccionado}% = \$${recargoPesos.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(
                      'Total con recargo: \$${montoConRecargo.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Botón para agregar pago
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agregarPagoParcial,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Agregar pago',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}