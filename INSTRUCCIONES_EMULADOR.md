# Ejecución de Facturador Offline en Emuladores

Este documento contiene instrucciones para ejecutar la aplicación en emuladores Android, abordando el problema común de "Release mode is not supported by Android SDK built for x86".

## El Problema

Cuando intentas ejecutar la aplicación en modo release en un emulador, es posible que veas el siguiente error:

```
Release mode is not supported by Android SDK built for x86.
```

Esto ocurre porque:

1. Los emuladores Android generalmente usan arquitectura x86 para mejor rendimiento
2. El modo release está optimizado para dispositivos físicos con arquitecturas ARM
3. Algunas optimizaciones de release no son compatibles con emuladores x86

## Soluciones Implementadas

### 1. Añadido soporte x86 en build.gradle

Hemos actualizado el archivo `android/app/build.gradle` para incluir soporte para arquitectura x86:

```gradle
ndk {
    abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64', 'x86'
}

splits {
    abi {
        enable true
        reset()
        include 'armeabi-v7a', 'arm64-v8a', 'x86_64', 'x86'
        universalApk true
    }
}
```

### 2. Script de ejecución para emuladores

Hemos creado un script `run_on_emulator.bat` que ofrece varias opciones de ejecución:

- **Modo Debug**: Ejecución normal para desarrollo y depuración
- **Modo Profile**: Mejor rendimiento con algunas herramientas de perfil
- **Modo Release Simulado**: Versión modificada del modo release que funciona en emuladores

## Opciones para Ejecutar en Emuladores

### Opción 1: Usar el script run_on_emulator.bat

La forma más sencilla es usar el script:

```
run_on_emulator.bat
```

Selecciona la opción que necesites.

### Opción 2: Ejecutar manualmente en modo debug o profile

```bash
flutter run              # Modo debug
flutter run --profile    # Modo profile
```

### Opción 3: Crear un emulador compatible con modo release

1. Abre Android Studio > Device Manager
2. Crea un nuevo dispositivo virtual
3. Selecciona una imagen del sistema con "Google Play" (no "Google APIs")
4. Configura y crea el emulador
5. Ejecuta con `flutter run --release`

### Opción 4: Ejecutar en dispositivo físico

Para pruebas finales, siempre es mejor usar un dispositivo físico:

```bash
flutter run --release
```

## Solución de Problemas Comunes

### Error de compilación en modo release

Si encuentras errores de compilación en modo release, intenta:

```bash
flutter clean
flutter pub get
flutter run --release
```

### Error con minificación

Si el problema está relacionado con la minificación, puedes usar:

```bash
flutter run --release --no-shrink
```

### Rendimiento lento en emulador

Si la aplicación es lenta en el emulador:

1. Asegúrate de que tu hardware tiene virtualización habilitada (VT-x/AMD-V)
2. Usa un emulador con aceleración por hardware
3. Reduce la resolución del emulador
4. Ejecuta en modo profile en lugar de debug

## Nota Final

El modo release está diseñado para dispositivos físicos. Aunque estas soluciones pueden funcionar en emuladores, para probar completamente la aplicación en su configuración final, siempre es mejor usar un dispositivo físico.