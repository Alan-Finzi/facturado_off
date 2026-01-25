@echo off
REM Script para ejecutar la aplicación en emuladores con diferentes modos

echo Facturador Offline - Script de ejecución para emuladores
echo =======================================================
echo.

REM Verificar si hay un dispositivo conectado
flutter devices > devices_temp.txt
findstr /C:"No devices" devices_temp.txt > nul
if %errorlevel% EQU 0 (
    echo No se encontraron dispositivos. Por favor inicia un emulador o conecta un dispositivo.
    del devices_temp.txt
    exit /b 1
)
del devices_temp.txt

echo Opciones de ejecución en emulador:
echo 1. Modo Debug (recomendado para emuladores) - Mayor rendimiento de depuración
echo 2. Modo Profile - Mejor rendimiento con algunas herramientas de perfil
echo 3. Modo Release simulado (con --no-shrink) - Mejor rendimiento pero sin shrinking
echo 4. Salir
echo.

set /p option="Seleccione una opción: "

if "%option%"=="1" (
    echo Ejecutando en modo Debug...
    flutter run
) else if "%option%"=="2" (
    echo Ejecutando en modo Profile...
    flutter run --profile
) else if "%option%"=="3" (
    echo Ejecutando en modo Release simulado...

    REM Configurar temporalmente para ejecutar en modo release en emulador
    echo Modificando temporalmente build.gradle para modo release en emulador...

    REM Crear copia temporal del archivo
    copy /Y android\app\build.gradle android\app\build.gradle.bak > nul

    REM Modificar configuración para release
    powershell -Command "(Get-Content android\app\build.gradle) -replace 'minifyEnabled true', 'minifyEnabled false' -replace 'shrinkResources true', 'shrinkResources false' | Set-Content android\app\build.gradle"

    REM Ejecutar en modo release con flags adicionales
    flutter run --release --no-shrink

    REM Restaurar archivo original
    copy /Y android\app\build.gradle.bak android\app\build.gradle > nul
    del android\app\build.gradle.bak

    echo Configuración original restaurada.
) else if "%option%"=="4" (
    echo Saliendo...
    exit /b 0
) else (
    echo Opción inválida.
    exit /b 1
)