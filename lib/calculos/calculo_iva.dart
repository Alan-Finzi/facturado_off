class ResultadoIva {
    final double ivaCalculado;
    final double porcentajeIva;
    final String detalleCalculo;

    ResultadoIva({
        required this.ivaCalculado,
        required this.porcentajeIva,
        required this.detalleCalculo,
    });
}

ResultadoIva calcularIva({
    required double precioProducto,
    required double alicuotaIva,
    required String? condicionIva,
    required int relacionPrecioIva,
    required double ivaProducto, // Si el IVA es proporcionado explícitamente para el producto
}) {
    double ivaFinal = 0.0;
    // Usar el IVA por defecto (21%) si no está especificado o es 0
    double porcentajeIva = (ivaProducto <= 0.0) ? 0.21 : alicuotaIva;
    String detalleCalculo = "";

    // 1. Determinar el IVA según la condición
    if (condicionIva == null || condicionIva == "Monotributo") {
        ivaFinal = 0.0;  // Si es null o Monotributo, no hay IVA
        detalleCalculo = "Sin IVA aplicado (Monotributo o condición no definida)";
    } else if (condicionIva == "IVA Responsable Inscripto") {
        // Usar el porcentaje por defecto si no hay IVA específico para el producto
        ivaFinal = (ivaProducto <= 0.0) ? 0.21 : ivaProducto;
        detalleCalculo = "IVA Responsable Inscripto: \$${ivaFinal.toStringAsFixed(2)} (porcentaje: ${porcentajeIva * 100}%)";
    }

    // 2. Determinar el IVA según la relación del precio con IVA
    if (relacionPrecioIva == 0) {
        ivaFinal = 0.0;  // Sin relación, no se aplica IVA
        detalleCalculo = "Sin relación con IVA (relacion_precio_iva == 0)";
    } else if (relacionPrecioIva == 1) {
        // El precio incluye IVA, así que calculamos el IVA sobre el precio dado
        ivaFinal = precioProducto * alicuotaIva;  // Calculamos el IVA sobre el precio
        porcentajeIva = alicuotaIva; // El porcentaje de IVA aplicado
        detalleCalculo = "Precio + IVA: \$${precioProducto.toStringAsFixed(2)} * ${porcentajeIva}% = \$${ivaFinal.toStringAsFixed(2)}";
    } else if (relacionPrecioIva == 2) {
        // El precio ya incluye IVA, así que calculamos el precio sin IVA
        double precioSinIva = precioProducto / (1 + alicuotaIva);  // Extraemos el precio sin IVA
        ivaFinal = precioProducto - precioSinIva;  // El IVA es la diferencia
        porcentajeIva = alicuotaIva; // El porcentaje de IVA aplicado
        detalleCalculo = "Precio con IVA incluido: \$${precioProducto.toStringAsFixed(2)} - \$${precioSinIva.toStringAsFixed(2)} = \$${ivaFinal.toStringAsFixed(2)} (porcentaje: ${porcentajeIva}%)";
    }

    return ResultadoIva(
        ivaCalculado: ivaFinal,
        porcentajeIva: porcentajeIva,
        detalleCalculo: detalleCalculo,
    );
}
