import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_thema/thema_cubit.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> products = [
    Product('Producto 1', 'assets/product1.png', 10.0),
    Product('Producto 2', 'assets/product2.png', 20.0),
    Product('Producto 3', 'assets/product3.png', 30.0),
    Product('Producto 5', 'assets/product3.png', 30.0),
    Product('Producto 6', 'assets/product3.png', 30.0),
    Product('Producto 7', 'assets/product3.png', 30.0),
  ];
  double precioEstimado =0;
  int cartCount = 0;
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final themeCubit = context.watch<ThemaCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
              Positioned(
                right: 7,
                top: 7,
                child: cartCount > 0
                    ? Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    : Container(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration:  InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar productos',
                fillColor: themeCubit.state.isDark? Colors.black : Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  // Implementar lógica de búsqueda aquí
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    child: Image.asset(
                      products[index].image,
                      width: screenSize.width * 0.2,
                      height: screenSize.height * 0.2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_cart, // Icono estándar
                          size: screenSize.width  * 0.1,
                          // Ajusta el tamaño del icono según sea necesario
                          color: Colors.grey, // Color del icono
                        );
                      },
                    ),
                  ),
                  title: Text(products[index].name),
                  subtitle: Text('\$${products[index].price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (products[index].quantity > 0) {
                              products[index].quantity--;
                            precioEstimado = precioEstimado- products[index].price;
                            }
                          });
                        },
                      ),
                      Text('${products[index].quantity}'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            products[index].quantity++;
                            precioEstimado = precioEstimado+ products[index].price;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cartCount += products.where((p) => p.quantity > 0).length;
                    });
                  },
                  child: Text('Agregar al carrito'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cartCount += products.where((p) => p.quantity > 0).length;
                    });
                  },
                  child: Text('Precio Estimado : $precioEstimado' ),
                ),
              ),

            ],
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
  int quantity;

  Product(this.name, this.image, this.price, {this.quantity = 0});
}