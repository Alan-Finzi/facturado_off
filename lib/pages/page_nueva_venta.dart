import 'package:facturador_offline/bloc/cubit_resumen/resumen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';


class NuevaVentaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva venta'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
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
            ),
          ),
          _buildResumenDeVenta(),
        ],
      ),
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

  Widget _buildResumenDeVenta() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del contribuyente
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Monotributo - PTO: 2 - (CUIT: 20358072101)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _buildDropdowns(),
          const SizedBox(height: 16.0),
          const Text('Resumen de venta'),
          _buildResumenTabla(),
          const SizedBox(height: 16.0),
          _buildBotonesAccion(),
        ],
      ),
    );
  }

  Widget _buildDropdowns() {
    return Column(
      children: [
        DropdownButton<String>(
          value: 'Monotributo',
          onChanged: (String? newValue) {},
          items: <String>['Monotributo', 'Responsable Inscripto', 'Consumidor Final']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 16.0),
        DropdownButton<String>(
          value: 'Factura C',
          onChanged: (String? newValue) {},
          items: <String>['Factura A', 'Factura B', 'Factura C', 'Consumidor final']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 16.0),
        DropdownButton<String>(
          value: 'Caja seleccionada: # 3',
          onChanged: (String? newValue) {},
          items: <String>['Caja seleccionada: # 1', 'Caja seleccionada: # 2', 'Caja seleccionada: # 3']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 16.0),
        const Text('Estado del pedido'),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Entregado'),
        ),
        const SizedBox(height: 16.0),
        const Text('Canal de venta'),
        DropdownButton<String>(
          value: 'Mostrador',
          onChanged: (String? newValue) {},
          items: <String>['Mostrador', 'Online', 'Teléfono']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 16.0),
        const Text('Descuento'),
        const Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  suffixText: '%',
                  prefixIcon: Icon(Icons.discount),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResumenTabla() {
    return ResumenTabla();
  }

  Widget _buildBotonesAccion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('CANCELAR'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('SIGUIENTE'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}

class ResumenTabla extends StatelessWidget {
  const ResumenTabla({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<ResumenCubit, ResumenState>(
  builder: (context, state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        //border: TableBorder.all(), // Agrega bordes a las celdas de la tabla
        children:  [
          const TableRow(
            children: [
              Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$0.00', textAlign: TextAlign.right),
            ],
          ),
          const TableRow(
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
              SizedBox(height: 8.0), // Espacio en blanco
              SizedBox(height: 8.0),
            ],
          ),
          TableRow(
            children: [
              Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$ ${state.totalFacturar}', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  },
);
  }
}
