@echo off
REM Script para Windows para aplicar parches a plugins de Flutter con problemas de namespace
REM Este script se debe ejecutar antes de compilar la aplicación

echo [33mIniciando parches para plugins de Flutter...[0m

REM Buscar ubicaciones posibles del plugin flutter_barcode_scanner
set PATCHED=false

REM Definir función para aplicar parche
:patch_plugin
set PLUGIN_DIR=%~1
set PATCH_FILE=%~2
set PLUGIN_NAME=%~3

if exist "%PLUGIN_DIR%" (
    echo [32mEncontrado %PLUGIN_NAME% en: %PLUGIN_DIR%[0m

    REM Verificar si existe build.gradle
    if exist "%PLUGIN_DIR%\build.gradle" (
        REM Hacer backup del archivo original si no existe
        if not exist "%PLUGIN_DIR%\build.gradle.orig" (
            copy "%PLUGIN_DIR%\build.gradle" "%PLUGIN_DIR%\build.gradle.orig"
            echo [32mCreado backup en: %PLUGIN_DIR%\build.gradle.orig[0m
        )

        REM Aplicar el parche
        copy "%PATCH_FILE%" "%PLUGIN_DIR%\build.gradle"
        echo [32mParche aplicado exitosamente a %PLUGIN_NAME% con configuración de namespace![0m
        set PATCHED=true
    ) else (
        echo [31mError: build.gradle no encontrado en %PLUGIN_DIR%[0m
    )
)
exit /b

REM Intentar parchar flutter_barcode_scanner
call :patch_plugin "%USERPROFILE%\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-2.0.0\android" ".\plugin-patches\flutter_barcode_scanner\build.gradle" "flutter_barcode_scanner"
if "%PATCHED%"=="true" goto end_patching

call :patch_plugin "%USERPROFILE%\.pub-cache\git\flutter_barcode_scanner\android" ".\plugin-patches\flutter_barcode_scanner\build.gradle" "flutter_barcode_scanner"
if "%PATCHED%"=="true" goto end_patching

call :patch_plugin "%USERPROFILE%\.flutter-plugins\flutter_barcode_scanner\android" ".\plugin-patches\flutter_barcode_scanner\build.gradle" "flutter_barcode_scanner"
if "%PATCHED%"=="true" goto end_patching

REM Si no hemos parchado nada, buscar en otras ubicaciones
echo [33mBuscando flutter_barcode_scanner en otras ubicaciones...[0m

REM Ver si podemos encontrar FLUTTER_ROOT
for /f "tokens=*" %%a in ('where flutter') do set FLUTTER_PATH=%%a
if not "%FLUTTER_PATH%"=="" (
    set FLUTTER_ROOT=%FLUTTER_PATH:~0,-11%
    call :patch_plugin "%FLUTTER_ROOT%\.pub-cache\hosted\pub.dev\flutter_barcode_scanner-2.0.0\android" ".\plugin-patches\flutter_barcode_scanner\build.gradle" "flutter_barcode_scanner"
    if "%PATCHED%"=="true" goto end_patching
)

REM Buscar en el directorio del proyecto local
for /f "tokens=*" %%a in ('dir /s /b ..\flutter_barcode_scanner-*\android') do (
    call :patch_plugin "%%a" ".\plugin-patches\flutter_barcode_scanner\build.gradle" "flutter_barcode_scanner"
    if "%PATCHED%"=="true" goto end_patching
)

:end_patching
if "%PATCHED%"=="false" (
    echo [31mAdvertencia: No se pudo encontrar el plugin flutter_barcode_scanner para aplicar parche[0m
    echo [33mPuede ser necesario agregar manualmente 'namespace \"com.amolg.flutterbarcodescanner\"' al build.gradle del plugin[0m
)

echo [32mProceso de aplicación de parches completado.[0m