import 'dart:math';

import '../helper/database_helper.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';

class DatabaseSeeder {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  final Random _random = Random();
  
  /// Genera un precio aleatorio entre 500 y 5000
  double getRandomPrice() {
    return 500.0 + (_random.nextDouble() * 4500.0);
  }
  
  /// Genera un stock aleatorio entre 10 y 500
  int getRandomStock() {
    return _random.nextInt(490) + 10; // Entre 10 y 500
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
      
      // Crear una nueva lista de precios, cliente y productos con ID > 100
      await createNewEntities();
      
      print('Actualización de precios y stocks completada con éxito');
      
    } catch (e) {
      print('Error al actualizar precios y stocks: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva lista de precios, cliente y productos con IDs > 100
  Future<void> createNewEntities() async {
    final db = await dbHelper.database;
    
    try {
      print('Creando nuevas entidades con IDs > 100...');
      
      // 1. Crear una nueva lista de precios con ID > 100
      final nuevaListaId = 101;
      final nombreListaNueva = 'Lista Premium';
      
      // Verificar si la lista ya existe
      final List<Map<String, dynamic>> listaExistente = await db.query(
        'lista',
        where: 'id = ?',
        whereArgs: [nuevaListaId]
      );
      
      if (listaExistente.isEmpty) {
        // Insertar la nueva lista
        await db.insert('lista', {
          'id': nuevaListaId,
          'nombre': nombreListaNueva
        });
        print('Creada nueva lista de precios con ID: $nuevaListaId');
      } else {
        // Actualizar la lista existente
        await db.update('lista', 
          {'nombre': nombreListaNueva},
          where: 'id = ?',
          whereArgs: [nuevaListaId]
        );
        print('Actualizada lista de precios existente con ID: $nuevaListaId');
      }
      
      // 2. Crear un nuevo cliente asociado a la nueva lista de precios
      final nuevoClienteId = '101';
      
      // Verificar si el cliente ya existe
      final List<Map<String, dynamic>> clienteExistente = await db.query(
        'Clientes_mostrador',
        where: 'id_cliente = ?',
        whereArgs: [nuevoClienteId]
      );
      
      if (clienteExistente.isEmpty) {
        // Insertar el nuevo cliente
        await db.insert('Clientes_mostrador', {
          'id': 101,
          'creador_id': 1,
          'id_cliente': nuevoClienteId,
          'nombre': 'Cliente Premium',
          'sucursal_id': 1,
          'lista_precio': nuevaListaId,  // Asociar a la nueva lista
          'comercio_id': 1,
          'plazo_cuenta_corriente': 30,
          'monto_maximo_cuenta_corriente': 50000.0,
          'saldo_inicial_cuenta_corriente': 0.0,
          'pais': 'Argentina',
          'codigo_postal': '1000',
          'direccion': 'Av. Premium 123',
          'localidad': 'CABA',
          'provincia': 'Buenos Aires',
          'eliminado': 0,
          'email': 'cliente.premium@example.com',
          'telefono': '+54911123456',
          'dni': '30123456',
          'activo': 1,
          'modificado': 0
        });
        print('Creado nuevo cliente con ID: $nuevoClienteId asociado a la lista de precios $nuevaListaId');
      } else {
        // Actualizar el cliente existente
        await db.update('Clientes_mostrador', 
          {
            'nombre': 'Cliente Premium',
            'lista_precio': nuevaListaId,
            'email': 'cliente.premium@example.com',
            'activo': 1
          },
          where: 'id_cliente = ?',
          whereArgs: [nuevoClienteId]
        );
        print('Actualizado cliente existente con ID: $nuevoClienteId');
      }
      
      // 3. Crear nuevos productos con ID > 100
      for (int i = 1; i <= 5; i++) {
        final nuevoProductoId = 100 + i;
        final nombreProducto = 'Producto Premium $i';
        final barcode = 'PREM$i${nuevoProductoId}';
        
        // Verificar si el producto ya existe
        final List<Map<String, dynamic>> productoExistente = await db.query(
          'product',
          where: 'id = ?',
          whereArgs: [nuevoProductoId]
        );
        
        if (productoExistente.isEmpty) {
          // Insertar el nuevo producto
          await db.insert('product', {
            'id': nuevoProductoId,
            'name': nombreProducto,
            'barcode': barcode,
            'tipo_producto': 's',
            'producto_tipo': 's',
            'category_id': 1,
            'comercio_id': 1,
            'eliminado': 0
          });
          print('Creado nuevo producto con ID: $nuevoProductoId');
          
          // 4. Asignar stock al nuevo producto
          final randomStock = getRandomStock();
          await db.insert('productos_stock_sucursales', {
            'product_id': nuevoProductoId,
            'referencia_variacion': 'Var1',
            'comercio_id': 1,
            'sucursal_id': 1,
            'almacen_id': 1,
            'stock': randomStock,
            'stock_real': randomStock,
            'eliminado': 0,
          });
          print('Asignado stock ($randomStock) al producto $nuevoProductoId');
          
          // 5. Asignar precio al producto en la nueva lista de precios
          final randomPrice = getRandomPrice();
          await db.insert('productos_lista_precios', {
            'product_id': nuevoProductoId,
            'referencia_variacion': 'Var1',
            'lista_id': nuevaListaId,
            'precio_lista': randomPrice,
            'comercio_id': 1,
            'eliminado': 0,
          });
          print('Asignado precio ($randomPrice) al producto $nuevoProductoId en lista $nuevaListaId');
        } else {
          // Actualizar el producto existente
          await db.update('product', 
            {'name': nombreProducto, 'barcode': barcode},
            where: 'id = ?',
            whereArgs: [nuevoProductoId]
          );
          print('Actualizado producto existente con ID: $nuevoProductoId');
          
          // Actualizar stock
          final randomStock = getRandomStock();
          final List<Map<String, dynamic>> stockExistente = await db.query(
            'productos_stock_sucursales',
            where: 'product_id = ?',
            whereArgs: [nuevoProductoId]
          );
          
          if (stockExistente.isEmpty) {
            await db.insert('productos_stock_sucursales', {
              'product_id': nuevoProductoId,
              'referencia_variacion': 'Var1',
              'comercio_id': 1,
              'sucursal_id': 1,
              'almacen_id': 1,
              'stock': randomStock,
              'stock_real': randomStock,
              'eliminado': 0,
            });
          } else {
            await db.update(
              'productos_stock_sucursales',
              {'stock': randomStock, 'stock_real': randomStock},
              where: 'product_id = ?',
              whereArgs: [nuevoProductoId]
            );
          }
          print('Actualizado stock ($randomStock) para producto $nuevoProductoId');
          
          // Actualizar precio
          final randomPrice = getRandomPrice();
          final List<Map<String, dynamic>> precioExistente = await db.query(
            'productos_lista_precios',
            where: 'product_id = ? AND lista_id = ?',
            whereArgs: [nuevoProductoId, nuevaListaId]
          );
          
          if (precioExistente.isEmpty) {
            await db.insert('productos_lista_precios', {
              'product_id': nuevoProductoId,
              'referencia_variacion': 'Var1',
              'lista_id': nuevaListaId,
              'precio_lista': randomPrice,
              'comercio_id': 1,
              'eliminado': 0,
            });
          } else {
            await db.update(
              'productos_lista_precios',
              {'precio_lista': randomPrice},
              where: 'product_id = ? AND lista_id = ?',
              whereArgs: [nuevoProductoId, nuevaListaId]
            );
          }
          print('Actualizado precio ($randomPrice) para producto $nuevoProductoId en lista $nuevaListaId');
        }
      }
      
      print('Creación de nuevas entidades completada con éxito');
      
    } catch (e) {
      print('Error al crear nuevas entidades: $e');
      rethrow;
    }
  }
}