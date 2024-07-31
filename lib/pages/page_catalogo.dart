import 'package:flutter/material.dart';

class CatalogoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Buscar producto por nombre o código',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: [
                  DataTable(
                    columns: [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Precio público')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('Producto 3')),
                        DataCell(Text('PP3')),
                        DataCell(Text('\$10,000.00')),
                        DataCell(Text('Sin categoría')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'codigo': 'PP3',
                                'nombre': 'Producto 3',
                                'precio': 10000,
                              });
                            },
                            child: Text('Agregar'),
                          ),
                        ),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Producto 2')),
                        DataCell(Text('PP2')),
                        DataCell(Text('\$3,000.00')),
                        DataCell(Text('Sin categoría')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'codigo': 'PP2',
                                'nombre': 'Producto 2',
                                'precio': 3000,
                              });
                            },
                            child: Text('Agregar'),
                          ),
                        ),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Producto 1')),
                        DataCell(Text('1')),
                        DataCell(Text('\$10.00')),
                        DataCell(Text('Sin categoría')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'codigo': '1',
                                'nombre': 'Producto 1',
                                'precio': 10,
                              });
                            },
                            child: Text('Agregar'),
                          ),
                        ),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('PRODUCTO PRODUCCION')),
                        DataCell(Text('PPR')),
                        DataCell(Text('\$20,000.00')),
                        DataCell(Text('Sin categoría')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'codigo': 'PPR',
                                'nombre': 'PRODUCTO PRODUCCION',
                                'precio': 20000,
                              });
                            },
                            child: Text('Agregar'),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
