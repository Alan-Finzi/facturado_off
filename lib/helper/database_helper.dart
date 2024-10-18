import 'package:sqflite/sqflite.dart';

import '../models/Producto_precio_stock.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';
import 'package:path/path.dart';



class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabaseIfExists() async {
    String path = join(await getDatabasesPath(), 'flaminco_appv1_DB.db');
    await deleteDatabase(path);
  }
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flaminco_appv1_DB.db');
    print('La base de datos se guarda en la siguiente ruta: $path');
    return await openDatabase(
      path,
      version: 18,
      onCreate: (db, version) async {
        // Crear tablas
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT ,
          nombre_usuario TEXT,
          apellido_usuario TEXT,
          cantidad_sucursales INTEGER,
          cantidad_empleados INTEGER,
          name TEXT,
          sucursal INTEGER,
          email TEXT,
          profile TEXT,
          status TEXT,
          external_auth TEXT,
          external_id TEXT,
          email_verified_at TEXT,
          confirmed_at TEXT,
          plan INTEGER,
          last_login TEXT,
          cantidad_login INTEGER,
          comercio_id INTEGER,
          cliente_id INTEGER,
          image TEXT,
          casa_central_user_id INTEGER,
          id_lista_precio INTEGER
        )
      ''');

        await db.execute('''
        CREATE TABLE productos(
          id INTEGER,
          producto_id INTEGER,
          name TEXT,
          tipo_producto TEXT,
          producto_tipo TEXT,
          precio_interno REAL,
          barcode TEXT,
          cost REAL,
          alerts REAL,
          image TEXT,
          category_id INTEGER,
          marca_id INTEGER,
          comercio_id INTEGER,
          stock_descubierto TEXT,
          proveedor_id INTEGER,
          eliminado INTEGER,
          unidad_medida INTEGER,
          wc_product_id INTEGER,
          wc_push INTEGER,
          wc_image TEXT,
          etiquetas TEXT,
          mostrador_canal INTEGER,
          ecommerce_canal INTEGER,
          wc_canal INTEGER,
          descripcion TEXT,
          receta_id INTEGER
        )
      ''');

        await db.execute('''
        CREATE TABLE lista_precios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT,
          comercio_id INTEGER,
          descripcion TEXT,
          eliminado INTEGER,
          wc_key TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE Clientes_mostrador(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          creador_id INTEGER,
          id_cliente TEXT,
          activo INTEGER,
          nombre TEXT,
          sucursal_id INTEGER,
          lista_precio INTEGER,
          comercio_id INTEGER,
          last_sale TEXT,
          recontacto TEXT,
          plazo_cuenta_corriente INTEGER,
          monto_maximo_cuenta_corriente REAL,
          saldo_inicial_cuenta_corriente REAL,
          fecha_inicial_cuenta_corriente TEXT,
          pais TEXT,
          codigo_postal TEXT,
          depto TEXT,
          piso TEXT,
          altura TEXT,
          eliminado INTEGER,
          email TEXT,
          telefono TEXT,
          observaciones TEXT,
          localidad TEXT,
          barrio TEXT,
          provincia TEXT,
          direccion TEXT,
          dni TEXT,
          status TEXT,
          image TEXT,
          wc_customer_id TEXT
        )
      ''');

        // Crear la tabla productos_stock_sucursales
        await db.execute('''
        CREATE TABLE productos_stock_sucursales(
          product_id INTEGER,
          referencia_variacion TEXT,
          comercio_id INTEGER,
          sucursal_id INTEGER,
          almacen_id INTEGER,
          stock INTEGER,
          stock_real INTEGER,
          eliminado INTEGER,
          PRIMARY KEY (product_id, referencia_variacion, comercio_id, sucursal_id, almacen_id)
        )
      ''');
        await db.execute('''
        CREATE TABLE productos_lista_precios(
        product_id INTEGER,
        referencia_variacion TEXT,
        lista_id INTEGER,
        precio_lista REAL,
        comercio_id INTEGER,
        eliminado INTEGER,
        PRIMARY KEY (product_id, referencia_variacion, lista_id, comercio_id)
       )
      ''');

        await db.execute('''
CREATE TABLE categorias(
  id INTEGER PRIMARY KEY,
  comercio_id TEXT,
  name TEXT,
  image TEXT,
  wc_category_id TEXT,
  eliminado INTEGER,
  created_at TEXT,
  updated_at TEXT
)
''');
// Crear la tabla productos_ivas actualizada
        await db.execute('''
CREATE TABLE productos_ivas(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,       -- ID del producto
  comercio_id INTEGER,       -- ID de la casa central
  sucursal_id INTEGER,       -- ID de la sucursal
  iva REAL,                  -- IVA en decimales (ej. 0.21 para 21%)
  porcentaje REAL            -- Porcentaje del IVA en decimales
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE Clientes_mostrador ADD COLUMN creador_id INTEGER');
        }
      },
    );
  }

  // Métodos relacionados con la tabla users
  Future<User?> getUser(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }


  // Métodos relacionados con la tabla users
  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<List<User>> getUsers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  // Métodos relacionados con la tabla productos
  Future<void> insertProducto(ProductoModel producto) async {
    Database db = await database;
    await db.insert(
      'productos',
      producto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<void> insertProductos(List<ProductoModel> productos) async {
    for (var producto in productos) {
      await insertProducto(producto);
    }
  }
  Future<List<ProductoModel>> getProductos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');
    return List.generate(maps.length, (i) => ProductoModel.fromMap(maps[i]));
  }

  // Métodos relacionados con la tabla categorias
  Future<void> insertCategoria(CategoriaModel categoria) async {
    Database db = await database;
    await db.insert(
      'categorias',
      categoria.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCategorias(List<CategoriaModel> categorias) async {
    for (var categoria in categorias) {
      if(categoria.eliminado ==0){
        await insertCategoria(categoria);
      }
    }
  }

  Future<List<CategoriaModel>> getCategorias() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorias');
    return List.generate(maps.length, (i) => CategoriaModel.fromJson(maps[i]));
  }
  // Métodos relacionados con la tabla lista_precios
  Future<void> insertListaPrecio(ListaPreciosModel listaPrecio) async {
    Database db = await database;
    await db.insert(
      'lista_precios',
      listaPrecio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertListaPrecios(List<ListaPreciosModel> listaPrecios) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var listaPrecio in listaPrecios) {
        await txn.insert(
          'lista_precios',
          listaPrecio.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }


  Future<List<ListaPreciosModel>> getListaPrecios() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lista_precios');
    return List.generate(maps.length, (i) => ListaPreciosModel.fromMap(maps[i]));
  }

  Future<void> deleteListaPrecio(int id) async {
    Database db = await database;
    await db.delete(
      'lista_precios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos relacionados con la tabla Clientes_mostrador
  Future<void> insertCliente(ClientesMostrador cliente) async {
    Database db = await database;
    await db.insert(
      'Clientes_mostrador',
      cliente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCliente(ClientesMostrador cliente) async {
    Database db = await database;
    await db.update(
      'Clientes_mostrador',
      cliente.toMap(),
      where: 'id_cliente = ?',
      whereArgs: [cliente.idCliente],
    );
  }

  Future<void> deleteCliente(String idCliente) async {
    Database db = await database;
    await db.delete(
      'Clientes_mostrador',
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
    );
  }

  Future<List<ClientesMostrador>> getClientesDB() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Clientes_mostrador');
    return List.generate(maps.length, (i) => ClientesMostrador.fromJson(maps[i]));
  }

  // Métodos relacionados con la tabla productos_stock_sucursales
  Future<void> insertProductosStockSucursal(ProductosStockSucursalesModel productoStockSucursal) async {
    final db = await database;
    await db.insert(
      'productos_stock_sucursales',
      productoStockSucursal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // Método para insertar una lista de productos en productos_stock_sucursales
  Future<void> insertProductosStockSucursales(List<ProductosStockSucursalesModel> productosStockSucursales) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var productoStockSucursal in productosStockSucursales) {
        await txn.insert(
          'productos_stock_sucursales',
          productoStockSucursal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<ProductosStockSucursalesModel>> getProductosStockSucursales({ required int sucursalId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos_stock_sucursales',
      where: 'sucursal_id = ?', // Condición para filtrar por sucursal
      whereArgs: [sucursalId], // Argumento para la condición
    );
    return List.generate(maps.length, (i) => ProductosStockSucursalesModel.fromMap(maps[i]));
  }

  Future<List<ProductoConPrecioYStock>> getProductosConPrecioYStockQuery(
      {required int sucursalId,required int listaId}) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
    p.barcode AS barcode,
    p.id AS productId,
    p.name AS productName,
    p.tipo_producto AS productType,
    pss.stock AS stock,
    plp.precio_lista AS precioLista,
    c.name AS categoryName  
FROM 
    productos p
INNER JOIN 
    productos_stock_sucursales pss ON p.id = pss.product_id
INNER JOIN 
    productos_lista_precios plp ON p.id = plp.product_id
INNER JOIN
    categorias c ON p.category_id = c.id
WHERE 
    pss.sucursal_id = ? 
    AND plp.lista_id = ?  
    AND pss.stock > 0
  ''', [sucursalId, listaId]);

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ProductoConPrecioYStock(
        producto: ProductoModel(
          id: map['productId'],
          name: map['productName'],
          tipoProducto: map['productType'],
          barcode:  map['barcode']
          // Agrega otros campos necesarios...
        ),
        precioLista: map['precioLista'] as double?,
        stock: map['stock'] is int
            ? (map['stock'] as int).toDouble()  // Si es int, conviértelo a double
            : map['stock'] is double
            ? map['stock'] as double         // Si ya es double, lo deja igual
            : null,  // Convertir a int si es necesario
        iva: null,
        categoria: map['categoryName']// Asigna un valor si es necesario
      );
    });
  }



  Future<void> insertProductosListaPrecio(ProductosListaPreciosModel productoListaPrecio) async {
    final db = await database;
    await db.insert(
      'productos_lista_precios',
      productoListaPrecio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // Método para insertar una lista de productos en productos_lista_precios en una transacción
  Future<void> insertProductosListasPrecios(List<ProductosListaPreciosModel> productosListaPrecios) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var productoListaPrecio in productosListaPrecios) {
        await txn.insert(
          'productos_lista_precios',
          productoListaPrecio.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  Future<List<ProductosListaPreciosModel>> getProductosListaPrecios(int listaId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'productos_lista_precios',
      where: 'lista_id = ?',
      whereArgs: [listaId],
    );

    return List.generate(maps.length, (i) => ProductosListaPreciosModel.fromMap(maps[i]));
  }


  Future<List<Map<String, dynamic>>> getProductosConPrecioYStock(int listaId, int sucursalId) async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      p.id AS productId,
      p.name AS productName,
      p.tipo_producto AS productType,
      p.precio_interno AS internalPrice,
      plp.precio_lista AS listPrice,
      pss.stock AS stock,
      pss.sucursal_id AS sucursalId,
      p.barcode AS productBarcode
    FROM productos p
    INNER JOIN productos_lista_precios plp ON p.producto_id = plp.product_id
    INNER JOIN productos_stock_sucursales pss ON p.producto_id = pss.product_id
    WHERE plp.lista_id = ? AND pss.sucursal_id = ?
  ''', [listaId, sucursalId]);

    print('Lista ID: $listaId, Sucursal ID: $sucursalId');
    return result;
  }


  Future<List<Map<String, dynamic>>> getProductosYStock(int listaId, int sucursalId) async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      p.id AS productId,
      p.name AS productName,
      p.tipo_producto AS productType,
      pss.stock AS stock,
      p.barcode AS productBarcode
    FROM productos p
    INNER JOIN productos_stock_sucursales pss ON p.idProducto = pss.producto_id
  ''', [listaId, sucursalId]);

    print('Lista ID: $listaId, Sucursal ID: $sucursalId');
    return result;
  }
  // Métodos relacionados con la tabla productos_ivas
  Future<List<ProductosIvasModel>> getProductosIvas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos_ivas');
    return List.generate(maps.length, (i) => ProductosIvasModel.fromMap(maps[i]));
  }

  Future<void> insertProductoIva(ProductosIvasModel productoIva) async {
    final db = await database;
    await db.insert(
      'productos_ivas',
      productoIva.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para insertar una lista de productosIvas en una sola transacción
  Future<void> insertProductosIvas(List<ProductosIvasModel> productosIvas) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var productoIva in productosIvas) {
        await txn.insert(
          'productos_ivas',
          productoIva.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return List.generate(maps.length, (i) {
      return Product(
        maps[i]['name'],
        maps[i]['image'],
        maps[i]['price'],
        maps[i]['code'],
        maps[i]['stock'],
      );
    });
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