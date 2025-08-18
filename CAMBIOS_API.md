# Cambios en la estructura de APIs del proyecto

## Resumen de cambios
Se ha normalizado el uso de APIs en el proyecto para simplificar la arquitectura y mejorar el mantenimiento. Se ha consolidado toda la funcionalidad de productos (incluyendo stock y precios) en una única API (`apiUrlProductosVer`).

## APIs mantenidas
- **apiUrlUser**: Gestión de usuarios (`https://api.flamincoapp.com.ar/api/users?comercio_id=362`)
- **apiUrlClienteMostrador**: Gestión de clientes (`https://api.flamincoapp.com.ar/api/clientes?casa_central_id=362&comercio_id=362`)
- **apiUrlLogin**: Autenticación (`https://api.flamincoapp.com.ar/api/login`)
- **apiUrlProductosVer**: API principal para productos, variaciones, stocks y precios (`https://api.flamincoapp.com.ar/api/productos-ver`)
- **apiUrlProductoIva**: Información de IVA para productos (`https://api.flamincoapp.com.ar/api/producto-ivas`)
- **apiUrlDatosFacturacion**: Datos para facturación (`https://api.flamincoapp.com.ar/api/dato-facturacions`)
- **apiUrlCategoria**: Categorías de productos (`https://api.flamincoapp.com.ar/api/categories`)

## APIs eliminadas (reemplazadas por apiUrlProductosVer)
- ~~apiUrlProducto~~: Reemplazada por apiUrlProductosVer
- ~~apiUrlProductoListaPrecios~~: Reemplazada por apiUrlProductosVer
- ~~apiUrlProductoStockSucursals~~: Reemplazada por apiUrlProductosVer
- ~~apiUrlListaPrecios~~: Reemplazada por apiUrlProductosVer

## Métodos modificados
1. `fetchVariaciones(String token)`: 
   - Ahora es el método principal para obtener todos los datos de productos
   - Incluye variaciones, stocks y precios en una sola llamada
   - Se actualiza para usar `apiUrlProductosVer` con parámetro de comercio_id

## Métodos eliminados
- `fetchProductos(token)`: Funcionalidad cubierta por `fetchVariaciones`
- `fetchProductosListaPrecio(token)`: Funcionalidad cubierta por `fetchVariaciones`
- `fetchProductosStockSucursals(token)`: Funcionalidad cubierta por `fetchVariaciones`
- `fetchListaPrecio(token)`: Funcionalidad cubierta por `fetchVariaciones`

## Modelo de datos
Se mantiene el uso del modelo `ProductoResponse` como estructura principal que contiene:
- Datos de productos básicos
- Variaciones de productos
- Stock por sucursal
- Precios por lista

## Flujo de sincronización
El flujo de sincronización en `SynchronizationCubit` ha sido simplificado para eliminar las llamadas redundantes y mantener solo las APIs necesarias:
1. Usuarios y autenticación
2. IVAs de productos
3. Datos de facturación
4. Productos (variaciones, stocks, precios) - Todo a través de `fetchVariaciones`
5. Clientes
6. Categorías

## Beneficios del cambio
- Reducción del código redundante
- Menor número de llamadas a APIs
- Mejor mantenibilidad del código
- Mayor eficiencia en la sincronización de datos