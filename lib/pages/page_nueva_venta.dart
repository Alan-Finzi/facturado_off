import 'package:facturador_offline/pages/page_catalogo.dart';
import 'package:flutter/material.dart';

class NuevaVentaPage extends StatefulWidget {
  @override
  _NuevaVentaPageState createState() => _NuevaVentaPageState();
}

class _NuevaVentaPageState extends State<NuevaVentaPage> {
  List<Map<String, dynamic>> productosSeleccionados = [
    {
      'codigo': 'PP2',
      'nombre': 'Producto 2',
      'precio': 3000,
      'cantidad': 1,
      'iva': 0,
      'stock': 6,
    },
    {
      'codigo': '60x69epamamo',
      'nombre': 'Medallon La Conquista 60 x 69 gr con pan + 1 mayonesa + 1 mostaza',
      'precio': 27800,
      'cantidad': 1,
      'iva': 0,
      'stock': 1,
    },
  ];

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
      body: Row(
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
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Cod. producto',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Buscar por nombre',
                            prefixIcon: Icon(Icons.list),
                          ),
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
                  SizedBox(height: 16.0),
                  Text('Lista de precios: Precio base'),
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
                  TextField(
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
                SizedBox(height: 16.0),
                Text('Canal de venta'),
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
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Total',
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Generar venta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}