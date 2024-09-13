import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Productos"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "CATÁLOGO"),
            Tab(text: "PRECIOS"),
            Tab(text: "STOCK"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(), // CATÁLOGO
          _buildProductList(), // PRECIOS (Puedes cambiar el contenido aquí si es diferente)
          _buildProductList(), // STOCK
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: [
        _buildFilterAndSearch(),
        _buildTableHeader(),
        Expanded(
          child: ListView(
            children: _buildProductRows(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.filter_list),
            label: Text('Filtros'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Buscar...',
              ),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {},
            child: Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (bool? value) {}),
          _buildTableHeaderCell('Nombre del producto', flex: 2),
          _buildTableHeaderCell('SKU', flex: 1),
          _buildTableHeaderCell('Precio', flex: 1),
          _buildTableHeaderCell('Precio Lista mayorista', flex: 2),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildProductRows() {
    final products = [
      {'name': 'BICICLETA 1', 'sku': '77123998871B1', 'price': 15000, 'wholesalePrice': 0},
      {'name': 'BICICLETA 2', 'sku': '77123998871B2', 'price': 35200, 'wholesalePrice': 0},
      {'name': 'BICICLETA 3', 'sku': '77123998871B3', 'price': 22000, 'wholesalePrice': 0},
      {'name': 'BICICLETA 4', 'sku': '77123998871B4', 'price': 31901, 'wholesalePrice': 0},
    ];

    return products.map((product) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(value: false, onChanged: (bool? value) {}),
            _buildProductRowCell(
              const Icon(Icons.add, size: 20),
              flex: 2,
              text: product['name'].toString(),
            ),
            _buildProductRowCell(Text(product['sku'].toString()), flex: 1),
            _buildProductRowCell(Text('\$${product['price']}.00'), flex: 1),
            _buildProductRowCell(Text('\$${product['wholesalePrice']}.00'), flex: 2),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildProductRowCell(Widget content, {int flex = 1, String? text}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: content,
            ),
          if (text != null)
            Text(text),
          if (text == null) content,
        ],
      ),
    );
  }
}