# Mejora del Campo de Contraseña - Funcionalidad de Visibilidad

Este documento explica las mejoras realizadas en el campo de contraseña de la página de login, incorporando un botón de ojito funcional para mostrar/ocultar la contraseña, así como la implementación del componente reutilizable `IconButtonWidget`.

## Cambios Implementados

### 1. Botón de Visibilidad de Contraseña
Se ha implementado un botón de ojito funcional en el campo de contraseña que:
- Alterna entre mostrar y ocultar la contraseña al hacer clic
- Cambia el color del icono dependiendo del estado:
  - **Rojo puro** (#FF0000) cuando la contraseña está oculta
  - **Naranja** cuando la contraseña está visible

### 2. Componente Reutilizable `IconButtonWidget`
Se ha creado un componente personalizado y reutilizable para botones de icono con múltiples variantes y opciones:

- **Tamaños**: small, medium, large, custom
- **Variantes**: filled, outlined, ghost, light
- **Estado**: normal, disabled, loading
- **Colores**: Implementa los colores de la aplicación (rojo puro y naranja)

### 3. Constructor de Fábrica para Visibilidad de Contraseña
Se ha agregado un constructor de fábrica especializado para crear botones de visibilidad de contraseña:

```dart
IconButtonWidget.passwordVisibility({
  required bool isVisible,
  required VoidCallback onPressed,
})
```

## Cambios en Archivos

1. **page_login.dart**
   - Agregada variable de estado `_obscurePassword`
   - Modificada la propiedad `obscureText` del campo de contraseña para usar esta variable
   - Implementado `IconButtonWidget.passwordVisibility` como suffixIcon
   - Implementada la lógica de cambio de estado al presionar el botón

2. **icon_button_widget.dart (NUEVO)**
   - Implementación completa del widget personalizable para botones de icono
   - Incluye enums para tamaños y variantes
   - Constructor de fábrica para crear botones de visibilidad de contraseña
   - Configuraciones de colores basadas en los colores de la aplicación

3. **constants.dart**
   - Se cambió el color de `miColor` de magenta (#FFD11C83) a rojo puro (#FF0000)

4. **Tests Unitarios**
   - Añadidos tests para verificar el comportamiento del `IconButtonWidget`
   - Tests específicos para la funcionalidad de visibilidad de contraseña
   - Verificación de cambios de color según el estado

## Cómo Ejecutar los Tests

Para ejecutar los tests unitarios:

```bash
cd /home/alanfinzi/Documents/GitHub/facturado_off
flutter test test/widget/icon_button_widget_test.dart
```

Para ejecutar todos los tests:

```bash
cd /home/alanfinzi/Documents/GitHub/facturado_off
flutter test
```

## Uso del Componente en Otros Lugares

El componente `IconButtonWidget` puede ser utilizado en cualquier parte de la aplicación donde se necesite un botón de icono:

```dart
// Ejemplo básico
IconButtonWidget(
  icon: Icons.search,
  onPressed: () {
    // Acción al presionar
  },
)

// Con estilo personalizado
IconButtonWidget(
  icon: Icons.delete,
  onPressed: () {
    // Acción al presionar
  },
  variant: IconButtonVariant.outlined,
  size: IconButtonSize.large,
  useOrangeColor: true, // Usar color naranja
)

// Para botón de visibilidad de contraseña
IconButtonWidget.passwordVisibility(
  isVisible: _passwordVisible,
  onPressed: () {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  },
)
```

## Consistencia de Diseño

La implementación mantiene consistencia con el diseño de la aplicación utilizando:
- Color primario (Rojo puro #FF0000) para los iconos principales
- Color naranja para botones de acción y el icono de visibilidad activa
- Mismos tamaños, bordes y estilos que el resto de la aplicación