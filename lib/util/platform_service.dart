import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clase de servicio para gestionar la detección y configuración de plataformas
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();

  factory PlatformService() {
    return _instance;
  }

  PlatformService._internal();

  /// Canal de método para comunicación con código nativo iOS
  static const MethodChannel _iosChannel =
      MethodChannel('com.ultrix.facturador_offline/ios_config');

  /// Canal de método para comunicación con código nativo Android
  static const MethodChannel _androidChannel =
      MethodChannel('com.ultrix.facturador_offline/android_config');

  /// Determina si se está ejecutando en una plataforma móvil (Android o iOS)
  bool get isMobile => isAndroid || isIOS;

  /// Determina si se está ejecutando en un dispositivo Android
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Determina si se está ejecutando en un dispositivo iOS
  bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Determina si se está ejecutando en una plataforma de escritorio
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Determina si se está ejecutando en Windows
  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Determina si se está ejecutando en macOS
  bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Determina si se está ejecutando en Linux
  bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Determina si se está ejecutando en la Web
  bool get isWeb => kIsWeb;

  /// Obtiene la versión del sistema operativo para iOS
  Future<String> getIOSVersion() async {
    try {
      if (!isIOS) return '';
      final version = await _iosChannel.invokeMethod<String>('getIOSVersion');
      return version ?? '';
    } catch (e) {
      debugPrint('Error al obtener la versión iOS: $e');
      return '';
    }
  }

  /// Habilita el acceso a la base de datos en iOS
  Future<bool> enableIOSDatabaseAccess() async {
    try {
      if (!isIOS) return true;
      final result =
          await _iosChannel.invokeMethod<bool>('enableDatabaseAccess');
      return result ?? false;
    } catch (e) {
      debugPrint('Error al habilitar acceso a base de datos iOS: $e');
      return false;
    }
  }

  /// Obtiene la ruta del directorio de documentos en iOS
  Future<String> getIOSDocumentsPath() async {
    try {
      if (!isIOS) return '';
      final path = await _iosChannel.invokeMethod<String>('getDocumentsPath');
      return path ?? '';
    } catch (e) {
      debugPrint('Error al obtener la ruta de documentos iOS: $e');
      return '';
    }
  }

  /// Obtiene la versión de Android
  Future<String> getAndroidVersion() async {
    try {
      if (!isAndroid) return '';
      final version =
          await _androidChannel.invokeMethod<String>('getAndroidVersion');
      return version ?? '';
    } catch (e) {
      debugPrint('Error al obtener la versión Android: $e');
      return '';
    }
  }

  /// Verifica si el dispositivo tiene los permisos necesarios en Android
  Future<bool> checkAndroidPermissions() async {
    try {
      if (!isAndroid) return true;
      final result =
          await _androidChannel.invokeMethod<bool>('checkPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error al verificar permisos Android: $e');
      return false;
    }
  }

  /// Solicita permisos en Android
  Future<bool> requestAndroidPermissions() async {
    try {
      if (!isAndroid) return true;
      final result =
          await _androidChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error al solicitar permisos Android: $e');
      return false;
    }
  }

  /// Configura la orientación de la aplicación según la plataforma
  void configurePlatformOrientation() {
    if (isMobile) {
      // En móvil permitir ambas orientaciones
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else if (isDesktop) {
      // En escritorio no restringir orientación
      SystemChrome.setPreferredOrientations([]);
    }
  }

  /// Configura el estilo visual de la UI del sistema
  void configureSystemUI() {
    if (isMobile) {
      // Configurar la barra de estado en dispositivos móviles
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFD11C83), // Color primario
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    }
  }

  /// Inicializa la configuración específica de la plataforma
  Future<void> initPlatformSettings() async {
    configurePlatformOrientation();
    configureSystemUI();

    if (isIOS) {
      await enableIOSDatabaseAccess();
    }

    if (isAndroid) {
      final hasPermissions = await checkAndroidPermissions();
      if (!hasPermissions) {
        await requestAndroidPermissions();
      }
    }

  }

  /// Retorna un nombre descriptivo de la plataforma actual para diagnóstico
  String getPlatformName() {
    if (isAndroid) return "Android";
    if (isIOS) return "iOS";
    if (isWindows) return "Windows";
    if (isMacOS) return "macOS";
    if (isLinux) return "Linux";
    if (isWeb) return "Web";
    return "Plataforma desconocida";
  }

  /// Retorna la versión del sistema operativo actual
  Future<String> getPlatformVersion() async {
    if (isAndroid) return await getAndroidVersion();
    if (isIOS) return await getIOSVersion();
    if (isWindows || isMacOS || isLinux) {
      return Platform.operatingSystemVersion;
    }
    return "Versión desconocida";
  }
}