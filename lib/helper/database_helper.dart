
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/user.dart';
import '../models/Producto.dart';

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
    String path = join(await getDatabasesPath(), 'flaminco_app_DB.db');
    await deleteDatabase(path);
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flaminco_app_DB.db');
    return await openDatabase(
      path,
      version: 2, // Incrementa la versión para aplicar cambios en la estructura de la base de datos
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY,
          username TEXT,
          password TEXT,
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
          confirmed INTEGER,
          plan INTEGER,
          last_login TEXT,
          cantidad_login INTEGER,
          comercio_id INTEGER,
          cliente_id INTEGER,
          image TEXT,
          casa_central_user_id INTEGER
        )
      ''');

        await db.execute('''
        CREATE TABLE productos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          tipo_producto TEXT,
          producto_tipo TEXT,
          precio_interno REAL,
          barcode TEXT,
          cost REAL,
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
          receta_id INTEGER,
          stock INTEGER,
          stock_real INTEGER,
          precio_lista REAL,
          lista_id INTEGER,
          iva REAL
        )
      ''');
      },
    );
  }

  Future<User?> getUser(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = (await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    )).cast<Map<String, dynamic>>();

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<List<User>> getUsers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = (await db.query('users')).cast<Map<String, dynamic>>();

    return List.generate(maps.length, (i) {
      return User.fromJson(maps[i]);
    });
  }

  // Nuevo método para agregar producto
  Future<void> insertProducto(ProductoModel producto) async {
    Database db = await database;
    await db.insert(
      'productos',
      producto.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Nuevo método para obtener productos
  Future<List<ProductoModel>> getProductos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');

    return List.generate(maps.length, (i) {
      return ProductoModel.fromJson(maps[i]);
    });
  }
}