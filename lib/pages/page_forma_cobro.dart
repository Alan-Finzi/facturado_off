import 'package:flutter/material.dart';
import '../widget/buscar_cliente.dart';

class FormaCobroPage extends StatefulWidget {
  final VoidCallback onBackPressed; // Callback para manejar el botón "Anterior"

  FormaCobroPage({required this.onBackPressed});

  @override
  _FormaCobroPageState createState() => _FormaCobroPageState();
}

class _FormaCobroPageState extends State<FormaCobroPage> {
  bool isPagoParcial = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forma de Cobro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              style: TextStyle(fontWeight: FontWeight.bold),
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
                    child: Text('Pago total'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isPagoParcial ? Colors.grey : null,
                    ),
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
                    child: Text('Pago parcial / pago dividido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPagoParcial ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            if (isPagoParcial)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agregar Método de Pago
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '+ Agregar Método de Pago',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  const Row(
                    children: [
                      // Monto Total
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Monto Total',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16.0),
                      // A Cobrar Total
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'A cobrar total',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text('Deuda: \$ 0,00'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monto a Pagar
                  TextField(
                    decoration: InputDecoration(
                      labelText:
                      'Ingresa el monto con el que va a pagar tu cliente',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Vuelto a entregar',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ],
              ),
            SizedBox(height: 16.0),

            // Sección Tipo de Envío
            Text(
              'Tipo de envío',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            CheckboxListTile(
              value: true,
              onChanged: (bool? value) {},
              title: Text('Retiro por sucursal'),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (bool? value) {},
              title: Text('Envío a domicilio del cliente'),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (bool? value) {},
              title: Text('Envío a otro domicilio'),
            ),
            Spacer(),

            // Botones Anterior y Guardar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onBackPressed, // Usamos el callback aquí
                  child: Text('Anterior'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}