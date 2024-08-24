
import '../helper/database_helper.dart';
import '../models/lista_precio_model.dart';
import '../models/producto.dart';
import '../models/user.dart';

class DatabaseSeeder {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

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
        confirmed: 1,
        plan: 1,
        lastLogin: DateTime.now(),
        cantidadLogin: 5,
        comercioId: 1,
        clienteId: 1,
        image: 'path/to/image.png',
        casaCentralUserId: 1,
      ).toJson(),
    );

    // Insertar productos
    await dbHelper.insertProducto(ProductoModel(
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
  }
}