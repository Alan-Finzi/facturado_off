# Corrección de Consulta SQL para Cargar Stock y Precios

## Actualización: Optimización Adicional (2025-08-18)

Se realizó una optimización adicional a la consulta para mejorar su rendimiento y precisión:

```sql
LEFT JOIN productos_stock_sucursales pss 
  ON p.id = pss.product_id 
  AND pss.sucursal_id = ?
  AND (pss.referencia_variacion = COALESCE(v.referencia_variacion, '0'))
LEFT JOIN productos_lista_precios plp 
  ON p.id = plp.product_id 
  AND plp.lista_id = ?
  AND (plp.referencia_variacion = COALESCE(v.referencia_variacion, '0'))
```

Esta mejora:

1. **Utiliza COALESCE para manejo de valores nulos**: Reemplaza los múltiples OR por una sola función COALESCE que devuelve '0' cuando v.referencia_variacion es NULL, simplificando la condición.

2. **Elimina condiciones innecesarias**: Quita la verificación OR para valores nulos de sucursal_id y lista_id, haciendo la consulta más precisa.

3. **Mejora el rendimiento**: La consulta más simple permite mejor optimización por parte del motor de base de datos.

4. **Asegura correspondencia exacta**: Garantiza que solo se consideren las relaciones exactas entre productos y sus precios/stocks.

---

## Problema Identificado Inicialmente
Se identificó un problema donde los stocks y precios de lista no se estaban cargando correctamente en el método `getProductoResponseBySucursalId`. Después de analizar el código y compararlo con la estructura de datos que devuelve la API, se determinó que las condiciones de JOIN entre las tablas estaban incompletas.

## Análisis del Modelo de Datos
Al consultar la API `productos-ver`, se observó que:

1. Los productos contienen campos `stocks` y `listas_precios` como arreglos
2. Cada elemento en estos arreglos tiene un campo `referencia_variacion`
3. Los productos sin variaciones utilizan `"0"` como valor de `referencia_variacion`
4. La API relaciona correctamente productos, sus variaciones, stocks y precios

```json
{
  "id": 23745,
  "nombre": "Hielo 2,5kg",
  "barcode": "H",
  "producto_tipo": "s",
  "productos_variaciones": [],
  "stocks": [
    {
      "id": 62823,
      "product_id": 23745,
      "referencia_variacion": "0",
      "stock": "10.000",
      "sucursal_id": 615
    }
  ],
  "listas_precios": [
    {
      "id": 71159,
      "product_id": 23745,
      "referencia_variacion": "0",
      "precio_lista": "3000.00",
      "lista_id": 0
    }
  ]
}
```

## Problemas Identificados en la Consulta SQL

1. **Faltaba relacionar por `referencia_variacion`**: La consulta solo relacionaba productos con stocks y precios por `product_id` pero no consideraba el campo `referencia_variacion`.
   
2. **No se manejaban productos sin variaciones**: Muchos productos utilizan `"0"` como valor de `referencia_variacion` cuando no tienen variaciones específicas.

3. **No se consideraban precios de la lista predeterminada**: Los precios en la lista con `lista_id = 0` (lista predeterminada) no se estaban considerando.

## Solución Implementada

Se modificaron las condiciones de JOIN para usar COALESCE para manejar de manera más eficiente las referencias de variación y asegurar que siempre se utilice el valor correcto, ya sea de una variación específica o el valor predeterminado '0'.

## Beneficios

1. **Carga completa de datos**: Ahora se cargan correctamente los stocks y precios, tanto para productos con variaciones como para productos sin ellas.

2. **Mayor rendimiento**: Las condiciones simplificadas mejoran la velocidad de la consulta.

3. **Mayor precisión**: Se eliminan casos ambiguos que podían llevar a duplicación o falta de datos.

4. **Mejor compatibilidad con el API**: La consulta ahora refleja mejor la estructura de datos que devuelve la API, facilitando la sincronización y actualizaciones futuras.