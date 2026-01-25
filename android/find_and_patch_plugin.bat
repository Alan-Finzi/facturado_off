@echo off
setlocal enabledelayedexpansion

echo ======================================================================
echo Script para localizar y parchar el plugin flutter_barcode_scanner
echo ======================================================================

REM Crear directorio para el archivo de log
if not exist ".\log" mkdir ".\log"
set "LOG_FILE=.\log\plugin_patch_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "LOG_FILE=!LOG_FILE: =0!"

echo Iniciando búsqueda del plugin flutter_barcode_scanner... > %LOG_FILE%
echo Hora de inicio: %time% >> %LOG_FILE%
echo. >> %LOG_FILE%

REM Verificar si el plugin local existe
if exist "..\local_plugins\flutter_barcode_scanner\android\build.gradle" (
    echo Plugin local encontrado en ..\local_plugins\flutter_barcode_scanner\android\build.gradle
    echo Plugin local encontrado en ..\local_plugins\flutter_barcode_scanner\android\build.gradle >> %LOG_FILE%

    echo Verificando namespace en plugin local...
    type "..\local_plugins\flutter_barcode_scanner\android\build.gradle" | findstr "namespace" > nul
    if !errorlevel! equ 0 (
        echo [OK] Plugin local ya tiene namespace configurado.
        echo [OK] Plugin local ya tiene namespace configurado. >> %LOG_FILE%
    ) else (
        echo [WARN] Plugin local no tiene namespace configurado. Añadiendo...
        echo [WARN] Plugin local no tiene namespace configurado. Añadiendo... >> %LOG_FILE%

        REM Crear copia de seguridad
        copy "..\local_plugins\flutter_barcode_scanner\android\build.gradle" "..\local_plugins\flutter_barcode_scanner\android\build.gradle.bak" > nul

        REM Añadir namespace
        powershell -Command "(Get-Content '..\local_plugins\flutter_barcode_scanner\android\build.gradle') -replace 'android \{', 'android {\n    namespace \"com.amolg.flutterbarcodescanner\"' | Set-Content '..\local_plugins\flutter_barcode_scanner\android\build.gradle'"

        echo Namespace añadido al plugin local.
        echo Namespace añadido al plugin local. >> %LOG_FILE%
    )
    goto :done
)

echo Buscando plugin en las rutas estándar...
echo Buscando plugin en las rutas estándar... >> %LOG_FILE%

set "FOUND_PLUGIN=false"

REM Lista de posibles ubicaciones donde buscar el plugin
set "LOCATIONS_TO_CHECK="
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %USERPROFILE%\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-2.0.0\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %USERPROFILE%\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-*\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_barcode_scanner-*\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %USERPROFILE%\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_barcode_scanner-*\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %FLUTTER_ROOT%\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-*\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %FLUTTER_ROOT%\bin\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-*\android"
set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK! %USERPROFILE%\.gradle\caches\modules-2\files-2.1\*\*\*\flutter_barcode_scanner*"

REM Comprobar ubicaciones específicas
for %%L in (%LOCATIONS_TO_CHECK%) do (
    echo Comprobando en: %%L
    echo Comprobando en: %%L >> %LOG_FILE%

    if exist "%%L\build.gradle" (
        echo [FOUND] Plugin encontrado en %%L
        echo [FOUND] Plugin encontrado en %%L >> %LOG_FILE%
        set "PLUGIN_DIR=%%L"
        set "FOUND_PLUGIN=true"

        REM Verificar si ya tiene namespace
        type "%%L\build.gradle" | findstr "namespace" > nul
        if !errorlevel! equ 0 (
            echo [OK] El plugin ya tiene namespace configurado.
            echo [OK] El plugin ya tiene namespace configurado. >> %LOG_FILE%
        ) else (
            echo [PATCHING] Añadiendo namespace al plugin...
            echo [PATCHING] Añadiendo namespace al plugin... >> %LOG_FILE%

            REM Crear copia de seguridad
            copy "%%L\build.gradle" "%%L\build.gradle.bak" > nul

            REM Añadir namespace
            powershell -Command "(Get-Content '%%L\build.gradle') -replace 'android \{', 'android {\n    namespace \"com.amolg.flutterbarcodescanner\"' | Set-Content '%%L\build.gradle'"

            echo Namespace añadido correctamente.
            echo Namespace añadido correctamente. >> %LOG_FILE%
        )
        goto :done
    )
)

REM Búsqueda más amplia si no se encontró en ubicaciones estándar
echo No se encontró el plugin en ubicaciones estándar. Realizando búsqueda ampliada...
echo No se encontró el plugin en ubicaciones estándar. Realizando búsqueda ampliada... >> %LOG_FILE%

REM Usar donde flutter para encontrar ubicación de Flutter
for /f "tokens=*" %%f in ('where flutter 2^>nul') do (
    set "FLUTTER_PATH=%%f"
)

if defined FLUTTER_PATH (
    echo Flutter encontrado en: !FLUTTER_PATH!
    echo Flutter encontrado en: !FLUTTER_PATH! >> %LOG_FILE%

    REM Extraer directorio Flutter
    for %%F in ("!FLUTTER_PATH!") do set "FLUTTER_DIR=%%~dpF"

    REM Buscar en .pub-cache relativo a Flutter
    echo Buscando en caché de Flutter: !FLUTTER_DIR!
    echo Buscando en caché de Flutter: !FLUTTER_DIR! >> %LOG_FILE%

    set "PUB_CACHE_DIR=!FLUTTER_DIR!.pub-cache"

    if exist "!PUB_CACHE_DIR!" (
        echo Buscando en !PUB_CACHE_DIR!
        echo Buscando en !PUB_CACHE_DIR! >> %LOG_FILE%

        for /r "!PUB_CACHE_DIR!" %%G in (*flutter_barcode_scanner*build.gradle) do (
            echo [FOUND] Plugin encontrado en %%G
            echo [FOUND] Plugin encontrado en %%G >> %LOG_FILE%
            set "PLUGIN_DIR=%%~dpG"
            set "FOUND_PLUGIN=true"

            REM Verificar si ya tiene namespace
            type "%%G" | findstr "namespace" > nul
            if !errorlevel! equ 0 (
                echo [OK] El plugin ya tiene namespace configurado.
                echo [OK] El plugin ya tiene namespace configurado. >> %LOG_FILE%
            ) else (
                echo [PATCHING] Añadiendo namespace al plugin...
                echo [PATCHING] Añadiendo namespace al plugin... >> %LOG_FILE%

                REM Crear copia de seguridad
                copy "%%G" "%%G.bak" > nul

                REM Añadir namespace
                powershell -Command "(Get-Content '%%G') -replace 'android \{', 'android {\n    namespace \"com.amolg.flutterbarcodescanner\"' | Set-Content '%%G'"

                echo Namespace añadido correctamente.
                echo Namespace añadido correctamente. >> %LOG_FILE%
            )
            goto :done
        )
    )
)

REM Si no se encontró, implementar solución alternativa usando plugin local
if "%FOUND_PLUGIN%"=="false" (
    echo [WARNING] No se pudo encontrar el plugin flutter_barcode_scanner en ninguna ubicación.
    echo [WARNING] No se pudo encontrar el plugin flutter_barcode_scanner en ninguna ubicación. >> %LOG_FILE%

    echo Implementando solución con plugin local...
    echo Implementando solución con plugin local... >> %LOG_FILE%

    REM Asegurarse de que el directorio local_plugins exista
    if not exist "..\local_plugins\flutter_barcode_scanner\android\" (
        echo Creando estructura del plugin local...
        echo Creando estructura del plugin local... >> %LOG_FILE%

        REM Crear directorios
        mkdir "..\local_plugins\flutter_barcode_scanner\android\src\main\java\com\amolg\flutterbarcodescanner" 2>nul
        mkdir "..\local_plugins\flutter_barcode_scanner\lib" 2>nul
        mkdir "..\local_plugins\flutter_barcode_scanner\ios\Classes" 2>nul

        REM Crear build.gradle con namespace
        echo group 'com.amolg.flutterbarcodescanner'> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo version '1.0'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo buildscript {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     repositories {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         google()>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         mavenCentral()>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     dependencies {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         classpath 'com.android.tools.build:gradle:8.2.0'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo rootProject.allprojects {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     repositories {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         google()>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         mavenCentral()>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo apply plugin: 'com.android.library'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo android {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     namespace 'com.amolg.flutterbarcodescanner'  // Configuración de namespace>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     compileSdkVersion 34>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     defaultConfig {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         minSdkVersion 16>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         targetSdkVersion 34>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner">> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     lintOptions {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         disable 'InvalidPackage'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     compileOptions {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         sourceCompatibility JavaVersion.VERSION_1_8>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo         targetCompatibility JavaVersion.VERSION_1_8>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo.>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo dependencies {>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     implementation 'androidx.appcompat:appcompat:1.6.1'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     implementation 'androidx.legacy:legacy-support-v4:1.0.0'>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo     // Eliminada dependencia problemática me.dm7.barcodescanner:zxing>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"
        echo }>> "..\local_plugins\flutter_barcode_scanner\android\build.gradle"

        echo Plugin local creado correctamente.
        echo Plugin local creado correctamente. >> %LOG_FILE%
    )

    REM Verificar pubspec.yaml para asegurar que usa el plugin local
    echo Verificando configuración en pubspec.yaml...
    echo Verificando configuración en pubspec.yaml... >> %LOG_FILE%

    type "..\pubspec.yaml" | findstr /C:"flutter_barcode_scanner:" | findstr /C:"path:" > nul
    if !errorlevel! neq 0 (
        echo [WARNING] pubspec.yaml no está configurado para usar el plugin local.
        echo [WARNING] pubspec.yaml no está configurado para usar el plugin local. >> %LOG_FILE%
        echo Por favor, modifica pubspec.yaml para usar el plugin local:
        echo.
        echo   # flutter_barcode_scanner: ^2.0.0  # Comentar esta línea
        echo   flutter_barcode_scanner:
        echo     path: ./local_plugins/flutter_barcode_scanner
    )
)

:done
echo ======================================================================
echo Proceso completado.
echo Consulta el log en: %LOG_FILE%
echo ======================================================================
endlocal