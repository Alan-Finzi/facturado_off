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

    // Insertar un usuario
    await db.insert(
      'users',
      User(
        username: 'test1',
        password: 'test',
        nombreUsuario: 'Nombre',
        apellidoUsuario: 'Apellido',
        cantidadSucursales: 1,
        cantidadEmpleados: 10,
        name: 'Comercio Test',
        sucursal: 1,
        email: 'test1@example.com',
        profile: 'admin',
        status: 'activo',
        externalAuth: '',
        externalId: '',
        emailVerifiedAt: DateTime.now(),
        confirmedAt: DateTime.now(),

        plan: 1,
        lastLogin: DateTime.now(),
        cantidadLogin: 5,
        comercioId: "1",
        clienteId: 1,
        idListaPrecio: 1,
        image: 'path/to/image.png',
        casaCentralUserId: 1,
      ).toJson(),
    );

    // Insertar un cliente en la tabla Clientes_mostrador
    await dbHelper.insertCliente(ClientesMostrador(
      creadorId: 1,
      idCliente: '1',
      activo: 1,
      nombre: 'Cliente de Ejemplo',
      sucursalId: 1,
      listaPrecio:2,
      comercioId: 1,
      recontacto: DateTime.now().add(Duration(days: 30)),
      plazoCuentaCorriente: 30,
      montoMaximoCuentaCorriente: 10000.0,
      saldoInicialCuentaCorriente: 500.0,
      fechaInicialCuentaCorriente: DateTime.now(),
      pais: 'Argentina',
      codigoPostal: '1234',
      depto: 'A',
      piso: '3',
      altura: '1500',
      eliminado: 0,
      email: 'cliente@example.com',
      telefono: '123456789',
      observaciones: 'Cliente frecuente',
      localidad: 'Buenos Aires',
      barrio: 'Palermo',
      provincia: 'Buenos Aires',
      direccion: 'Calle Falsa 123',
      dni: '12345678',
      status: 'activo',
      image: 'url_to_image',
      wcCustomerId: '1',
    ));

    await dbHelper.insertCliente(ClientesMostrador(
      creadorId: 1,
      idCliente: '4',
      activo: 1,
      nombre: 'Cliente de Ejemplo 4',
      sucursalId: 1,
      listaPrecio: 1,
      comercioId: 1,
      recontacto: DateTime.now().add(Duration(days: 30)),
      plazoCuentaCorriente: 30,
      montoMaximoCuentaCorriente: 10000.0,
      saldoInicialCuentaCorriente: 500.0,
      fechaInicialCuentaCorriente: DateTime.now(),
      pais: 'Argentina',
      codigoPostal: '1234',
      depto: 'A',
      piso: '3',
      altura: '1500',
      eliminado: 0,
      email: 'cliente@example.com',
      telefono: '123456789',
      observaciones: 'Cliente frecuente',
      localidad: 'Buenos Aires',
      barrio: 'Palermo',
      provincia: 'Buenos Aires',
      direccion: 'Calle Falsa 123',
      dni: '12345678',
      status: 'activo',
      image: 'url_to_image',
      wcCustomerId: '1',
    ));


    await dbHelper.insertCliente(ClientesMostrador(
      creadorId: 1,
      idCliente: '3',
      activo: 1,
      nombre: 'Cliente de Ejemplo 3',
      sucursalId: 1,
      listaPrecio: 1,
      comercioId: 1,
      recontacto: DateTime.now().add(Duration(days: 30)),
      plazoCuentaCorriente: 30,
      montoMaximoCuentaCorriente: 10000.0,
      saldoInicialCuentaCorriente: 500.0,
      fechaInicialCuentaCorriente: DateTime.now(),
      pais: 'Argentina',
      codigoPostal: '1234',
      depto: 'A',
      piso: '3',
      altura: '1500',
      eliminado: 0,
      email: 'cliente@example.com',
      telefono: '123456789',
      observaciones: 'Cliente frecuente',
      localidad: 'Buenos Aires',
      barrio: 'Palermo',
      provincia: 'Buenos Aires',
      direccion: 'Calle Falsa 123',
      dni: '12345678',
      status: 'activo',
      image: 'url_to_image',
      wcCustomerId: '1',
    ));

    await dbHelper.insertCliente(ClientesMostrador(
      creadorId: 1,
      idCliente: '2',
      activo: 1,
      nombre: 'Cliente de Ejemplo 2',
      sucursalId: 1,
      listaPrecio: 1,
      comercioId: 1,
      recontacto: DateTime.now().add(Duration(days: 30)),
      plazoCuentaCorriente: 30,
      montoMaximoCuentaCorriente: 10000.0,
      saldoInicialCuentaCorriente: 500.0,
      fechaInicialCuentaCorriente: DateTime.now(),
      pais: 'Argentina',
      codigoPostal: '1234',
      depto: 'A',
      piso: '3',
      altura: '1500',
      eliminado: 0,
      email: 'cliente@example.com',
      telefono: '123456789',
      observaciones: 'Cliente frecuente',
      localidad: 'Buenos Aires',
      barrio: 'Palermo',
      provincia: 'Buenos Aires',
      direccion: 'Calle Falsa 123',
      dni: '12345678',
      status: 'activo',
      image: 'url_to_image',
      wcCustomerId: '1',
    ));


    // Insertar productos
    await db.insert('product', {
      'id': 1,
      'producto_id': 1,
      'name': 'Producto agregado por codigo de barra',
      'tipo_producto': 'barcode',
      'producto_tipo': 's',
      'precio_interno': 100.0,
      'barcode': '6920108163817',
      'cost': 50.0,
      'image': 'url_to_image',
      'category_id': 1,
      'marca_id': 1,
      'comercio_id': 1,
      'stock_descubierto': 'no',
      'proveedor_id': 1,
      'unidad_medida': 1,
      'wc_product_id': 1,
      'wc_image': 'url_to_wc_image',
      'etiquetas': 'etiqueta1, etiqueta2',
      'descripcion': 'Descripción del producto',
      'receta_id': 1,
      'eliminado': 0,
    });

    await db.insert('product', {
      'id': 2,
      'producto_id': 2,
      'name': 'Producto agregado por codigo de barra 2',
      'tipo_producto': 'barcode',
      'producto_tipo': 's',
      'precio_interno': 100.0,
      'barcode': '6920108160380',
      'cost': 50.0,
      'image': 'url_to_image',
      'category_id': 1,
      'marca_id': 1,
      'comercio_id': 1,
      'stock_descubierto': 'no',
      'proveedor_id': 1,
      'eliminado': 0,
      'unidad_medida': 1,
      'wc_product_id': 1,
      'wc_push': 1,
      'wc_image': 'url_to_wc_image',
      'etiquetas': 'etiqueta1, etiqueta2',
      'mostrador_canal': 1,
      'ecommerce_canal': 1,
      'wc_canal': 1,
      'descripcion': 'Descripción del producto',
      'receta_id': 1,
    });

    await db.insert('product', {
      'id': 3,
      'producto_id': 3,
      'name': 'Producto agregado por codigo de barra 3',
      'tipo_producto': 'barcode',
      'producto_tipo': 's',
      'precio_interno': 100.0,
      'barcode': '6920108160380',
      'cost': 50.0,
      'image': 'url_to_image',
      'category_id': 1,
      'marca_id': 1,
      'comercio_id': 1,
      'stock_descubierto': 'no',
      'proveedor_id': 1,
      'eliminado': 1,
      'unidad_medida': 1,
      'wc_product_id': 1,
      'wc_push': 1,
      'wc_image': 'url_to_wc_image',
      'etiquetas': 'etiqueta1, etiqueta2',
      'mostrador_canal': 1,
      'ecommerce_canal': 1,
      'wc_canal': 1,
      'descripcion': 'Descripción del producto',
      'receta_id': 1,
    });

    await db.insert('product', {
      'id': 4,
      'producto_id': 4,
      'name': 'Vino tinto',
      'tipo_producto': 'barcode',
      'producto_tipo': 's',
      'precio_interno': 100.0,
      'barcode': '7798116190311',
      'cost': 50.0,
      'image': 'url_to_image',
      'category_id': 1,
      'marca_id': 1,
      'comercio_id': 1,
      'stock_descubierto': 'no',
      'proveedor_id': 1,
      'eliminado': 0,
      'unidad_medida': 1,
      'wc_product_id': 1,
      'wc_push': 1,
      'wc_image': 'url_to_wc_image',
      'etiquetas': 'etiqueta1, etiqueta2',
      'mostrador_canal': 1,
      'ecommerce_canal': 1,
      'wc_canal': 1,
      'descripcion': 'Descripción del producto',
      'receta_id': 1,
    });

    // Insertar listas de precios
    await db.insert('lista', {
      'id': 1,
      'nombre': 'Lista General',
    });

    await db.insert('lista', {
      'id': 2,
      'nombre': 'Lista General mayorista',
    });

    await db.insert('productos_lista_precios', {
      'product_id': 1,
      'referencia_variacion': 'Var1',
      'lista_id': 1,
      'precio_lista': getRandomPrice(),
      'comercio_id': 1,
      'eliminado': 0,
    });

    await db.insert('productos_lista_precios', {
      'product_id': 1,
      'referencia_variacion': 'Var1',
      'lista_id': 2,
      'precio_lista': getRandomPrice(),
      'comercio_id': 1,
      'eliminado': 0,
    });

    final randomStock1 = getRandomStock();
    await db.insert('productos_stock_sucursales', {
      'product_id': 1,
      'referencia_variacion': 'Var1',
      'comercio_id': 1,
      'sucursal_id': 1,
      'almacen_id': 1,
      'stock': randomStock1,
      'stock_real': randomStock1,
      'eliminado': 0,
    });

    await db.insert('productos_lista_precios', {
      'product_id': 2,
      'referencia_variacion': 'Var1',
      'lista_id': 1,
      'precio_lista': getRandomPrice(),
      'comercio_id': 1,
      'eliminado': 0,
    });

    await db.insert('productos_lista_precios', {
      'product_id': 4,
      'referencia_variacion': 'Var1',
      'lista_id': 2,
      'precio_lista': getRandomPrice(),
      'comercio_id': 1,
      'eliminado': 0,
    });

    await db.insert('productos_lista_precios', {
      'product_id': 4,
      'referencia_variacion': 'Var1',
      'lista_id': 1,
      'precio_lista': getRandomPrice(),
      'comercio_id': 1,
      'eliminado': 0,
    });

    // Ya se insertó el stock para el producto 1
    final randomStock3 = getRandomStock();
    await db.insert('productos_stock_sucursales', {
      'product_id': 3,
      'referencia_variacion': 'Var1',
      'comercio_id': 1,
      'sucursal_id': 1,
      'almacen_id': 1,
      'stock': randomStock3,
      'stock_real': randomStock3,
      'eliminado': 0,
    });
    final randomStock2 = getRandomStock();
    await db.insert('productos_stock_sucursales', {
      'product_id': 2,
      'referencia_variacion': 'Var1',
      'comercio_id': 1,
      'sucursal_id': 1,
      'almacen_id': 1,
      'stock': randomStock2,
      'stock_real': randomStock2,
      'eliminado': 0,
    });
    
    // Stock para producto 4
    final randomStock4 = getRandomStock();
    await db.insert('productos_stock_sucursales', {
      'product_id': 4,
      'referencia_variacion': 'Var1',
      'comercio_id': 1,
      'sucursal_id': 1,
      'almacen_id': 1,
      'stock': randomStock4,
      'stock_real': randomStock4,
      'eliminado': 0,
    });
  }
}
