import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:facturador_offline/pages/page_forma_cobro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_state.dart';
import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_productos/productos_cubit.dart';
import '../bloc/cubit_resumen/resumen_cubit.dart';
import '../helper/database_helper.dart';
import '../models/datos_facturacion_model.dart';
import '../widget/buildDropdowns.dart';
import '../widget/buscar_cliente.dart';
import '../widget/buscar_productos.dart';
import '../widget/listado_precios.dart';
import '../widget/resumen_widget.dart';

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

            VentaDropdownsWidget(comercioId: userIdOrComercioId!),
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


}
class dropButtonDatosFact extends StatelessWidget {
  const dropButtonDatosFact({
    super.key,
    required this.datosFacturacion,
  });

  final List<DatosFacturacionModel> datosFacturacion;

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que el valor actual exista en la lista
    DatosFacturacionModel? selected = DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty
        ? DatosFacturacionModel.datosFacturacionCurrent.first
        : null;

    // Si el valor actual no está en la lista, agregarlo
    if (selected != null && !datosFacturacion.contains(selected)) {
      selected = null;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DropdownButton<DatosFacturacionModel>(
        value: selected,
        onChanged: (DatosFacturacionModel? selectedFactura) {
          if (selectedFactura != null) {
            DatosFacturacionModel.datosFacturacionCurrent
              ..clear()
              ..add(selectedFactura);

            context.read<ProductosCubit>().updateDatosFacturacion([selectedFactura]);

            print("Seleccionado: ${selectedFactura.razonSocial} - ${selectedFactura.condicionIva}");
          }
        },
        items: datosFacturacion.map((factura) {
          String condicionIvaText = factura.condicionIva?.toString().split('.').last ?? 'IVA: No disponible';
          return DropdownMenuItem<DatosFacturacionModel>(
            value: factura,
            key: Key(factura.id.toString()),
            child: Text(
              '${factura.razonSocial?.isNotEmpty == true ? factura.razonSocial : 'Sin razón social'} - $condicionIvaText',
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
            // Usamos dos BlocBuilders anidados para asegurar que siempre tenemos la información más actualizada
            BlocBuilder<ClientesMostradorCubit, ClientesMostradorState>(
              buildWhen: (previous, current) => previous.clienteSeleccionado?.listaPrecio != current.clienteSeleccionado?.listaPrecio,
              builder: (context, clienteState) {
                // BlocBuilder anidado para acceder también a la información de las listas de precios
                return BlocBuilder<ListaPreciosCubit, ListaPreciosState>(
                  builder: (context, listasState) {
                    // Por defecto, mostrar 'Precio base'
                    String listaPrecioNombre = 'Precio base';
                    
                    // Si hay un cliente seleccionado, intentar obtener el nombre de su lista de precios
                    if (clienteState.clienteSeleccionado != null && clienteState.clienteSeleccionado!.listaPrecio != null) {
                      final listaId = clienteState.clienteSeleccionado!.listaPrecio!;
                      
                      try {
                        // Buscar la lista de precios por su ID
                        final listaDelCliente = listasState.currentList.firstWhere(
                          (lista) => lista.id == listaId,
                        );
                        
                        if (listaDelCliente.nombre != null) {
                          listaPrecioNombre = listaDelCliente.nombre!;
                          print('Mostrando lista: ${listaDelCliente.nombre} (ID: ${listaDelCliente.id})');
                        }
                      } catch (e) {
                        print('Lista de precio no encontrada: $e');
                      }
                    }
                    
                    return Text('Lista de precios: $listaPrecioNombre');
                  },
                );
              },
            ),
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
