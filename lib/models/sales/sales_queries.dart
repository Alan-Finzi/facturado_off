/// Clase que contiene las consultas SQL para las tablas de ventas
class SalesQueries {
  /// Consulta SQL para crear la tabla de ventas
  static const String createVentasTable = '''
CREATE TABLE IF NOT EXISTS ventas(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nro_venta TEXT,
  id_venta TEXT,
  fecha TEXT NOT NULL,
  comercio_id INTEGER NOT NULL,
  cliente_id INTEGER,
  domicilio_entrega TEXT,
  tipo_comprobante TEXT,
  datos_facturacion_id INTEGER,
  subtotal REAL NOT NULL,
  iva REAL NOT NULL,
  total REAL NOT NULL,
  descuento REAL DEFAULT 0.0,
  recargo REAL DEFAULT 0.0,
  metodo_pago TEXT NOT NULL,
  metodo_pago_detalles TEXT,
  sincronizado INTEGER DEFAULT 0,
  eliminado INTEGER DEFAULT 0,
  estado TEXT NOT NULL,
  user_id INTEGER,
  canal_venta TEXT,
  caja_id INTEGER,
  nota_interna TEXT,
  observaciones TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
  ''';

  /// Consulta SQL para crear la tabla de detalles de venta
  static const String createVentasDetalleTable = '''
CREATE TABLE IF NOT EXISTS ventas_detalle(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  venta_id INTEGER NOT NULL,
  producto_id INTEGER NOT NULL,
  codigo_producto TEXT,
  nombre_producto TEXT NOT NULL,
  descripcion TEXT,
  cantidad REAL NOT NULL,
  unidad_medida TEXT,
  precio_unitario REAL NOT NULL,
  porcentaje_iva REAL NOT NULL,
  monto_iva REAL NOT NULL,
  precio_final REAL NOT NULL,
  subtotal REAL NOT NULL,
  total REAL NOT NULL,
  descuento REAL DEFAULT 0.0,
  monto_descuento REAL DEFAULT 0.0,
  nota_interna TEXT,
  observaciones TEXT,
  sincronizado INTEGER DEFAULT 0,
  eliminado INTEGER DEFAULT 0,
  categoria_id INTEGER,
  categoria_nombre TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (venta_id) REFERENCES ventas (id) ON DELETE CASCADE
);
  ''';

  /// Consulta SQL para insertar una venta
  static const String insertVenta = '''
INSERT INTO ventas (
  nro_venta,
  id_venta,
  fecha,
  comercio_id,
  cliente_id,
  domicilio_entrega,
  tipo_comprobante,
  datos_facturacion_id,
  subtotal,
  iva,
  total,
  descuento,
  recargo,
  metodo_pago,
  metodo_pago_detalles,
  sincronizado,
  eliminado,
  estado,
  user_id,
  canal_venta,
  caja_id,
  nota_interna,
  observaciones,
  created_at,
  updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
  ''';

  /// Consulta SQL para insertar un detalle de venta
  static const String insertVentaDetalle = '''
INSERT INTO ventas_detalle (
  venta_id,
  producto_id,
  codigo_producto,
  nombre_producto,
  descripcion,
  cantidad,
  unidad_medida,
  precio_unitario,
  porcentaje_iva,
  monto_iva,
  precio_final,
  subtotal,
  total,
  descuento,
  monto_descuento,
  nota_interna,
  observaciones,
  sincronizado,
  eliminado,
  categoria_id,
  categoria_nombre,
  created_at,
  updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
  ''';

  /// Consulta SQL para actualizar una venta
  static const String updateVenta = '''
UPDATE ventas SET
  nro_venta = ?,
  id_venta = ?,
  fecha = ?,
  comercio_id = ?,
  cliente_id = ?,
  domicilio_entrega = ?,
  tipo_comprobante = ?,
  datos_facturacion_id = ?,
  subtotal = ?,
  iva = ?,
  total = ?,
  descuento = ?,
  recargo = ?,
  metodo_pago = ?,
  metodo_pago_detalles = ?,
  sincronizado = ?,
  eliminado = ?,
  estado = ?,
  user_id = ?,
  canal_venta = ?,
  caja_id = ?,
  nota_interna = ?,
  observaciones = ?,
  updated_at = ?
WHERE id = ?;
  ''';

  /// Consulta SQL para actualizar un detalle de venta
  static const String updateVentaDetalle = '''
UPDATE ventas_detalle SET
  venta_id = ?,
  producto_id = ?,
  codigo_producto = ?,
  nombre_producto = ?,
  descripcion = ?,
  cantidad = ?,
  unidad_medida = ?,
  precio_unitario = ?,
  porcentaje_iva = ?,
  monto_iva = ?,
  precio_final = ?,
  subtotal = ?,
  total = ?,
  descuento = ?,
  monto_descuento = ?,
  nota_interna = ?,
  observaciones = ?,
  sincronizado = ?,
  eliminado = ?,
  categoria_id = ?,
  categoria_nombre = ?,
  updated_at = ?
WHERE id = ?;
  ''';

  /// Consulta SQL para obtener todas las ventas
  static const String getAllVentas = '''
SELECT * FROM ventas WHERE eliminado = 0 ORDER BY fecha DESC;
  ''';

  /// Consulta SQL para obtener una venta por ID
  static const String getVentaById = '''
SELECT * FROM ventas WHERE id = ? AND eliminado = 0;
  ''';

  /// Consulta SQL para obtener los detalles de una venta
  static const String getVentaDetalleByVentaId = '''
SELECT * FROM ventas_detalle WHERE venta_id = ? AND eliminado = 0;
  ''';

  /// Consulta SQL para borrado lógico de una venta
  static const String softDeleteVenta = '''
UPDATE ventas SET eliminado = 1, updated_at = ? WHERE id = ?;
  ''';

  /// Consulta SQL para borrado lógico de los detalles de una venta
  static const String softDeleteVentaDetalleByVentaId = '''
UPDATE ventas_detalle SET eliminado = 1, updated_at = ? WHERE venta_id = ?;
  ''';

  /// Consulta SQL para borrado físico de una venta
  static const String hardDeleteVenta = '''
DELETE FROM ventas WHERE id = ?;
  ''';

  /// Consulta SQL para borrado físico de los detalles de una venta
  static const String hardDeleteVentaDetalleByVentaId = '''
DELETE FROM ventas_detalle WHERE venta_id = ?;
  ''';

  /// Consulta SQL para marcar una venta como sincronizada
  static const String markVentaAsSincronizada = '''
UPDATE ventas SET sincronizado = 1, updated_at = ? WHERE id = ?;
  ''';

  /// Consulta SQL para marcar los detalles de una venta como sincronizados
  static const String markVentaDetalleAsSincronizada = '''
UPDATE ventas_detalle SET sincronizado = 1, updated_at = ? WHERE venta_id = ?;
  ''';

  /// Consulta SQL para obtener ventas no sincronizadas
  static const String getVentasNoSincronizadas = '''
SELECT * FROM ventas WHERE sincronizado = 0 AND eliminado = 0;
  ''';

  /// Consulta SQL para obtener ventas por cliente
  static const String getVentasByClienteId = '''
SELECT * FROM ventas WHERE cliente_id = ? AND eliminado = 0 ORDER BY fecha DESC;
  ''';

  /// Consulta SQL para obtener ventas por período
  static const String getVentasByPeriodo = '''
SELECT * FROM ventas
WHERE fecha BETWEEN ? AND ?
AND eliminado = 0
ORDER BY fecha DESC;
  ''';

  /// Consulta SQL para obtener el total de ventas por período
  static const String getTotalVentasByPeriodo = '''
SELECT SUM(total) as total FROM ventas
WHERE fecha BETWEEN ? AND ?
AND eliminado = 0;
  ''';

  /// Consulta SQL para obtener el conteo de ventas por estado
  static const String getVentasCountByEstado = '''
SELECT estado, COUNT(*) as cantidad FROM ventas
WHERE eliminado = 0
GROUP BY estado;
  ''';
}