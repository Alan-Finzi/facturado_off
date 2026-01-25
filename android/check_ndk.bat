@echo off
REM Script para verificar y descargar NDK si falta

echo Verificando NDK version 25.1.8937393...

REM Obtener la ruta al SDK de Android
set "ANDROID_SDK_ROOT="
if defined ANDROID_HOME (
    set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
) else if defined ANDROID_SDK_ROOT (
    REM Ya está definido
    echo ANDROID_SDK_ROOT ya definido: %ANDROID_SDK_ROOT%
) else (
    REM Intentar encontrar el SDK
    if exist "%USERPROFILE%\AppData\Local\Android\Sdk" (
        set "ANDROID_SDK_ROOT=%USERPROFILE%\AppData\Local\Android\Sdk"
    ) else if exist "C:\Android\Sdk" (
        set "ANDROID_SDK_ROOT=C:\Android\Sdk"
    )
)

if not defined ANDROID_SDK_ROOT (
    echo ERROR: No se pudo encontrar el SDK de Android.
    echo Instala Android Studio o define la variable ANDROID_SDK_ROOT.
    exit /b 1
)

echo Usando SDK de Android en: %ANDROID_SDK_ROOT%

REM Verificar si el NDK ya está instalado
set "NDK_PATH=%ANDROID_SDK_ROOT%\ndk\25.1.8937393"
if exist "%NDK_PATH%" (
    echo NDK 25.1.8937393 ya está instalado en: %NDK_PATH%
) else (
    echo NDK 25.1.8937393 no encontrado.
    echo Opciones:
    echo 1. Abre Android Studio ^> SDK Manager ^> SDK Tools ^> Selecciona "NDK (Side by side)" ^> Apply
    echo 2. Después de instalar, asegúrate de usar la versión correcta en build.gradle:
    echo    android {
    echo        ndkVersion "25.1.8937393"
    echo        ...
    echo    }

    set /p instalar="¿Deseas intentar instalar el NDK automáticamente? (S/N): "
    if /i "%instalar%"=="S" (
        echo Intentando instalar NDK usando sdkmanager...
        "%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" "ndk;25.1.8937393" --verbose

        if exist "%NDK_PATH%" (
            echo NDK instalado exitosamente en: %NDK_PATH%
        ) else (
            echo Falló la instalación automática. Por favor instala manualmente desde Android Studio.
        )
    )
)

REM Verificar la versión de Gradle
echo.
echo Verificando versión de Gradle...
if exist ".\gradlew.bat" (
    call .\gradlew.bat --version | findstr "Gradle"
) else (
    echo Gradle wrapper no encontrado. Considera ejecutar 'flutter create --platforms=android .'
)

REM Mostrar configuración actual de NDK en build.gradle
echo.
echo Verificando configuración en build.gradle...
findstr /C:"ndkVersion" ".\app\build.gradle"

echo.
echo Verificación completa. Si encuentras problemas, asegúrate de que:
echo 1. NDK 25.1.8937393 esté instalado
echo 2. build.gradle tenga 'ndkVersion "25.1.8937393"'
echo 3. Se hayan aplicado todos los parches del plugin barcode scanner