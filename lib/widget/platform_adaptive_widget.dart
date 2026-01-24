import 'package:flutter/material.dart';
import '../util/platform_service.dart';

/// Widget que adapta su contenido según la plataforma
class PlatformAdaptiveWidget extends StatelessWidget {
  /// Widget a mostrar en plataforma móvil (Android/iOS)
  final Widget mobileWidget;

  /// Widget a mostrar en plataforma de escritorio (Windows/macOS/Linux)
  final Widget desktopWidget;

  /// Widget específico para Android (opcional)
  final Widget? androidWidget;

  /// Widget específico para iOS (opcional)
  final Widget? iosWidget;

  /// Widget específico para web (opcional)
  final Widget? webWidget;

  /// Constructor del widget adaptativo
  const PlatformAdaptiveWidget({
    Key? key,
    required this.mobileWidget,
    required this.desktopWidget,
    this.androidWidget,
    this.iosWidget,
    this.webWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService();

    // Comprobar si existe un widget específico para la plataforma
    if (platformService.isWeb && webWidget != null) {
      return webWidget!;
    } else if (platformService.isAndroid && androidWidget != null) {
      return androidWidget!;
    } else if (platformService.isIOS && iosWidget != null) {
      return iosWidget!;
    } else if (platformService.isMobile) {
      return mobileWidget;
    } else {
      return desktopWidget;
    }
  }
}

/// Widget para adaptar el layout basado en el tamaño de pantalla
class ResponsiveLayoutWidget extends StatelessWidget {
  /// Widget a mostrar en pantallas pequeñas (típicamente móviles en vertical)
  final Widget smallScreenWidget;

  /// Widget a mostrar en pantallas medianas (tablets o móviles en horizontal)
  final Widget mediumScreenWidget;

  /// Widget a mostrar en pantallas grandes (típicamente escritorio)
  final Widget largeScreenWidget;

  /// Umbral para pantallas pequeñas (menor que este ancho)
  final double smallScreenThreshold;

  /// Umbral para pantallas medianas (entre small y large)
  final double mediumScreenThreshold;

  /// Constructor del widget de layout responsive
  const ResponsiveLayoutWidget({
    Key? key,
    required this.smallScreenWidget,
    required this.mediumScreenWidget,
    required this.largeScreenWidget,
    this.smallScreenThreshold = 600.0,
    this.mediumScreenThreshold = 1200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < smallScreenThreshold) {
      return smallScreenWidget;
    } else if (screenWidth < mediumScreenThreshold) {
      return mediumScreenWidget;
    } else {
      return largeScreenWidget;
    }
  }
}

/// Extensión para MediaQuery para determinar el tipo de dispositivo
extension DeviceTypeExtension on MediaQueryData {
  /// Devuelve true si el dispositivo es un teléfono
  bool get isPhone => size.width < 600;

  /// Devuelve true si el dispositivo es una tablet
  bool get isTablet => size.width >= 600 && size.width < 1200;

  /// Devuelve true si el dispositivo es una desktop
  bool get isDesktop => size.width >= 1200;
}

/// Extensión para BuildContext que proporciona métodos para adaptarse a diferentes tamaños de pantalla
extension ResponsiveExtension on BuildContext {
  /// Devuelve el tamaño de la pantalla
  Size get screenSize => MediaQuery.of(this).size;

  /// Devuelve el ancho de la pantalla
  double get screenWidth => screenSize.width;

  /// Devuelve el alto de la pantalla
  double get screenHeight => screenSize.height;

  /// Devuelve true si el dispositivo está en modo horizontal
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  /// Devuelve true si el dispositivo está en modo vertical
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;

  /// Devuelve true si el dispositivo es un teléfono
  bool get isPhone => MediaQuery.of(this).isPhone;

  /// Devuelve true si el dispositivo es una tablet
  bool get isTablet => MediaQuery.of(this).isTablet;

  /// Devuelve true si el dispositivo es una desktop
  bool get isDesktop => MediaQuery.of(this).isDesktop;

  /// Devuelve un valor según el tamaño de la pantalla
  T adaptiveValue<T>({
    required T mobile,
    required T desktop,
    T? tablet,
  }) {
    if (isDesktop) {
      return desktop;
    } else if (isTablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}