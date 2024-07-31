import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_thema/thema_cubit.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List<Product> products = [
    Product('Producto 1', 'assets/product1.png', 10.0, '001', 50),
    Product('Producto 2', 'assets/product2.png', 20.0, '002', 30),
    Product('Producto 3', 'assets/product3.png', 30.0, '003', 20),
    Product('Producto 4', 'assets/product4.png', 40.0, '004', 10),
    Product('Producto 5', 'assets/product5.png', 50.0, '005', 5),
  ];

  TextEditingController nameSearchController = TextEditingController();
  TextEditingController codeSearchController = TextEditingController();
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = products;
  }

  void filterProducts() {
    String nameQuery = nameSearchController.text.toLowerCase();
    String codeQuery = codeSearchController.text.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        bool matchesName = product.name.toLowerCase().contains(nameQuery);
        bool matchesCode = product.code.toLowerCase().contains(codeQuery);
        return matchesName && matchesCode;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final themeCubit = context.watch<ThemaCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Productos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: nameSearchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre',
                fillColor: themeCubit.state.isDark? Colors.black : Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                filterProducts();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: codeSearchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por código',
                fillColor: themeCubit.state.isDark? Colors.black : Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                filterProducts();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    width: screenSize.width * 0.2,
                    height: screenSize.height * 0.2,
                    child: Center(
                      child: Image.asset(
                        filteredProducts[index].image,
                        width: screenSize.width * 0.2,
                        height: screenSize.height * 0.2,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_cart, // Icono estándar
                            size: screenSize.width  * 0.05,
                            // Ajusta el tamaño del icono según sea necesario
                            color: Colors.grey, // Color del icono
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(filteredProducts[index].name),
                  subtitle: Text(
                    'Código: ${filteredProducts[index].code}\n\$${filteredProducts[index].price}\nStock: ${filteredProducts[index].stock}',
                    style: TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final String image;
  final double price;
  final String code;
  final int stock;

  Product(this.name, this.image, this.price, this.code, this.stock);
}