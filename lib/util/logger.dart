import 'dart:developer' as developer;

/// Clase para manejar logs de forma centralizada
/// Reemplaza el uso de print con un sistema que puede configurarse
/// según el entorno (desarrollo, producción, etc.)
class Logger {
  // Singleton
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  // Niveles de log
  static const int DEBUG = 0;
  static const int INFO = 1;
  static const int WARNING = 2;
  static const int ERROR = 3;
  
  // Nivel actual (configurable)
  int _currentLevel = DEBUG;
  
  // Si está habilitado o no el log
  bool _enabled = true;

  /// Configura el nivel de log
  void setLevel(int level) {
    _currentLevel = level;
  }
  
  /// Habilita o deshabilita el log
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Log de nivel debug
  void d(String tag, String message) {
    if (!_enabled || _currentLevel > DEBUG) return;
    developer.log('🔍 DEBUG [$tag] $message');
  }
  
  /// Log de nivel info
  void i(String tag, String message) {
    if (!_enabled || _currentLevel > INFO) return;
    developer.log('ℹ️ INFO [$tag] $message');
  }
  
  /// Log de nivel warning
  void w(String tag, String message) {
    if (!_enabled || _currentLevel > WARNING) return;
    developer.log('⚠️ WARNING [$tag] $message');
  }
  
  /// Log de nivel error
  void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_enabled || _currentLevel > ERROR) return;
    developer.log('❌ ERROR [$tag] $message', error: error, stackTrace: stackTrace);
  }
}

// Instancia global para acceso fácil desde cualquier parte de la app
final log = Logger();