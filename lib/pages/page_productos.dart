import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_thema/thema_cubit.dart';

import '../helper/database_helper.dart';
class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({Key? key}) : super(key: key);

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
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
                            Icons.shopping_cart,
                            size: screenSize.width * 0.05,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(filteredProducts[index].name),
                  subtitle: Text(
                    'Código: ${filteredProducts[index].code}\n\$${filteredProducts[index].price}\nStock: ${filteredProducts[index].stock}',
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
