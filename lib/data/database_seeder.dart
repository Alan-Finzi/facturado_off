import 'dart:math';

import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/user.dart';

class DatabaseSeeder {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  final Random _random = Random();
  
  /// Genera un precio aleatorio menor a 1000
  double getRandomPrice() {
    return _random.nextDouble() * 999.0;
  }
  
  /// Genera un stock aleatorio entre 1 y 100
  int getRandomStock() {
    return _random.nextInt(99) + 1; // Entre 1 y 100
  }
  
  Future<void> seedDatabase() async {
    final db = await dbHelper.database;
    
    try {
      // Buscar productos existentes y actualizar precios aleatorios
      final List<Map<String, dynamic>> productos = await db.query('product');
      
      if (productos.isEmpty) {
        throw Exception('No se encontraron productos en la base de datos');
      }
      
      // Para cada producto, actualizar sus precios en las listas
      for (var producto in productos) {
        final productId = producto['id'];
        
        // Verificar si el producto está eliminado
        if (producto['eliminado'] == 1) continue;
        
        // Encontrar listas de precios existentes
        final List<Map<String, dynamic>> listasPrecios = await db.query(
          'lista',
          columns: ['id', 'nombre']
        );
        
        if (listasPrecios.isEmpty) {
          print('No se encontraron listas de precios');
          continue;
        }
        
        // Para cada lista de precios, actualizar o insertar precio para este producto
        for (var lista in listasPrecios) {
          final listaId = lista['id'];
          final randomPrice = getRandomPrice();
          
          // Verificar si ya existe un precio para este producto en esta lista
          final List<Map<String, dynamic>> existingPrecios = await db.query(
            'productos_lista_precios',
            where: 'product_id = ? AND lista_id = ?',
            whereArgs: [productId, listaId]
          );
          
          if (existingPrecios.isNotEmpty) {
            // Actualizar precio existente
            await db.update(
              'productos_lista_precios',
              {'precio_lista': randomPrice},
              where: 'product_id = ? AND lista_id = ?',
              whereArgs: [productId, listaId]
            );
            print('Actualizado precio para producto $productId en lista $listaId: $randomPrice');
          } else {
            // Insertar nuevo precio
            await db.insert('productos_lista_precios', {
              'product_id': productId,
              'referencia_variacion': 'Var1',
              'lista_id': listaId,
              'precio_lista': randomPrice,
              'comercio_id': 1,
              'eliminado': 0,
            });
            print('Insertado nuevo precio para producto $productId en lista $listaId: $randomPrice');
          }
        }
        
        // Actualizar stock
        final randomStock = getRandomStock();
        
        // Verificar si ya existe un stock para este producto
        final List<Map<String, dynamic>> existingStocks = await db.query(
          'productos_stock_sucursales',
          where: 'product_id = ?',
          whereArgs: [productId]
        );
        
        if (existingStocks.isNotEmpty) {
          // Actualizar stock existente
          await db.update(
            'productos_stock_sucursales',
            {'stock': randomStock, 'stock_real': randomStock},
            where: 'product_id = ?',
            whereArgs: [productId]
          );
          print('Actualizado stock para producto $productId: $randomStock');
        } else {
          // Insertar nuevo stock
          await db.insert('productos_stock_sucursales', {
            'product_id': productId,
            'referencia_variacion': 'Var1',
            'comercio_id': 1,
            'sucursal_id': 1,
            'almacen_id': 1,
            'stock': randomStock,
            'stock_real': randomStock,
            'eliminado': 0,
          });
          print('Insertado nuevo stock para producto $productId: $randomStock');
        }
      }
      
      print('Actualización de precios y stocks completada con éxito');
      
    } catch (e) {
      print('Error al actualizar precios y stocks: $e');
      rethrow;
    }
  }
}