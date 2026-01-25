@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo Verificador de configuración de Java para compilación
echo =======================================================
echo.

REM Verificar versión de Java
echo Comprobando versión de Java...
java -version 2>java_version.txt
type java_version.txt
echo.

REM Buscar versión de Java en el resultado
findstr /C:"version" java_version.txt > nul
if %errorlevel% equ 0 (
    findstr /C:"17" java_version.txt > nul
    if %errorlevel% equ 0 (
        echo [OK] Versión de Java compatible encontrada (Java 17).
    ) else (
        echo [ADVERTENCIA] No se detectó Java 17. Se recomienda usar Java 17 para compilar.
        echo Para instalar Java 17:
        echo 1. Visita https://adoptium.net/ y descarga Eclipse Temurin JDK 17
        echo 2. Instala y configura la variable JAVA_HOME
    )
) else (
    echo [ERROR] No se pudo detectar la versión de Java.
    echo Asegúrate de que Java está instalado y en el PATH.
)

echo.
del java_version.txt

REM Verificar configuración en build.gradle
echo Verificando configuraciones en archivos build.gradle...

set "APP_BUILD_GRADLE=..\android\app\build.gradle"
set "PLUGIN_BUILD_GRADLE=..\local_plugins\flutter_barcode_scanner\android\build.gradle"
set "GRADLE_PROPERTIES=..\android\gradle.properties"

if exist "%APP_BUILD_GRADLE%" (
    echo Revisando %APP_BUILD_GRADLE%...

    REM Verificar sourceCompatibility
    findstr /C:"sourceCompatibility JavaVersion.VERSION_17" "%APP_BUILD_GRADLE%" > nul
    if %errorlevel% equ 0 (
        echo [OK] sourceCompatibility está configurado a VERSION_17
    ) else (
        echo [ERROR] sourceCompatibility no está configurado a VERSION_17
        echo Edita %APP_BUILD_GRADLE% y cambia:
        echo     compileOptions {
        echo         sourceCompatibility JavaVersion.VERSION_17
        echo         targetCompatibility JavaVersion.VERSION_17
        echo     }
    )

    REM Verificar kotlinOptions
    findstr /C:"jvmTarget = \"17\"" "%APP_BUILD_GRADLE%" > nul
    if %errorlevel% equ 0 (
        echo [OK] kotlinOptions jvmTarget está configurado a 17
    ) else (
        echo [ERROR] kotlinOptions jvmTarget no está configurado o no es 17
        echo Edita %APP_BUILD_GRADLE% y añade:
        echo     kotlinOptions {
        echo         jvmTarget = "17"
        echo     }
    )
) else (
    echo [ERROR] No se encontró el archivo %APP_BUILD_GRADLE%
)

echo.

REM Verificar plugin barcode scanner
if exist "%PLUGIN_BUILD_GRADLE%" (
    echo Revisando %PLUGIN_BUILD_GRADLE%...

    REM Verificar sourceCompatibility
    findstr /C:"sourceCompatibility JavaVersion.VERSION_17" "%PLUGIN_BUILD_GRADLE%" > nul
    if %errorlevel% equ 0 (
        echo [OK] Plugin: sourceCompatibility está configurado a VERSION_17
    ) else (
        echo [ERROR] Plugin: sourceCompatibility no está configurado a VERSION_17
        echo Edita %PLUGIN_BUILD_GRADLE% y cambia:
        echo     compileOptions {
        echo         sourceCompatibility JavaVersion.VERSION_17
        echo         targetCompatibility JavaVersion.VERSION_17
        echo     }
    )

    REM Verificar kotlinOptions
    findstr /C:"jvmTarget = \"17\"" "%PLUGIN_BUILD_GRADLE%" > nul
    if %errorlevel% equ 0 (
        echo [OK] Plugin: kotlinOptions jvmTarget está configurado a 17
    ) else (
        echo [ADVERTENCIA] Plugin: kotlinOptions jvmTarget no está configurado o no es 17
        echo Considera añadir:
        echo     kotlinOptions {
        echo         jvmTarget = "17"
        echo     }
    )
) else (
    echo [ADVERTENCIA] No se encontró plugin local en %PLUGIN_BUILD_GRADLE%
)

echo.

REM Verificar gradle.properties
if exist "%GRADLE_PROPERTIES%" (
    echo Revisando %GRADLE_PROPERTIES%...

    findstr /C:"kotlin.jvm.target.validation.mode=IGNORE" "%GRADLE_PROPERTIES%" > nul
    if %errorlevel% equ 0 (
        echo [OK] kotlin.jvm.target.validation.mode=IGNORE está configurado
    ) else (
        echo [ADVERTENCIA] kotlin.jvm.target.validation.mode no está configurado a IGNORE
        echo Edita %GRADLE_PROPERTIES% y añade:
        echo kotlin.jvm.target.validation.mode=IGNORE
    )
) else (
    echo [ERROR] No se encontró el archivo %GRADLE_PROPERTIES%
)

echo.
echo =======================================================
echo Recomendaciones para compilación:
echo =======================================================
echo 1. Asegúrate de tener Java 17 instalado y configurado
echo 2. Verifica que todos los archivos build.gradle tengan:
echo    - compileOptions con sourceCompatibility JavaVersion.VERSION_17
echo    - kotlinOptions con jvmTarget = "17"
echo 3. En gradle.properties añade: kotlin.jvm.target.validation.mode=IGNORE
echo 4. Ejecuta: flutter clean
echo 5. Ejecuta: flutter pub get
echo 6. Compila con: flutter build apk --release
echo =======================================================

pause