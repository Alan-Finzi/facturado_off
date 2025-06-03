import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:facturador_offline/pages/page_forma_cobro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../helper/database_helper.dart';
import '../models/datos_facturacion_model.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';

class VentaMainPage extends StatefulWidget {
  @override
  _VentaMainPageState createState() => _VentaMainPageState();
}

class _VentaMainPageState extends State<VentaMainPage> {
  int _currentPageIndex = 0;
  String categoriaIvaUser = 'Seleccionar';
  List<DatosFacturacionModel> datosFacturacion = [];
  bool datosCargados = false; // Variable para evitar que se recarguen los datos // Inicialmente "Seleccionar
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
    final loginCubit = context.read<LoginCubit>();

   String? userIdOrComercioId = (loginCubit.state.user!.comercioId == "1")
        ? loginCubit.state.user!.id.toString()
        : loginCubit.state.user!.comercioId;
    return SingleChildScrollView(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildDropdowns(context, userIdOrComercioId),
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

  Widget _buildDropdowns(BuildContext context, String? comercioid ) {
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

    // Obtener el comercioId del LoginCubit
    final loginCubit = context.read<LoginCubit>();
    String? userIdOrComercioId = (loginCubit.state.user!.comercioId == "1")
        ? loginCubit.state.user!.id.toString()
        : loginCubit.state.user!.comercioId;

    if (userIdOrComercioId == null) {
      // Si no tienes comercioId, manejar el caso aquí
      return Center(child: Text('No se encontró comercioId'));
    }

    // Usar un FutureBuilder para obtener los datos de facturación
    return FutureBuilder<List<DatosFacturacionModel>>(
      future: DatabaseHelper.instance.getAllDatosFacturacionCommerce(int.parse(userIdOrComercioId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());  // Cargando
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar datos'));  // Error
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay datos de facturación',style: TextStyle(color: Colors.black), ));  // No hay datos
        }

        // Aquí ya tienes los datos de facturación en snapshot.data
        final datosFacturacion = snapshot.data!;


        // Si la lista está vacía, no seleccionamos nada
        if (DatosFacturacionModel.datosFacturacionCurrent.isEmpty && datosFacturacion.isNotEmpty) {
          DatosFacturacionModel.datosFacturacionCurrent.clear();
          // Inicializamos con el primer elemento de la lista
          DatosFacturacionModel.datosFacturacionCurrent.add(datosFacturacion.first);
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Seleccione un dato de facturación:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // DropdownButton para seleccionar el dato de facturación
            dropButtonDatosFact(datosFacturacion: datosFacturacion),
            // Los dropdowns
            DropdownButton<String>(
              value: context.watch<ProductosCubit>().state.categoriaIvaUser ?? 'Seleccionar',  // Valor por defecto
              onChanged: (String? newValue) {
                if (newValue != null && newValue != 'Monotributo') {
                  // Actualiza el cubit con la nueva categoría seleccionada
                  context.read<ProductosCubit>().updateCategoriaIvaUser(newValue);
                }
              },
              items: ['Monotributo', 'Responsable Inscripto', 'Consumidor Final'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
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
      },
    );

  }

}
class dropButtonDatosFact extends StatelessWidget {
  const dropButtonDatosFact({
    super.key,
    required this.datosFacturacion,
  });

  final List<DatosFacturacionModel> datosFacturacion;

  @override
  Widget build(BuildContext context) {
    context.read<ProductosCubit>().updateDatosFacturacion([DatosFacturacionModel.datosFacturacionCurrent.first]);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DropdownButton<DatosFacturacionModel>(
        value: DatosFacturacionModel.datosFacturacionCurrent.isEmpty
            ? null
            : DatosFacturacionModel.datosFacturacionCurrent.first, // Valor seleccionado

        onChanged: (DatosFacturacionModel? selectedFactura) {
          if (selectedFactura != null) {
            // Limpiamos la lista estática y añadimos el nuevo valor
            DatosFacturacionModel.datosFacturacionCurrent.clear();
            DatosFacturacionModel.datosFacturacionCurrent.add(selectedFactura);

            // Actualizamos el estado en el ProductoCubit
            context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);
            print("Seleccionado: ${selectedFactura.razonSocial} - ${selectedFactura.condicionIva}");
          }
        },

        items: datosFacturacion.map((factura) {
          // Convertir la condicionIva a un texto legible
          String condicionIvaText = factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';

          // Devolver el DropdownMenuItem con el texto adecuado
          return DropdownMenuItem<DatosFacturacionModel>(
            value: factura,  // El valor debe ser único
            key: Key(factura.id.toString()), // Usar un valor único como clave, como el ID
            child: Text(
              '${factura.razonSocial?.isNotEmpty == true ? factura.razonSocial : 'Sin razón social'} - '
                  '${condicionIvaText}', // Usamos el texto formateado
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
            ),
          );
        }).toList(),

        isExpanded: false,
        iconSize: 20,
        style: TextStyle(fontSize: 14),
      ),
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
      child: SingleChildScrollView(
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
                  flex:2,
                  child: BuscarProductoWidget(),
                ),
                Expanded(
                  flex: 1,
                  child:     ElevatedButton(
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
                )
              ],
            ),

            const SizedBox(height: 16.0),
            const Text('Lista de precios: Precio base'),
            const SizedBox(height: 16.0),
            ListaPrecios(),
            const SizedBox(height: 16.0),
            _buildNotasYObservaciones(),
          ],
        ),
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
