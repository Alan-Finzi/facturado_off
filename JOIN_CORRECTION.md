# Corrección de Consulta SQL para Cargar Stock y Precios

## Problema Identificado
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

Se modificaron las condiciones de JOIN para:

1. **Relacionar correctamente variaciones**:
   ```sql
   AND (pss.referencia_variacion = v.referencia_variacion OR pss.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
   ```
   
2. **Considerar la lista de precios predeterminada**:
   ```sql
   AND (plp.lista_id = ? OR plp.lista_id = 0)
   ```
   
3. **Manejar productos sin variaciones**:
   ```sql
   AND (plp.referencia_variacion = v.referencia_variacion OR plp.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
   ```

## Cambios Específicos

Las condiciones de JOIN originales:
```sql
LEFT JOIN productos_stock_sucursales pss 
  ON p.id = pss.product_id 
  AND (pss.sucursal_id = ? OR pss.sucursal_id IS NULL)
LEFT JOIN productos_lista_precios plp 
  ON p.id = plp.product_id 
  AND (plp.lista_id = ? OR plp.lista_id IS NULL)
```

Se modificaron a:
```sql
LEFT JOIN productos_stock_sucursales pss 
  ON p.id = pss.product_id 
  AND (pss.sucursal_id = ? OR pss.sucursal_id IS NULL)
  AND (pss.referencia_variacion = v.referencia_variacion OR pss.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
LEFT JOIN productos_lista_precios plp 
  ON p.id = plp.product_id 
  AND (plp.lista_id = ? OR plp.lista_id = 0)
  AND (plp.referencia_variacion = v.referencia_variacion OR plp.referencia_variacion = '0' OR v.referencia_variacion IS NULL)
```

## Beneficios

1. **Carga completa de datos**: Ahora se cargan correctamente los stocks y precios, tanto para productos con variaciones como para productos sin ellas.

2. **Soporte para lista predeterminada**: Se incluyen precios de la lista predeterminada (`lista_id = 0`) si el producto no tiene precio en la lista específica.

3. **Mejor compatibilidad con el API**: La consulta ahora refleja mejor la estructura de datos que devuelve la API, facilitando la sincronización y actualizaciones futuras.