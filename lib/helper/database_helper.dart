
import 'package:sqflite/sqflite.dart';

import '../models/Producto_precio_stock.dart';
import '../models/categorias_model.dart';
import '../models/clientes_mostrador.dart';
import '../models/datos_facturacion_model.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/productos_ivas_model.dart';
import '../models/productos_lista_precios_model.dart';
import '../models/productos_maestro.dart';
import '../models/productos_stock_sucursales.dart';
import '../models/user.dart';
import 'package:path/path.dart';
import 'dart:convert';



class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Cache en memoria para consultas frecuentes
  final Map<String, dynamic> _queryCache = {};
  final Duration _cacheDuration = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Obtiene una instancia de la base de datos, inicializándola si es necesario
  /// La base de datos se mantiene como singleton para eficiencia
  Future<Database> get database async {
    if (_database != null) return _database!;
    await deleteDatabaseIfExists();
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Limpia la caché después de que expire el tiempo
  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      final isExpired = now.difference(timestamp) > _cacheDuration;
      if (isExpired) _queryCache.remove(key);
      return isExpired;
    });
  }
  
  /// Almacena un resultado en la caché
  void _cacheResult(String key, dynamic result) {
    _queryCache[key] = result;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  /// Obtiene un resultado de la caché si está disponible y no ha expirado
  dynamic _getCachedResult(String key) {
    _cleanExpiredCache();
    return _queryCache[key];
  }

  Future<void> deleteDatabaseIfExists() async {
    String path = join(await getDatabasesPath(), 'flaminco_appv13_DB.db');
    await deleteDatabase(path);
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flaminco_appv13_DB.db');
    print('La base de datos se guarda en la siguiente ruta: $path');

    return await  openDatabase(
      path,
      version: 27, // Incrementa este número si ya estabas en 23
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 24) {
          await _createTables(db); // Llama a _createTables para crear las tablas nuevas
        }
      },
    );
  }



  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        modificado INTEGER,
        image TEXT,
        wc_customer_id TEXT
      )
    ''');

    // Tabla: product
    await db.execute('''
  CREATE TABLE IF NOT EXISTS product(
    id INTEGER PRIMARY KEY, -- id como clave primaria
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
    receta_id INTEGER,
    listas_precios TEXT, -- Almacena listas de precios en formato JSON
    stocks TEXT,         -- Almacena stocks en formato JSON
    category_name TEXT,  -- Nombre de la categoría
    categoria TEXT,      -- Objeto categoría en formato JSON
    UNIQUE(id)
  );
''');

// Tabla: producto_response
    await db.execute('''
  CREATE TABLE IF NOT EXISTS producto_response (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    current_page INTEGER
  );
''');

// Tabla: producto_data
    await db.execute('''
  CREATE TABLE IF NOT EXISTS producto_data (
    id INTEGER PRIMARY KEY,
    atributo_id INTEGER,
    variacion_id INTEGER,
    producto_id INTEGER,
    referencia_id TEXT,
    codigo_variacion TEXT,
    comercio_id INTEGER,
    eliminado INTEGER,
    updated_at TEXT,
    created_at TEXT,
    product_id INTEGER,
    response_id INTEGER,
    FOREIGN KEY (product_id) REFERENCES product (id),
    FOREIGN KEY (response_id) REFERENCES producto_response (id)
  );
''');

// Tabla: variacion
    await db.execute('''
  CREATE TABLE IF NOT EXISTS variacion (
    id INTEGER PRIMARY KEY,
    referencia_variacion TEXT,
    nombre TEXT,
    producto_id INTEGER,
    FOREIGN KEY (producto_id) REFERENCES product (id)
  );
''');

// Tabla: atributo
    await db.execute('''
  CREATE TABLE IF NOT EXISTS atributo (
    id INTEGER PRIMARY KEY,
    nombre TEXT
  );
''');
    await db.execute('DROP TABLE IF EXISTS lista_precio');
// Tabla: lista_precio
    await db.execute('''
  CREATE TABLE IF NOT EXISTS lista_precio(
    lista_id INTEGER,          
    product_id INTEGER, 
    referencia_variacion TEXT,         
    precio_lista REAL,         
    lista_id_fk INTEGER,     
    PRIMARY KEY (lista_id, product_id)
  );
''');

// Tabla: lista
    await db.execute('''
  CREATE TABLE IF NOT EXISTS lista(
    id INTEGER PRIMARY KEY,
    nombre TEXT
  );
''');

// Tabla: stock
    await db.execute('''
  CREATE TABLE IF NOT EXISTS stock(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER,
    stock REAL,
    referencia_variacion TEXT,
    sucursal_id INTEGER,
    sucursal TEXT, -- Ajusta el tipo de 'sucursal' según lo que necesites
    FOREIGN KEY (product_id) REFERENCES product(id)
  );
''');

// Tabla: productos_stock_sucursales
    await db.execute('''
  CREATE TABLE IF NOT EXISTS productos_stock_sucursales(
    product_id INTEGER,
    referencia_variacion TEXT,
    comercio_id INTEGER,
    sucursal_id INTEGER,
    almacen_id INTEGER,
    stock INTEGER,
    stock_real INTEGER,
    eliminado INTEGER,
    PRIMARY KEY (product_id, referencia_variacion, comercio_id, sucursal_id, almacen_id)
  );
''');

// Tabla: productos_lista_precios
    await db.execute('''
  CREATE TABLE IF NOT EXISTS productos_lista_precios(
    product_id INTEGER,
    referencia_variacion TEXT,
    lista_id INTEGER,
    precio_lista REAL,
    comercio_id INTEGER,
    eliminado INTEGER,
    PRIMARY KEY (product_id, referencia_variacion, lista_id, comercio_id)
  );
''');

// Tabla: categorias
    await db.execute('''
  CREATE TABLE IF NOT EXISTS categorias(
    id INTEGER PRIMARY KEY,
    comercio_id TEXT,
    name TEXT,
    image TEXT,
    wc_category_id TEXT,
    eliminado INTEGER,
    created_at TEXT,
    updated_at TEXT
  );
''');

    await db.execute('''
  CREATE TABLE datos_facturacion(
    id INTEGER PRIMARY KEY AUTOINCREMENT,      -- Campo id con auto incremento
    usuario_id INTEGER,                        -- Campo para el ID del usuario
    razon_social TEXT,                         -- Nombre o razón social de la empresa
    comercio_id INTEGER,                       -- ID del comercio
    provincia INTEGER,                         -- ID de la provincia (puede ser un número o ID)
    localidad TEXT,                            -- Localidad
    domicilio_fiscal TEXT,                     -- Dirección fiscal
    iva_defecto REAL,                          -- Valor del IVA por defecto (como número decimal)
    fecha_inicio_actividades TEXT,             -- Fecha de inicio de actividades
    condicion_iva TEXT,                        -- Condición de IVA (puede ser un texto como "responsable inscripto")
    iibb TEXT,                                 -- Código de IIBB (Ingresos Brutos)
    cuit TEXT,                                 -- Número de CUIT
    pto_venta TEXT,                            -- Punto de venta
    relacion_precio_iva INTEGER,               -- Relación entre precio y IVA
    habilitado_afip INTEGER,                   -- Si está habilitado en AFIP (1=Sí, 0=No)
    eliminado INTEGER,                         -- Indica si está eliminado (1=Eliminado, 0=Activo)
    predeterminado INTEGER,                    -- Indica si es el predeterminado (1=Sí, 0=No)
    updated_at TEXT,                           -- Fecha de última actualización
    created_at TEXT                            -- Fecha de creación
  )
''');
    await db.execute('''
      CREATE TABLE productos_ivas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        comercio_id INTEGER,
        sucursal_id INTEGER,
        iva REAL,
        porcentaje REAL
      )
    ''');
  }
  Future<void> insertProductoResponse(ProductoResponse productoResponse) async {
    try {
      final db = await database;

      // Inserta la cabecera de ProductoResponse
      int responseId = await db.insert(
        'producto_response',
        {'current_page': productoResponse.currentPage},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (productoResponse.data != null) {
        for (var datum in productoResponse.data!) {
          // Convertir listas complejas a JSON
          String listasPreciosJson = jsonEncode(
            datum.listasPrecios?.map((lp) => lp.toJson()).toList() ?? [],
          );
          String stocksJson = jsonEncode(
              (datum.stocks ?? []).map((s) => s.toJson()).toList()
          );

          // Insertar producto principal
          await db.insert(
            'product',
            {
              'id': datum.id,
              'name': datum.nombre,
              'barcode': datum.barcode,
              'tipo_producto': productoTipoValues.reverse[datum.productoTipo],
              'producto_tipo': productoTipoValues.reverse[datum.productoTipo],
              'category_id': datum.categoryId,
              'marca_id': datum.marcaId,
              'proveedor_id': datum.proveedorId,
              'comercio_id': int.tryParse(datum.comercioId ?? ''),
              'listas_precios': listasPreciosJson,
              'stocks': stocksJson,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Procesar variaciones
          if (datum.productosVariaciones != null) {
            for (var productoVar in datum.productosVariaciones!) {
              // 1. Insertar en tabla variacion
              int variacionId = await db.insert(
                'variacion',
                {
                  'referencia_variacion': productoVar.referenciaVariacion,
                  'nombre': productoVar.variaciones, // String directo
                  'producto_id': datum.id, // Relación con product
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              // 2. Insertar en producto_data
              await db.insert(
                'producto_data',
                {
                  'producto_id': datum.id,
                  'variacion_id': variacionId,
                  'referencia_id': productoVar.referenciaVariacion,
                  'codigo_variacion': productoVar.codigoVariacion,
                  'comercio_id': int.tryParse(datum.comercioId ?? ''),
                  'product_id': datum.id,
                  'response_id': responseId,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              // 3. Insertar stocks de variación
              if (productoVar.stocks != null) {
                for (var stock in productoVar.stocks!) {
                  await db.insert(
                    'stock',
                    {
                      'product_id': datum.id,
                      'referencia_variacion': productoVar.referenciaVariacion,
                      'stock': stock.stock,
                      'sucursal_id': stock.sucursalId,
                      'sucursal': stock.sucursal,
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                }
              }

              // 4. Insertar listas de precios de variación
              if (productoVar.listasPrecios != null) {
                for (var lp in productoVar.listasPrecios!) {
                  await db.insert(
                    'lista_precio',
                    {
                      'lista_id': lp.listaId,
                      'product_id': datum.id,
                      'referencia_variacion': productoVar.referenciaVariacion,
                      'precio_lista': double.tryParse(lp.precioLista ?? '') ?? 0.0,
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );

                  if (lp.lista != null) {
                    await db.insert(
                      'lista',
                      {
                        'id': lp.lista!.id,
                        'nombre': lp.lista!.nombre,
                      },
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    );
                  }
                }
              }
            }
          }

          // Insertar stocks a nivel de producto
          if (datum.stocks != null) {
            for (var stock in datum.stocks!) {
              await db.insert(
                'stock',
                {
                  'product_id': datum.id,
                  'stock': stock.stock,
                  'sucursal_id': stock.sucursalId,
                  'sucursal': stock.sucursal,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Insertar listas de precio a nivel de producto
          if (datum.listasPrecios != null) {
            for (var lp in datum.listasPrecios!) {
              await db.insert(
                'lista_precio',
                {
                  'lista_id': lp.listaId,
                  'product_id': datum.id,
                  'precio_lista': double.tryParse(lp.precioLista ?? '') ?? 0.0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              if (lp.lista != null) {
                await db.insert(
                  'lista',
                  {
                    'id': lp.lista!.id,
                    'nombre': lp.lista!.nombre,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error al insertar ProductoResponse: $e');
      rethrow;
    }
  }




  Future<ProductoResponse> getProductoResponseBySucursalId(
      int sucursalId, int listaId) async {
    final db = await database;

    // Obtener categorías


    // Ejecutar consulta
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
    SELECT 
      p.id AS id,
      p.name AS nombre, 
      p.barcode, 
      p.producto_tipo AS productoTipo, 
      p.category_id AS categoryId, 
      p.marca_id AS marcaId, 
      p.proveedor_id AS proveedorId,
      p.comercio_id AS comercioId,
       c.name AS categoria_nombre, 
      
      -- Variaciones
      v.id AS variacion_id, 
      v.referencia_variacion AS variacion_referencia,
      v.nombre AS variacion_nombre, 

      -- Stock (la tabla productos_stock_sucursales no tiene campo id)
      pss.product_id AS stock_id,
      pss.stock AS stock,
      pss.stock_real AS stock_real,
      pss.sucursal_id AS stock_sucursal_id,

      -- Lista de precios
      plp.lista_id AS lista_precio_id,
      plp.precio_lista AS lista_precio_precio,
      l.id AS lista_id, 
      l.nombre AS lista_nombre

    FROM product p
     LEFT JOIN categorias c ON p.category_id = c.id
    LEFT JOIN variacion v ON p.id = v.producto_id
    LEFT JOIN productos_stock_sucursales pss 
      ON p.id = pss.product_id 
      AND (pss.sucursal_id = ? OR pss.sucursal_id IS NULL)
      AND (pss.referencia_variacion = v.referencia_variacion OR pss.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
    LEFT JOIN productos_lista_precios plp 
      ON p.id = plp.product_id 
      AND (plp.lista_id = ? OR plp.lista_id = 0)
      AND (plp.referencia_variacion = v.referencia_variacion OR plp.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
    LEFT JOIN lista l ON plp.lista_id = l.id
    WHERE p.eliminado = 0 OR p.eliminado IS NULL
  ''', [sucursalId, listaId]);

    final Map<int, Datum> productosMap = {};

    for (var row in rows) {
      // Procesar producto principal
      final dynamic idValue = row['id'];
      final int? productId = idValue != null ? int.tryParse(idValue.toString()) : null;
      if (productId == null) continue;

      if (!productosMap.containsKey(productId)) {
        // Buscar categoría
        final dynamic categoryIdValue = row['categoryId'];
        final int? categoryId = categoryIdValue != null ? int.tryParse(categoryIdValue.toString()) : null;

        productosMap[productId] = Datum(
          id: productId,
          nombre: row['nombre'] as String?,
          barcode: row['barcode'] as String?,
          productoTipo: row['productoTipo'] != null
              ? productoTipoValues.map[row['productoTipo']]
              : null,
          categoryId: categoryId,
          categoriaName: row['categoria_nombre'],
          marcaId: row['marcaId'] != null ? int.tryParse(row['marcaId'].toString()) : null,
          proveedorId: row['proveedorId'] != null ? int.tryParse(row['proveedorId'].toString()) : null,
          comercioId: row['comercioId']?.toString(),
          productosVariaciones: [],
          stocks: [],
          listasPrecios: [],
        );
      }

      final productoActual = productosMap[productId]!;

      // Procesar variación
      if (row['variacion_referencia'] != null) {
        final String referenciaVar = row['variacion_referencia'] as String;

        // Buscar si ya existe la variación
        var variacion = productoActual.productosVariaciones!.firstWhere(
              (v) => v.referenciaVariacion == referenciaVar,
          orElse: () {
            final nuevaVariacion = ProductosVariacione(
              productId: productId,
              referenciaVariacion: referenciaVar,
              variaciones: row['variacion_nombre'] as String?,
              codigoVariacion: null, // Añadir si existe en la consulta
              cost: null, // Añadir si existe en la consulta
              precioInterno: null, // Añadir si existe en la consulta
              stocks: [],
              listasPrecios: [],
            );
            productoActual.productosVariaciones!.add(nuevaVariacion);
            return nuevaVariacion;
          },
        );

        // Procesar stock de la variación
        if (row['stock_id'] != null) {
          variacion.stocks!.add(Stock(
            id: row['stock_id'] as int?,
            productId: productId,
            referenciaVariacion: referenciaVar,
            stock: row['stock']?.toString(),
            sucursalId: row['stock_sucursal_id'] as int?,
          ));
        }

        // Procesar precios de la variación
        if (row['lista_precio_id'] != null) {
          variacion.listasPrecios!.add(ListasPrecio(
            id: row['lista_precio_id'] as int?,
            productId: productId,
            referenciaVariacion: referenciaVar,
            precioLista: row['lista_precio_precio']?.toString(),
            listaId: row['lista_id'] as int?,
            lista: row['lista_id'] != null
                ? Lista(
              id: row['lista_id'] as int?,
              nombre: row['lista_nombre'] as String?,
            )
                : null,
          ));
        }
      }

      // Procesar stock a nivel de producto (si aplica en tu modelo)
      if (row['stock_id'] != null && productoActual.stocks != null) {
        productoActual.stocks!.add(Stock(
          id: row['stock_id'] as int?,
          productId: productId,
          stock: row['stock']?.toString(),
          sucursalId: row['stock_sucursal_id'] as int?,
        ));
      }

      // Procesar precios a nivel de producto (si aplica en tu modelo)
      if (row['lista_precio_id'] != null && productoActual.listasPrecios != null) {
        productoActual.listasPrecios!.add(ListasPrecio(
          id: row['lista_precio_id'] as int?,
          productId: productId,
          precioLista: row['lista_precio_precio']?.toString(),
          listaId: row['lista_id'] as int?,
          lista: row['lista_id'] != null
              ? Lista(
            id: row['lista_id'] as int?,
            nombre: row['lista_nombre'] as String?,
          )
              : null,
        ));
      }
    }

    return ProductoResponse(
      currentPage: 1,
      data: productosMap.values.toList(),
      // Completa estos valores según tu paginación
      firstPageUrl: null,
      from: 1,
      lastPage: 1,
      lastPageUrl: null,
      links: [],
      nextPageUrl: null,
      path: null,
      perPage: 20,
      prevPageUrl: null,
      to: productosMap.length,
      total: productosMap.length,
    );
  }





  //datos facturacion
  Future<List<DatosFacturacionModel>> getAllDatosFacturacion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('datos_facturacion');

    return List.generate(maps.length, (i) {
      return DatosFacturacionModel.fromJson(maps[i]);
    });
  }

  //
  Future<int> insertDatosFacturacion(DatosFacturacionModel datos) async {
    final db = await database;
    return await db.insert(
      'datos_facturacion',
      datos.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDatosFacturacionList(List<DatosFacturacionModel> datosList) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final datos in datosList) {
        await txn.insert(
          'datos_facturacion',
          datos.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

// Métodos para usuarios
  Future<void> insertUser(User user) async {
    try {
      final db = await database;
      await db.insert(
        'users',
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      print('Error al insertar el usuario: $e');
      print('StackTrace: $stackTrace');
      // Podés lanzar el error si querés que se propague hacia arriba
      // throw Exception('Fallo al insertar usuario');
    }
  }

  Future<User?> getUser(String username) async {
    Database db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return maps.isNotEmpty ? User.fromJson(maps.first) : null;
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  // Métodos para productos
  Future<void> insertProducto(ProductoModel producto) async {
    final db = await database;
    await db.insert('productos', producto.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ProductoModel?> getProductoById(int id) async {
    final db = await database;
    final maps = await db.query('productos', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? ProductoModel.fromMap(maps.first) : null;
  }

  Future<void> insertCategorias(List<CategoriaModel> categorias) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        for (var categoria in categorias) {
          await txn.insert(
            'categorias',
            categoria.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e, s) {
      print('Error al insertar categorías: $e');
      print('Stack trace: $s');
      // Opcional: relanzar la excepción si deseas que el llamador también la maneje
      // throw e;
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

  /// Obtiene todos los productos de la base de datos con caché para mejorar rendimiento
  Future<List<ProductoModel>> getProductos() async {
    const cacheKey = 'all_productos';
    
    // Verificar si existe en caché
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      return cachedResult as List<ProductoModel>;
    }
    
    // Consultar la base de datos
    final db = await database;
    final maps = await db.query('productos');
    final result = maps.map((map) => ProductoModel.fromMap(map)).toList();
    
    // Guardar en caché
    _cacheResult(cacheKey, result);
    
    return result;
  }

  Future<void> insertOrUpdateProductos(List<ProductoModel> productos) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var producto in productos) {
        await txn.insert(
          'productos',
          producto.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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


  Future<List<Lista>> getListaPrecios() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Lista');
    return List.generate(maps.length, (i) => Lista.fromJson(maps[i]));
  }

  Future<void> deleteListaPrecio(int id) async {
    Database db = await database;
    await db.delete(
      'lista_precio',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos relacionados con la tabla Clientes_mostrador
  Future<void> insertCliente(ClientesMostrador cliente) async {
    if (!await clienteExiste(cliente.idCliente!)) {
      Database db = await database;
      await db.insert(
        'Clientes_mostrador',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> clienteExiste(String idCliente) async {
    Database db = await database;
    final result = await db.query(
      'Clientes_mostrador',
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
    );
    return result.isNotEmpty;
  }


 Future<List<ClientesMostrador>> getClientesModificados() async {
   final db = await instance.database;
   final maps = await db.query('clientes_mostrador', where: 'modificado = 1');
   return maps.map((e) => ClientesMostrador.fromJson(e)).toList();
 }

   Future<void> marcarClienteSincronizado(String? idCliente) async {
   final db = await instance.database;
   await db.update('clientes_mostrador', {'modificado': 0}, where: 'id_cliente = ?', whereArgs: [idCliente]);
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

  /// Obtiene todos los clientes de la base de datos con caché para mejorar rendimiento
  Future<List<ClientesMostrador>> getClientesDB() async {
    const cacheKey = 'all_clientes';
    
    // Verificar si existe en caché
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      return cachedResult as List<ClientesMostrador>;
    }
    
    // Consultar la base de datos
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Clientes_mostrador');
    final result = List.generate(maps.length, (i) => ClientesMostrador.fromJson(maps[i]));
    
    // Guardar en caché
    _cacheResult(cacheKey, result);
    
    return result;
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

  //datos facturacion
  Future<List<DatosFacturacionModel>> getAllDatosFacturacionCommerce(int comercioId) async {
    final db = await database;

    // Modificar la consulta para filtrar por comercioId
    final List<Map<String, dynamic>> maps = await db.query(
      'datos_facturacion',
      where: 'comercio_id = ?', // Filtro por comercioId
      whereArgs: [comercioId],   // Usamos el comercioId en los argumentos
    );

    return List.generate(maps.length, (i) {
      return DatosFacturacionModel.fromJson(maps[i]);
    });
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

  Future<List<Datum>> getProducts() async {
    final db = await database;

    final List<Map<String, dynamic>> productResults = await db.rawQuery('''
    SELECT 
      p.id AS product_id, 
      p.name AS product_name, 
      p.category_id AS product_category_id,
      p.barcode AS product_barcode,
      p.producto_tipo AS product_producto_tipo,
      p.listas_precios AS product_listas_precios,
      p.stocks AS product_stocks,
      c.name AS categoria_nombre,
      p.category_name AS product_category_name,
      p.categoria AS product_categoria,
      p.marca_id AS product_marca_id,
      p.proveedor_id AS product_proveedor_id,
      p.comercio_id AS product_comercio_id,
      lp.lista_id AS lista_precio_id, 
      lp.precio_lista AS lista_precio_precio, 
      l.id AS lista_id_fk, 
      l.nombre AS lista_nombre
    FROM product p
     LEFT JOIN categoria c ON p.category_id = c.id
    LEFT JOIN lista_precio lp ON p.id = lp.product_id
    LEFT JOIN lista l ON lp.lista_id = l.id
  ''');

    // Mapa para agrupar los Datum por product_id
    final Map<int, Datum> datumMap = {};

    for (var row in productResults) {
      final int productId = row['product_id'] as int;

      // Si aún no existe el Datum para este producto, crearlo
      if (!datumMap.containsKey(productId)) {
        // Decodificar las listas de precios almacenadas en JSON.
        List<ListasPrecio> listasPrecios = [];
        if (row['product_listas_precios'] != null) {
          try {
            final List<dynamic> lpJson = jsonDecode(row['product_listas_precios']);
            listasPrecios = lpJson.map((lp) => ListasPrecio.fromJson(lp)).toList();
          } catch (e) {
            listasPrecios = [];
          }
        }

        // Decodificar los stocks almacenados en JSON.
        List<Stock> stocks = [];
        if (row['product_stocks'] != null) {
          try {
            final List<dynamic> stocksJson = jsonDecode(row['product_stocks']);
            stocks = stocksJson.map((s) => Stock.fromJson(s)).toList();
          } catch (e) {
            stocks = [];
          }
        }

        // Determinar el productoTipo usando la columna 'product_producto_tipo'
        ProductoTipo? productoTipo;
        if (row['product_producto_tipo'] != null) {
          productoTipo = productoTipoValues.map[row['product_producto_tipo']];
        }

        // Crear el objeto Datum (producto)
        Datum datum = Datum(
          id: productId,
          nombre: row['product_name'] as String?,
          barcode: row['product_barcode'] as String?,
          categoriaName: row['categoriaName'] as String?,
          productoTipo: productoTipo,
          categoryId: row['product_category_id'] as int?,
          marcaId: row['product_marca_id'] as int?,
          proveedorId: row['product_proveedor_id'] as int?,
          comercioId: row['product_comercio_id'] as String?,
          // Para este método, usamos los JSON decodificados de la tabla product
          listasPrecios: listasPrecios,
          stocks: stocks,
          // Si en este query no obtenemos las variaciones, dejamos la lista vacía
          productosVariaciones: [],
        );
        datumMap[productId] = datum;
      }

      // Agregar la lista de precio proveniente del join (si existe)
      if (row['lista_precio_id'] != null) {
        final ListasPrecio lp = ListasPrecio(
          id: row['lista_precio_id'] as int?,
          productId: productId,
          // Convertir el valor a String para precioLista
          precioLista: row['lista_precio_precio'] != null
              ? row['lista_precio_precio'].toString()
              : null,
          listaId: row['lista_id_fk'] as int?,
          lista: row['lista_id_fk'] != null
              ? Lista(
            id: row['lista_id_fk'] as int?,
            nombre: row['lista_nombre'] as String?,
          )
              : null,
        );
        datumMap[productId]?.listasPrecios?.add(lp);
      }
    }

    return datumMap.values.toList();
  }


}

