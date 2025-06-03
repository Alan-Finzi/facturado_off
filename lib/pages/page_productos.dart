import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_thema/thema_cubit.dart';

import '../helper/database_helper.dart';
import '../models/productos_maestro.dart';
class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({Key? key}) : super(key: key);

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List products = [];
  List filteredProducts = [];
  TextEditingController nameSearchController = TextEditingController();
  TextEditingController codeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void loadProducts() async {
    products = await DatabaseHelper.instance.getProducts();
    setState(() {
      filteredProducts = products;
    });
  }

  void filterProducts() {
    String nameQuery = nameSearchController.text.toLowerCase();
    String codeQuery = codeSearchController.text.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        bool matchesName = product.name!.toLowerCase().contains(nameQuery);
        bool matchesCode = product.barcode!.toLowerCase().contains(codeQuery);
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
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre',
                fillColor: themeCubit.state.isDark ? Colors.black : Colors.white,
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
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por código',
                fillColor: themeCubit.state.isDark ? Colors.black : Colors.white,
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
                  title: Text(filteredProducts[index].name!),
                  subtitle: Text(
                    'Código: ${filteredProducts[index].barcode}\nStock: ${filteredProducts[index].stocks}',
                    style: TextStyle(
                      color: themeCubit.state.isDark ? Colors.white : Colors.black,
                    ),
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
