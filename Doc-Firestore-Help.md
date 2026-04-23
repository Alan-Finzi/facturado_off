# Guía de configuración Firebase / Firestore

Este documento explica cómo conectar la app a un proyecto Firebase nuevo.  
Las credenciales NO están incluidas en el repositorio — cada entorno (desarrollo, producción) usa su propio proyecto Firebase.

---

## 1. Crear el proyecto Firebase

1. Ir a https://console.firebase.google.com
2. Clic en **"Agregar proyecto"**
3. Elegir un nombre (ej: `facturadoroff-produccion`)
4. Desactivar Google Analytics si no se necesita → **Crear proyecto**

---

## 2. Crear la base de datos Firestore

1. En el panel izquierdo ir a **Firestore Database**
2. Clic en **"Crear base de datos"**
3. Elegir modo:
   - **Producción** (recomendado): bloquea todo por defecto, configurar reglas manualmente
   - **Prueba**: permite lectura/escritura libre por 30 días
4. Elegir región: **`southamerica-east1`** (São Paulo — la más cercana para Argentina)

---

## 3. Registrar las plataformas en Firebase

Dentro del proyecto Firebase, ir a **Configuración del proyecto → Tus apps** y agregar:

### Android
- Package name: `com.ultrix.facturador_offline`
- Descargar `google-services.json` y copiarlo en `android/app/google-services.json`

### iOS (si aplica)
- Bundle ID: `com.ultrix.facturadorOffline`
- Descargar `GoogleService-Info.plist` y copiarlo en `ios/Runner/GoogleService-Info.plist`

### Web
- Registrar la app web en Firebase Console
- Los valores los va a generar `flutterfire configure` automáticamente (ver paso 4)

### Windows
- Registrar como app web adicional (Firebase usa la configuración web para Windows)

---

## 4. Generar firebase_options.dart (método recomendado)

Este archivo es generado automáticamente por la CLI de Firebase para Flutter.

```bash
# Instalar FlutterFire CLI (una sola vez)
dart pub global activate flutterfire_cli

# Dentro del directorio del proyecto, ejecutar:
flutterfire configure
```

Esto va a:
- Preguntar qué proyecto Firebase usar
- Preguntar qué plataformas configurar (Android, iOS, Web, Windows)
- Generar `lib/firebase_options.dart` con las claves correctas
- Actualizar `android/app/google-services.json` automáticamente

---

## 5. Reglas de seguridad de Firestore

### Para desarrollo / pruebas (acceso total)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Para producción (recomendado — ajustar según necesidad)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /ventas/{ventaId} {
      allow read, write: if true;
    }
    match /clientes/{clienteId} {
      allow read, write: if true;
    }
    match /productos/{productoId} {
      allow read: if true;
      allow write: if true;
    }
    match /users/{userId} {
      allow read, write: if true;
    }
    match /datos_facturacion/{docId} {
      allow read, write: if true;
    }
    match /payment_providers/{docId} {
      allow read, write: if true;
    }
    match /payment_methods/{docId} {
      allow read, write: if true;
    }
    match /productos_ivas/{docId} {
      allow read, write: if true;
    }
    match /categorias/{docId} {
      allow read, write: if true;
    }
  }
}
```

> Nota: la app usa su propio sistema de autenticación (API `flamincoapp.com.ar`), no Firebase Auth. Por eso las reglas no usan `request.auth`. Si en el futuro se integra Firebase Auth, las reglas pueden restringirse por usuario.

---

## 6. Índices de Firestore

Algunas consultas compuestas requieren índices. Firebase los sugiere automáticamente con un link en los logs cuando fallan.

Las consultas que pueden necesitar índice son:

| Colección | Campos indexados |
|-----------|-----------------|
| `ventas` | `comercio_id` + `eliminado` + `created_at` |
| `ventas` | `comercio_id` + `cliente_id` + `eliminado` |
| `ventas` | `comercio_id` + `eliminado` + `fecha` |
| `clientes` | `comercio_id` + `modificado` |
| `productos_ivas` | `comercio_id` |

Si aparece un error `FAILED_PRECONDITION` en los logs con un link de Firebase, abrirlo directamente para crear el índice faltante.

---

## 7. Estructura de colecciones en Firestore

### `users`
- **ID del documento**: email del usuario
- Campos: `id`, `username`, `email`, `password`, `comercio_id`, `sucursal`, `id_lista_precio`, `profile`, `status`, `nombre_usuario`, `apellido_usuario`

### `clientes`
- **ID del documento**: `idCliente` (string)
- Campos: `id_cliente`, `nombre`, `apellido`, `cuit`, `dni`, `email`, `comercio_id`, `lista_precio`, `modificado`

### `productos`
- **ID del documento**: id numérico del producto (string)
- Campos: `id`, `nombre`, `barcode`, `producto_tipo` (`"s"` = simple, `"v"` = con variaciones), `comercio_id`, `listas_precios` (array), `stocks` (array), `variaciones` (array)

### `productos_ivas`
- **ID del documento**: `{product_id}_{sucursal_id}_{comercio_id}`
- Campos: `product_id`, `comercio_id`, `sucursal_id`, `iva`

### `datos_facturacion`
- **ID del documento**: id numérico (string)
- Campos: `id`, `razon_social`, `comercio_id`, `condicion_iva`, `cuit`, `pto_venta`, `domicilio_fiscal`, `predeterminado`

### `payment_providers`
- **ID del documento**: id numérico (string)
- Campos: `id`, `nombre`, `comercio_id`

### `payment_methods`
- **ID del documento**: id numérico (string)
- Campos: `id`, `provider_id`, `nombre`, `recargo`

### `categorias`
- **ID del documento**: id numérico (string)
- Campos: `id`, `name`, `comercio_id`

### `ventas`
- **ID del documento**: timestamp en milisegundos (string)
- Campos: `id`, `id_venta`, `comercio_id`, `cliente_id`, `total`, `eliminado`, `sincronizado`, `fecha`, `created_at`, `updated_at`, `detalles` (array de items de venta)

---

## 8. Primer uso — flujo de sincronización

La app requiere una **sincronización inicial** con internet para poblar Firestore. El flujo es:

1. Usuario inicia sesión → la app se conecta a `api.flamincoapp.com.ar`
2. Si es el primer login → muestra `SynchronizationPage` que descarga todos los datos
3. Los datos se guardan en Firestore (productos, clientes, IVAs, etc.)
4. A partir de ahí, la app puede funcionar **sin internet** usando el caché de Firestore

Si el cliente tiene su propia API backend, el endpoint base está en `lib/services/service_api.dart`:
```dart
final String apiUrlLogin = 'https://api.flamincoapp.com.ar/api/login';
// ... etc
```

---

## 9. CORS para la versión web

Si la app web no puede conectarse a la API, el servidor backend necesita habilitar CORS.

**En Laravel** (`config/cors.php`):
```php
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

Y verificar que `HandleCors::class` esté en el grupo `api` del Kernel.

---

## 10. Resumen rápido para un developer nuevo

```bash
# 1. Clonar repo e instalar dependencias
flutter pub get

# 2. Configurar Firebase (tener Firebase CLI instalado)
dart pub global activate flutterfire_cli
flutterfire configure   # elegir el proyecto Firebase del cliente

# 3. Correr la app
flutter run             # Android/iOS
flutter run -d chrome   # Web
flutter run -d windows  # Windows
```

Si `flutterfire configure` no está disponible, crear `lib/firebase_options.dart` manualmente copiando la estructura del archivo existente y reemplazando los valores `TU_*` con los datos del proyecto Firebase (disponibles en Firebase Console → Configuración del proyecto).
