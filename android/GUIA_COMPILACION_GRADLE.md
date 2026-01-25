# Guía de Compilación con Gradle 8.2

Esta guía proporciona instrucciones detalladas para compilar el proyecto utilizando Gradle 8.2 y resolver problemas comunes durante el proceso.

## Cambios realizados para Gradle 8.2

1. **Actualización del wrapper de Gradle**:
   - Se actualizó `gradle-wrapper.properties` de la versión 7.6.3 a la versión 8.2
   - Esta actualización es necesaria para compatibilidad con las últimas versiones del Android Gradle Plugin

2. **Actualización de la sintaxis de Clean Task**:
   - Se modificó `tasks.register("clean", Delete) { delete rootProject.buildDir }` a
   - `tasks.register("clean", Delete) { delete = [rootProject.buildDir] }`
   - Este cambio es necesario debido a cambios en la API de Gradle

3. **Archivo settings.gradle.kts**:
   - Se creó una versión Kotlin DSL del archivo de configuración para mejor compatibilidad
   - Se especificaron versiones explícitas para los plugins Android

## Pasos para compilar el proyecto

1. **Verificar entorno Java**:
   ```bash
   cd android
   # Ejecutar este script para verificar la configuración de Java
   .\check_java.bat
   cd ..
   ```

2. **Preparar el plugin barcode scanner**:
   ```bash
   cd android
   # Ejecutar este script para encontrar y parchar el plugin barcode scanner
   .\find_and_patch_plugin.bat
   cd ..
   ```

3. **Limpiar el proyecto**:
   ```bash
   flutter clean
   ```

4. **Actualizar dependencias**:
   ```bash
   flutter pub get
   ```

5. **Compilar en modo release**:
   ```bash
   flutter build apk --release
   ```

Si encuentras problemas de compilación con el modo release, puedes intentar:
```bash
flutter build apk --release --no-shrink
```

## Solución de problemas comunes

### 1. Error "Minimum supported Gradle version is 8.2"

**Problema**:
```
Minimum supported Gradle version is 8.2. Current version is 7.6.3.
```

**Solución**:
- Verificar que el archivo `android/gradle/wrapper/gradle-wrapper.properties` contiene:
  ```
  distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
  ```
- Si necesitas actualizar manualmente, ejecuta:
  ```bash
  cd android
  .\gradlew wrapper --gradle-version=8.2
  ```

### 2. Plugin flutter_barcode_scanner no encontrado

**Problema**:
```
WARNING: Could not find flutter_barcode_scanner build.gradle file to patch
```

**Solución**:
- Ejecutar script para localizar y parchar el plugin:
  ```bash
  cd android
  .\find_and_patch_plugin.bat
  ```
- Si sigue fallando, verificar que pubspec.yaml use la versión local:
  ```yaml
  flutter_barcode_scanner:
    path: ./local_plugins/flutter_barcode_scanner
  ```

### 3. Error de compilación con archivo settings.gradle

**Problema**:
```
Build file 'C:\...\android\settings.gradle' line: xxx
```

**Solución**:
- Usar el nuevo archivo settings.gradle.kts:
  ```bash
  cd android
  # Renombrar el original para preservarlo
  ren settings.gradle settings.gradle.backup
  # Ya se debería estar usando settings.gradle.kts
  ```

### 4. Errores de compatibilidad JVM entre Java y Kotlin

**Problema**:
```
Execution failed for task ':app:compileReleaseKotlin'.
> Inconsistent JVM-target compatibility detected for tasks 'compileReleaseJavaWithJavac' (1.8) and 'compileReleaseKotlin' (17).
```

**Solución**:
Hay dos partes a resolver:

1. **Alinear todas las versiones JVM target**:
   - Modificar `android/app/build.gradle`:
   ```gradle
   compileOptions {
       sourceCompatibility JavaVersion.VERSION_17
       targetCompatibility JavaVersion.VERSION_17
   }

   kotlinOptions {
       jvmTarget = "17"
   }
   ```

   - También modificar `local_plugins/flutter_barcode_scanner/android/build.gradle` con la misma configuración

2. **Añadir flag para ignorar validación JVM target**:
   - Añadir al archivo `android/gradle.properties`:
   ```
   kotlin.jvm.target.validation.mode=IGNORE
   ```

3. **Verificar instalación de Java 17**:
   ```bash
   java -version
   ```
   - Si no tienes Java 17, descárgalo de [Eclipse Temurin JDK 17](https://adoptium.net/)

4. **Ejecutar script de verificación**:
   ```bash
   cd android
   .\check_java.bat
   ```

## Verificación de entorno

Es importante verificar que tu entorno de desarrollo cumpla con estos requisitos:

1. **Android Studio**: Versión 2022.3.1 (Giraffe) o superior
2. **Java Development Kit (JDK)**: Versión 17
3. **Gradle**: Versión 8.2
4. **Android Gradle Plugin (AGP)**: Versión 8.2.0
5. **Flutter**: Versión 3.19.x o superior
6. **NDK**: Versión 25.1.8937393

Para verificar las versiones de Gradle y AGP:

```bash
cd android
.\gradlew --version
```

## Notas sobre dependencias

Algunas dependencias pueden no ser compatibles con Gradle 8.2. En ese caso, considera:

1. Buscar actualizaciones de los paquetes
2. Usar versiones fork o fijadas
3. Implementar soluciones locales como se hizo con flutter_barcode_scanner

## Recursos adicionales

- [Guía oficial de migración a Gradle 8.2](https://docs.gradle.org/8.2/release-notes.html)
- [Documentación de Android Gradle Plugin](https://developer.android.com/build)