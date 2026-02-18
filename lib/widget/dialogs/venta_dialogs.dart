import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Clase con métodos para mostrar diálogos relacionados con ventas
/// de manera consistente en todas las plataformas (Android, iOS, Web, Desktop)
class VentaDialogs {
  /// Muestra un diálogo de confirmación para guardar una venta
  /// Adaptado para funcionar en todas las plataformas (Android/Web/Desktop y iOS)
  static Future<bool> mostrarConfirmacionVenta(
    BuildContext context, {
    required String nombreCliente,
    required List<Map<String, dynamic>> productos,
    required double subtotal,
    required double descuentoGeneral,
    required double montoDescuento,
    required double iva,
    required double total,
  }) async {
    // Contenido común para ambas plataformas
    Widget content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Por favor confirme los detalles de la venta:'),
          const SizedBox(height: 16),

          // Cliente
          const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(nombreCliente),
          const SizedBox(height: 8),

          // Productos
          const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...productos.map((producto) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(producto['nombre'] ?? 'Producto sin nombre'),
                ),
                Text('\\$${(producto['precio'] as num).toStringAsFixed(2)}'),
              ],
            ),
          )),
          const Divider(),

          // Mostrar totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 14)),
              Text('\\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          if (descuentoGeneral > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Descuento (${descuentoGeneral.round()}%):', style: const TextStyle(fontSize: 14)),
                Text('- \\$${montoDescuento.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA:', style: TextStyle(fontSize: 14)),
              Text('\\$${iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    // Determinar si estamos en iOS para mostrar el diálogo específico
    if (isIOS) {
      final resultado = await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.systemGreen),
              SizedBox(width: 8),
              Text('Confirmar venta'),
            ],
          ),
          content: content,
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      return resultado ?? false;
    } else {
      // Android/Web/Desktop
      final resultado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirmar venta'),
            ],
          ),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      return resultado ?? false;
    }
  }

  /// Muestra un indicador de carga mientras se procesa la venta
  /// Adaptado para funcionar en todas las plataformas
  static Future<void> mostrarCargando(BuildContext context, {String mensaje = 'Guardando venta...'}) async {
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 20),
              Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Cierra el diálogo de carga (común para todas las plataformas)
  static void cerrarCargando(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Muestra un diálogo de éxito después de guardar una venta
  /// Adaptado para funcionar en todas las plataformas
  static Future<void> mostrarExito(
    BuildContext context, {
    required int ventaId,
    required double total,
    required String nombreCliente,
    Function? onAceptar,
  }) async {
    // Contenido común para ambas plataformas
    Widget contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('La venta ha sido guardada correctamente.'),
        const SizedBox(height: 10),
        Text('Número de venta: #$ventaId', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text('Total: \\$${total.toStringAsFixed(2)}'),
        const SizedBox(height: 5),
        Text('Cliente: $nombreCliente'),
      ],
    );

    if (isIOS) {
      await showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.systemGreen),
              SizedBox(width: 10),
              Text('¡Venta Guardada con Éxito!'),
            ],
          ),
          content: contentWidget,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                if (onAceptar != null) {
                  onAceptar();
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('¡Venta Guardada con Éxito!'),
            ],
          ),
          content: contentWidget,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onAceptar != null) {
                  onAceptar();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  /// Muestra un diálogo de error cuando falla el guardado de una venta
  /// Adaptado para funcionar en todas las plataformas
  static Future<bool> mostrarError(
    BuildContext context, {
    required String error,
    Function? onReintentar,
  }) async {
    // Contenido común para el diálogo de error
    Widget errorContent = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isIOS ? CupertinoColors.systemRed.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isIOS ? CupertinoColors.systemRed.withOpacity(0.3) : Colors.red.shade200,
        ),
      ),
      child: Text(
        error,
        style: TextStyle(
          color: isIOS ? CupertinoColors.systemRed : Colors.red.shade800,
          fontSize: 12,
        ),
      ),
    );

    Widget contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('No se pudo guardar la venta debido a un error:'),
        const SizedBox(height: 10),
        errorContent,
        const SizedBox(height: 10),
        const Text('Por favor, inténtelo nuevamente o contacte al soporte técnico.')
      ],
    );

    if (isIOS) {
      final resultado = await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed),
              SizedBox(width: 10),
              Text('Error al Guardar la Venta'),
            ],
          ),
          content: contentWidget,
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            if (onReintentar != null)
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onReintentar();
                },
                child: const Text('Reintentar'),
              ),
          ],
        ),
      );
      return resultado ?? false;
    } else {
      final resultado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Error al Guardar la Venta'),
            ],
          ),
          content: contentWidget,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            if (onReintentar != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onReintentar();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Reintentar'),
              ),
          ],
        ),
      );
      return resultado ?? false;
    }
  }

  /// Utilidad para determinar si estamos en iOS
  static bool get isIOS {
    try {
      return Platform.isIOS;
    } catch (e) {
      // Si estamos en web, no podemos detectar la plataforma directamente
      // En ese caso, usamos la implementación Material (no iOS)
      return false;
    }
  }
}