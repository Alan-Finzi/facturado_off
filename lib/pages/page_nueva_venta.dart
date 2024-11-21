import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:facturador_offline/pages/page_forma_cobro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';

class VentaMainPage extends StatefulWidget {
  @override
  _VentaMainPageState createState() => _VentaMainPageState();
}

class _VentaMainPageState extends State<VentaMainPage> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    const NuevaVentaPage(),
    FormaCobroPage(
      onBackPressed: () {
        // Regresar a la página anterior
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proceso de Venta'),
      ),
      body: Row(
        children: [
          Expanded(
            child: _pages[_currentPageIndex],
          ),
          _buildResumenDeVenta(context),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  Widget _buildResumenDeVenta(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const ResumenTabla(),
            const SizedBox(height: 16.0),
            _buildBotonesAccion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _navigateToPage(0),// Cancelar
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () => _navigateToPage(1), // Siguiente
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('SIGUIENTE'),
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    const List<String> categories = [
      'Monotributo',
      'Responsable Inscripto',
      'Consumidor Final'
    ];

    const List<String> invoices = ['Factura A', 'Factura B', 'Factura C'];
    const List<String> cashRegisters = [
      'Caja seleccionada: # 1',
      'Caja seleccionada: # 2',
      'Caja seleccionada: # 3'
    ];
    const List<String> salesChannels = ['Mostrador', 'Online', 'Teléfono'];

    return Column(
      children: [
        DropdownButton<String>(
          value: categories[0],
          onChanged: (String? newValue) {},
          items: categories
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
        ),
        const SizedBox(height: 16.0),
        DropdownButton<String>(
          value: invoices[2],
          onChanged: (String? newValue) {},
          items: invoices
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
        ),
        const SizedBox(height: 16.0),
        DropdownButton<String>(
          value: cashRegisters[2],
          onChanged: (String? newValue) {},
          items: cashRegisters
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
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
          value: salesChannels[0],
          onChanged: (String? newValue) {},
          items: salesChannels
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
        ),
        const SizedBox(height: 16.0),
        const Text('Descuento'),
        const TextField(
          decoration: InputDecoration(
            suffixText: '%',
            prefixIcon: Icon(Icons.discount),
          ),
        ),
      ],
    );
  }
}

// Página de nueva venta
class NuevaVentaPage extends StatelessWidget {
  const NuevaVentaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuscarClienteWidget(),
          const SizedBox(height: 16.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: BuscarProductoScanner(),
              ),
              const SizedBox(width: 8.0), // Espaciado entre widgets
              Expanded(
                flex: 1,
                child: BuscarProductoWidget(),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CatalogoPage()),
              );
              if (result != null) {
                context.read<ProductosCubit>().agregarProducto(result);
              }
            },
            child: const Text('Ver catálogo'),
          ),
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
    return BlocBuilder<ResumenCubit, ResumenState>(
      builder: (context, state) {
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
      },
    );
  }
}
