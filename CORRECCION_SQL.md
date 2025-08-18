# Corrección de Error SQL en Database Helper

## Problema Identificado

Se detectó un error en la consulta SQL en el método `getProductoResponseBySucursalId` dentro de `database_helper.dart`. El error específico era:

```
Error: no such column: pss.id
```

Este error ocurría porque la consulta SQL intentaba acceder a una columna `id` en la tabla `productos_stock_sucursales` (alias `pss`), pero esta columna no existe en dicha tabla.

## Análisis Realizado

1. Se verificó la estructura de la tabla `productos_stock_sucursales` en la definición de la base de datos:
```sql
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
```

2. Se confirmó que esta tabla no tiene una columna `id` independiente, sino que utiliza una clave primaria compuesta.

3. Se revisó el modelo `ProductosStockSucursalesModel` que también confirma la ausencia de un campo `id`:
```dart
class ProductosStockSucursalesModel {
  final int? productId;
  final String? referenciaVariacion;
  final int? comercioId;
  final int? sucursalId;
  final int? almacenId;
  final double? stock;
  final double? stockReal;
  final int? eliminado;
  // ...
}
```

4. Se verificó también la clase `Stock` en `productos_maestro.dart` que sí tiene un campo `id`, por lo que debemos mantener la compatibilidad:
```dart
class Stock {
  int? id;
  int? productId;
  String? referenciaVariacion;
  String? stock;
  int? sucursalId;
  dynamic sucursal;
  // ...
}
```

## Solución Implementada

La solución consistió en modificar la consulta SQL para usar `product_id` como identificador en lugar de un inexistente campo `id`. Se cambió:

```sql
-- Stock
pss.id AS stock_id,
pss.stock AS stock,
pss.stock_real AS stock_real,
pss.sucursal_id AS stock_sucursal_id,
```

A:

```sql
-- Stock (la tabla productos_stock_sucursales no tiene campo id)
pss.product_id AS stock_id,
pss.stock AS stock,
pss.stock_real AS stock_real,
pss.sucursal_id AS stock_sucursal_id,
```

Esto permite mantener la compatibilidad con el modelo `Stock` que espera un campo `id` mientras utiliza correctamente la estructura real de la tabla `productos_stock_sucursales`.

## Justificación

Esta solución es la más adecuada porque:

1. Mantiene la compatibilidad con el modelo `Stock` existente que espera un campo `id`
2. Utiliza un campo válido (`product_id`) de la tabla `productos_stock_sucursales`
3. No requiere cambios en otras partes del código que procesan estos datos
4. El valor de `product_id` funciona correctamente como identificador para los propósitos requeridos

El uso de `product_id` como `stock_id` es lógico ya que para cada producto se almacena una entrada de stock, y el procesamiento posterior en el código utiliza este valor principalmente para relaciones entre objetos.