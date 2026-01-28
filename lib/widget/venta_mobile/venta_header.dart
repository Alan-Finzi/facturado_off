import 'package:flutter/material.dart';

/// Encabezado para la página de venta mobile
class VentaHeader extends StatelessWidget {
  /// Callback para el botón de menú
  final VoidCallback? onMenu;

  /// Callback para el botón de opciones
  final VoidCallback? onOptions;

  /// Widget del logo a mostrar en el centro
  final Widget? logo;

  const VentaHeader({
    super.key,
    this.onMenu,
    this.onOptions,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: logo ?? const SizedBox(width: 120),
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.orange),
        onPressed: onMenu ?? () {},
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.orange),
          onPressed: onOptions ?? () {},
        ),
      ],
    );
  }
}