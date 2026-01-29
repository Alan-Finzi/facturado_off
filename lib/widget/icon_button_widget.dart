import 'package:flutter/material.dart';
import '../util/constants.dart';

/// Tamaños predefinidos para el IconButtonWidget
enum IconButtonSize {
  /// Botón pequeño (32x32)
  small,

  /// Botón mediano (40x40)
  medium,

  /// Botón grande (48x48)
  large,

  /// Botón de tamaño personalizado
  custom
}

/// Tipo de botón para diferentes estilos visuales
enum IconButtonVariant {
  /// Estilo con fondo sólido
  filled,

  /// Estilo con sólo borde
  outlined,

  /// Estilo plano sin borde ni fondo
  ghost,

  /// Estilo con fondo semitransparente
  light
}

/// Botón de icono personalizable con múltiples variantes
/// Implementa los colores de la aplicación (rojo/magenta y naranja)
class IconButtonWidget extends StatelessWidget {
  /// El icono a mostrar dentro del botón
  final IconData icon;

  /// Función que se ejecuta al presionar el botón
  final VoidCallback? onPressed;

  /// Tamaño del botón
  final IconButtonSize size;

  /// Variante visual del botón
  final IconButtonVariant variant;

  /// Color del icono
  final Color? iconColor;

  /// Color de fondo del botón
  final Color? backgroundColor;

  /// Color del borde para la variante outlined
  final Color? borderColor;

  /// Radio del borde del botón
  final double borderRadius;

  /// Grosor del borde para la variante outlined
  final double borderWidth;

  /// Ancho personalizado (solo para size = custom)
  final double? width;

  /// Alto personalizado (solo para size = custom)
  final double? height;

  /// Tamaño personalizado del icono
  final double? iconSize;

  /// Si es verdadero, muestra un indicador de carga en lugar del icono
  final bool isLoading;

  /// Color del indicador de carga
  final Color? loadingColor;

  /// Si es verdadero, el botón está deshabilitado
  final bool disabled;

  /// Tooltip que se muestra al mantener presionado
  final String? tooltip;

  /// Si es verdadero, usa el color naranja como color principal, de lo contrario usa el color primario (rojo/magenta)
  final bool useOrangeColor;

  /// Constructor para IconButtonWidget
  const IconButtonWidget({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.size = IconButtonSize.medium,
    this.variant = IconButtonVariant.filled,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.borderWidth = 1.5,
    this.width,
    this.height,
    this.iconSize,
    this.isLoading = false,
    this.loadingColor,
    this.disabled = false,
    this.tooltip,
    this.useOrangeColor = false,
  })  : assert(
          (size == IconButtonSize.custom) ? (width != null && height != null) : true,
          'width and height must be provided when size is custom',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Colores personalizados de la aplicación
    final Color primaryColor = Constants.miColor; // Rojo/magenta
    final Color orangeColor = Colors.orange;

    // Determinar color principal según la configuración
    final Color mainColor = useOrangeColor ? orangeColor : primaryColor;

    // Calcular dimensiones según el tamaño
    double buttonSize;
    double defaultIconSize;

    switch (size) {
      case IconButtonSize.small:
        buttonSize = 32.0;
        defaultIconSize = 16.0;
        break;
      case IconButtonSize.medium:
        buttonSize = 40.0;
        defaultIconSize = 20.0;
        break;
      case IconButtonSize.large:
        buttonSize = 48.0;
        defaultIconSize = 24.0;
        break;
      case IconButtonSize.custom:
        buttonSize = width ?? 40.0;
        defaultIconSize = 20.0;
        break;
    }

    final double actualIconSize = iconSize ?? defaultIconSize;

    // Determinar colores basados en la variante y el tema
    final Color effectiveIconColor = iconColor ??
        (variant == IconButtonVariant.filled ? Colors.white : mainColor);

    Color effectiveBackgroundColor;
    Color effectiveBorderColor;

    switch (variant) {
      case IconButtonVariant.filled:
        effectiveBackgroundColor = backgroundColor ?? mainColor;
        effectiveBorderColor = Colors.transparent;
        break;
      case IconButtonVariant.outlined:
        effectiveBackgroundColor = Colors.transparent;
        effectiveBorderColor = borderColor ?? mainColor;
        break;
      case IconButtonVariant.ghost:
        effectiveBackgroundColor = Colors.transparent;
        effectiveBorderColor = Colors.transparent;
        break;
      case IconButtonVariant.light:
        effectiveBackgroundColor =
            backgroundColor?.withOpacity(0.15) ?? mainColor.withOpacity(0.15);
        effectiveBorderColor = Colors.transparent;
        break;
    }

    // Contenido del botón (icono o indicador de carga)
    Widget buttonContent = isLoading
        ? SizedBox(
            width: actualIconSize,
            height: actualIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                loadingColor ?? effectiveIconColor,
              ),
            ),
          )
        : Icon(
            icon,
            size: actualIconSize,
            color: disabled ? effectiveIconColor.withOpacity(0.5) : effectiveIconColor,
          );

    // Construir el botón con el tamaño, forma y colores adecuados
    Widget button = Container(
      width: size == IconButtonSize.custom ? width : buttonSize,
      height: size == IconButtonSize.custom ? height : buttonSize,
      decoration: BoxDecoration(
        color: disabled ? effectiveBackgroundColor.withOpacity(0.5) : effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: disabled ? effectiveBorderColor.withOpacity(0.5) : effectiveBorderColor,
          width: variant == IconButtonVariant.outlined ? borderWidth : 0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(child: buttonContent),
        ),
      ),
    );

    // Agregar tooltip si se proporciona
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }

  /// Fábrica para crear un botón de visibilidad para mostrar/ocultar contraseña
  /// [isVisible] determina si la contraseña está visible o no
  factory IconButtonWidget.passwordVisibility({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButtonWidget(
      icon: isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      onPressed: onPressed,
      variant: IconButtonVariant.ghost,
      useOrangeColor: isVisible, // Si es visible, usa naranja; si no, usa rojo/magenta
      tooltip: isVisible ? 'Ocultar contraseña' : 'Mostrar contraseña',
    );
  }
}