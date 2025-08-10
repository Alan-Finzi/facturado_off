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
    await dbHelper.insertProducto(ProductoModel(
      id: 1,
      idProducto: 1,
      name: 'Producto agregado por codigo de barra',
      tipoProducto: 'barcode',
      productoTipo: 's',
      precioInterno: 100.0,
      barcode: '6920108163817',
      cost: 50.0,
      image: 'url_to_image',
      categoryId: 1,
      marcaId: 1,
      comercioId: 1,
      stockDescubierto: 'no',
      proveedorId: 1,
      unidadMedida: 1,
      wcProductId: 1,
      wcImage: 'url_to_wc_image',
      etiquetas: 'etiqueta1, etiqueta2',
      descripcion: 'Descripción del producto',
      recetaId: 1,
    ));

    await dbHelper.insertProducto(ProductoModel(
      idProducto: 2,
      id: 2,
      name: 'Producto agregado por codigo de barra 2',
      tipoProducto: 'barcode',
      productoTipo: 's',
      precioInterno: 100.0,
      barcode: '6920108160380',
      cost: 50.0,
      image: 'url_to_image',
      categoryId: 1,
      marcaId: 1,
      comercioId: 1,
      stockDescubierto: 'no',
      proveedorId: 1,
      eliminado: 0,
      unidadMedida: 1,
      wcProductId: 1,
      wcPush: 1,
      wcImage: 'url_to_wc_image',
      etiquetas: 'etiqueta1, etiqueta2',
      mostradorCanal: 1,
      ecommerceCanal: 1,
      wcCanal: 1,
      descripcion: 'Descripción del producto',
      recetaId: 1,
    ));

    await dbHelper.insertProducto(ProductoModel(
      idProducto: 3,
      id: 3,
      name: 'Producto agregado por codigo de barra 2',
      tipoProducto: 'barcode',
      productoTipo: 's',
      precioInterno: 100.0,
      barcode: '6920108160380',
      cost: 50.0,
      image: 'url_to_image',
      categoryId: 1,
      marcaId: 1,
      comercioId: 1,
      stockDescubierto: 'no',
      proveedorId: 1,
      eliminado: 1,
      unidadMedida: 1,
      wcProductId: 1,
      wcPush: 1,
      wcImage: 'url_to_wc_image',
      etiquetas: 'etiqueta1, etiqueta2',
      mostradorCanal: 1,
      ecommerceCanal: 1,
      wcCanal: 1,
      descripcion: 'Descripción del producto',
      recetaId: 1,
    ));

    await dbHelper.insertProducto(ProductoModel(
      id: 4,
      idProducto: 4,
      name: 'Vino tinto',
      tipoProducto: 'barcode',
      productoTipo: 's',
      precioInterno: 100.0,
      barcode: '7798116190311',
      cost: 50.0,
      image: 'url_to_image',
      categoryId: 1,
      marcaId: 1,
      comercioId: 1,
      stockDescubierto: 'no',
      proveedorId: 1,
      eliminado: 0,
      unidadMedida: 1,
      wcProductId: 1,
      wcPush: 1,
      wcImage: 'url_to_wc_image',
      etiquetas: 'etiqueta1, etiqueta2',
      mostradorCanal: 1,
      ecommerceCanal: 1,
      wcCanal: 1,
      descripcion: 'Descripción del producto',
      recetaId: 1,
    ));

    // Insertar listas de precios
    await dbHelper.insertListaPrecio(ListaPreciosModel(
      nombre: 'Lista General',
      comercioId: 1,
      descripcion: 'Lista de precios para todos los clientes',
      eliminado: 0,
      wcKey: '1',
    ));

    await dbHelper.insertListaPrecio(ListaPreciosModel(
      nombre: 'Lista General mayorista',
      comercioId: 1,
      descripcion: 'Lista de precios para todos los clientes',
      eliminado: 0,
      wcKey: '2',
    ));

    await dbHelper.insertProductosListaPrecio(ProductosListaPreciosModel(
      productId: 1,
      referenciaVariacion: 'Var1',
      listaId: 1,
      precioLista: getRandomPrice(),
      comercioId: 1,
      eliminado: 0,
    ));

    await dbHelper.insertProductosListaPrecio(ProductosListaPreciosModel(
      productId: 1,
      referenciaVariacion: 'Var1',
      listaId: 2,
      precioLista: getRandomPrice(),
      comercioId: 1,
      eliminado: 0,
    ));

    final randomStock1 = getRandomStock();
    await dbHelper.insertProductosStockSucursal(ProductosStockSucursalesModel(
      productId: 1,
      referenciaVariacion: 'Var1',
      comercioId: 1,
      sucursalId: 1,
      almacenId: 1,
      stock: 200,
      stockReal: 200, // 90% del stock
      eliminado: 0,
    ));

    await dbHelper.insertProductosListaPrecio(ProductosListaPreciosModel(
      productId: 2,
      referenciaVariacion: 'Var1',
      listaId: 1,
      precioLista: getRandomPrice(),
      comercioId: 1,
      eliminado: 0,
    ));

    await dbHelper.insertProductosListaPrecio(ProductosListaPreciosModel(
      productId: 4,
      referenciaVariacion: 'Var1',
      listaId: 2,
      precioLista: getRandomPrice(),
      comercioId: 1,
      eliminado: 0,
    ));

    await dbHelper.insertProductosListaPrecio(ProductosListaPreciosModel(
      productId: 4,
      referenciaVariacion: 'Var1',
      listaId:1,
      precioLista: getRandomPrice(),
      comercioId: 1,
      eliminado: 0,
    ));

    await dbHelper.insertProductosStockSucursal(ProductosStockSucursalesModel(
      productId: 1,
      referenciaVariacion: 'Var1',
      comercioId: 1,
      sucursalId: 1,
      almacenId: 1,
      stock: 200,
      stockReal: 200, // 90% del stock
      eliminado: 0,
    ));
    final randomStock3 = getRandomStock();
    await dbHelper.insertProductosStockSucursal(ProductosStockSucursalesModel(
      productId: 3,
      referenciaVariacion: 'Var1',
      comercioId: 1,
      sucursalId: 1,
      almacenId: 1,
      stock: 200,
      stockReal: 200, // 90% del stock
      eliminado: 0,
    ));
    final randomStock2 = getRandomStock();
    await dbHelper.insertProductosStockSucursal(ProductosStockSucursalesModel(
      productId: 2,
      referenciaVariacion: 'Var1',
      comercioId: 1,
      sucursalId: 1,
      almacenId: 1,
      stock: 200,
      stockReal: 200, // 90% del stock
      eliminado: 0,
    ));
  }
}
