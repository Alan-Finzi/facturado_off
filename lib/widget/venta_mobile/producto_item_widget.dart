import 'package:flutter/material.dart';

/// Widget para mostrar un elemento de producto en la lista de carrito
class ProductoItemWidget extends StatelessWidget {
  /// Nombre del producto
  final String nombreProducto;

  /// Cantidad del producto
  final int cantidad;

  /// Precio final del producto
  final double precioFinal;

  /// Callback para eliminar el producto
  final VoidCallback onDelete;

  /// Widget opcional para la imagen del producto
  final Widget? imagenProducto;

  /// Formateador para el precio (opcional)
  final String Function(double) formatearPrecio;

  const ProductoItemWidget({
    super.key,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioFinal,
    required this.onDelete,
    this.imagenProducto,
    this.formatearPrecio = _defaultFormatPrecio,
  });

  static String _defaultFormatPrecio(double precio) {
    return '\$ ${precio.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen del producto (placeholder o imagen proporcionada)
          imagenProducto ?? Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Detalles del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreProducto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Control de cantidad
                Row(
                  children: [
                    // Entrada numérica de cantidad
                    Container(
                      width: 35,
                      height: 35,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatearPrecio(precioFinal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Botón para eliminar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}