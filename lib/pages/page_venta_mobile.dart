import 'package:flutter/material.dart';

import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';

class VentaMainPageMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proceso de Venta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMainContent(context),
          ),
          _buildResumenDeVenta(context),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuscarCliente(),
          const SizedBox(height: 16.0),
          BuscarProducto(),
          const SizedBox(height: 16.0),
          const Text('Lista de precios: Precio base'),
          const SizedBox(height: 16.0),
          ListaPrecios(),
          const SizedBox(height: 16.0),
          _buildNotasYObservaciones(),
        ],
      ),
    );
  }

  Widget _buildResumenDeVenta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de venta',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          ResumenTabla(),
          const SizedBox(height: 16.0),
          _buildBotonesAccion(context),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            // Lógica para cancelar
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            // Lógica para siguiente
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('SIGUIENTE'),
        ),
      ],
    );
  }

  Widget _buildNotasYObservaciones() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Nota interna',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16.0),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

// Resumen tabla widget
class ResumenTabla extends StatelessWidget {
  const ResumenTabla({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        children: const [
          TableRow(
            children: [
              Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          TableRow(
            children: [
              Text('- Descuento promociones', style: TextStyle(fontSize: 10)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          TableRow(
            children: [
              Text('- Descuento Gral (0%)', style: TextStyle(fontSize: 10)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          TableRow(
            children: [
              Text('+ Recargo (0%)', style: TextStyle(fontSize: 10)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          TableRow(
            children: [
              Text('+ IVA'),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          TableRow(
            children: [
              SizedBox(height: 8.0),
              SizedBox(height: 8.0),
            ],
          ),
          TableRow(
            children: [
              Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
        ],
      ),
    );
  }
}
