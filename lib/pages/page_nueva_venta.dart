
import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_productos/productos_cubit.dart';
class NuevaVentaPage extends StatefulWidget {
  @override
  _NuevaVentaPageState createState() => _NuevaVentaPageState();
}

class _NuevaVentaPageState extends State<NuevaVentaPage> {
  List<Map<String, dynamic>> productosSeleccionados = [];

  void _incrementarCantidad(int index) {
    setState(() {
      productosSeleccionados[index]['cantidad']++;
    });
  }

  void _decrementarCantidad(int index) {
    setState(() {
      if (productosSeleccionados[index]['cantidad'] > 1) {
        productosSeleccionados[index]['cantidad']--;
      }
    });
  }

  void _eliminarProducto(int index) {
    setState(() {
      productosSeleccionados.removeAt(index);
    });
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      productosSeleccionados.add({
        'codigo': producto['codigo'],
        'nombre': producto['nombre'],
        'precio': producto['precio'],
        'cantidad': 1,
        'iva': 0,
        'stock': 1,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva venta'),
      ),
      body: BlocBuilder<ProductosCubit, ProductosState>(
        builder: (context, state) {
          List<Map<String, dynamic>> todosLosProductos = [];

          if (state.currentListProductCubit.isNotEmpty) {
            todosLosProductos = state.currentListProductCubit.map((producto) {
              return {
                'codigo': producto.barcode,
                'nombre': producto.name,
                'precio': producto.precioLista,
              };
            }).toList();
          }

          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Buscar cliente o cuit',
                          prefixIcon: Icon(Icons.person_search),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {},
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: Autocomplete<Map<String, dynamic>>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<Map<String, dynamic>>.empty();
                                }
                                return todosLosProductos.where((Map<String, dynamic> producto) {
                                  return producto['codigo']
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              displayStringForOption: (Map<String, dynamic> producto) =>
                              producto['codigo'],
                              onSelected: (Map<String, dynamic> selection) {
                                _agregarProducto(selection);
                              },
                              fieldViewBuilder: (BuildContext context,
                                  TextEditingController textEditingController,
                                  FocusNode focusNode,
                                  VoidCallback onFieldSubmitted) {
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar por código o Nombre del producto',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                );
                              },
                              optionsViewBuilder: (BuildContext context,
                                  AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                                  Iterable<Map<String, dynamic>> options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    child: Container(
                                      width: 300,
                                      child: ListView.builder(
                                        padding: EdgeInsets.all(8.0),
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final Map<String, dynamic> option = options.elementAt(index);
                                          return GestureDetector(
                                            onTap: () {
                                              onSelected(option);
                                            },
                                            child: ListTile(
                                              title: Text(option['codigo']),
                                              subtitle: Text(option['nombre']),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8.0),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CatalogoPage()),
                              );
                              if (result != null) {
                                _agregarProducto(result);
                              }
                            },
                            child: Text('Ver catálogo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      const Text('Lista de precios: Precio base'),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('CÓDIGO')),
                              DataColumn(label: Text('NOMBRE')),
                              DataColumn(label: Text('PRECIO')),
                              DataColumn(label: Text('CANT')),
                              DataColumn(label: Text('IVA')),
                              DataColumn(label: Text('TOTAL')),
                              DataColumn(label: Text('ACCIONES')),
                            ],
                            rows: List<DataRow>.generate(
                              productosSeleccionados.length,
                                  (index) {
                                final producto = productosSeleccionados[index];
                                final total = producto['precio'] * producto['cantidad'];
                                return DataRow(
                                  cells: [
                                    DataCell(Text(producto['codigo'])),
                                    DataCell(Text(producto['nombre'])),
                                    DataCell(Text('\$ ${producto['precio']}')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove),
                                            onPressed: () => _decrementarCantidad(index),
                                          ),
                                          Text('${producto['cantidad']}'),
                                          IconButton(
                                            icon: Icon(Icons.add),
                                            onPressed: () => _incrementarCantidad(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${producto['iva']} %')),
                                    DataCell(Text('\$ ${total.toStringAsFixed(2)}')),
                                    DataCell(
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {},
                                            child: Text('DESCUENTO'),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () => _eliminarProducto(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Nota interna',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      const TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 300,
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[200],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del contribuyente
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Monotributo - PTO: 2 - (CUIT: 20358072101 )',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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

                    // Tipo de factura
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

                    // Caja seleccionada
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

                    // Estado del pedido
                    const Text('Estado del pedido'),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Entregado'),
                    ),
                    const SizedBox(height: 16.0),

                    // Canal de venta
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

                    // Descuento
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
                    const SizedBox(height: 16.0),

                    // Resumen de venta
                    const Text('Resumen de venta'),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Table(
                        //border: TableBorder.all(), // Agrega bordes a las celdas de la tabla
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
                              SizedBox(height: 8.0), // Espacio en blanco
                              SizedBox(height: 8.0),
                            ],
                          ),
                          TableRow(
                            children: [
                              Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$0.00', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Botones de acción
                    Row(
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
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
