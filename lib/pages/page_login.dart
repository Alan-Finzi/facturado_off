import 'package:facturador_offline/pages/page_synchronization.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Para TimeoutException

import '../bloc/cubit_login/login_cubit.dart';
import '../util/platform_service.dart';
import '../widget/platform_adaptive_widget.dart';
import '../util/constants.dart';
import '../widget/icon_button_widget.dart';
import 'inicializacion_datos_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late LoginCubit loginCubit;
  bool rememberUser = false;
  // Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    loginCubit = BlocProvider.of<LoginCubit>(context);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final savedPassword = prefs.getString('remembered_password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberUser = true;
      });
    }
  }

  Future<void> _saveOrRemoveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberUser) {
      await prefs.setString('remembered_email', email);
      await prefs.setString('remembered_password', password);
    } else {
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService();

    // Usar diseño responsive basado en la plataforma
    return PlatformAdaptiveWidget(
      // Versión móvil (Android/iOS)
      mobileWidget: _buildMobileLogin(context),

      // Versión escritorio (Windows/macOS/Linux)
      desktopWidget: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  // Usar IconButtonWidget personalizado para el botón de visibilidad
                  suffixIcon: IconButtonWidget.passwordVisibility(
                    isVisible: !_obscurePassword,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: rememberUser,
                    activeColor: Constants.miColor,
                    onChanged: (value) {
                      setState(() {
                        rememberUser = value ?? false;
                      });
                    },
                  ),
                  const Text('Recordar usuario'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Diseño para móviles basado en la imagen de referencia
  Widget _buildMobileLogin(BuildContext context) {
    // Obtener tamaño de pantalla para diseño responsive
    final screenSize = MediaQuery.of(context).size;
    final screenPadding = MediaQuery.of(context).padding;

    // Determinar si el teclado está abierto
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardSpace > 0;

    // Definir colores personalizados
    final Color primaryColor = Constants.miColor;
    final Color orangeColor = Colors.orange;

    // Usar SingleChildScrollView para evitar errores de RenderFlex overflow
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // No usamos appBar para seguir el diseño de la imagen de referencia
      body: SafeArea(
        child: SingleChildScrollView(
          // Añadir padding adicional cuando el teclado está abierto
          padding: EdgeInsets.only(
            left: 24.0,
            top: 24.0,
            right: 24.0,
            bottom: 24.0 + (isKeyboardOpen ? 200 : 0), // Padding adicional para evitar el error de overflow
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo centrado
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                  child: Container(
                    width: 150,
                    height: 80,
                    alignment: Alignment.center,
                    child: Text(
                      "flaminco",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor, // Usar color primario (rojo/magenta)
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),

              // Título "Inicio de sesión"
              const Text(
                'Inicio de sesion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                'Por favor inicia sesion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              // Campo de email
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'nombre@email.com',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  // Usar IconButtonWidget para el icono de email
                  suffixIcon: IconButtonWidget(
                    icon: Icons.email_outlined,
                    onPressed: null, // Sin acción
                    variant: IconButtonVariant.ghost,
                    useOrangeColor: false, // Usar color primario (rojo/magenta)
                    disabled: true,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Campo de contraseña
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu password',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  // Usar IconButtonWidget.passwordVisibility personalizado
                  suffixIcon: IconButtonWidget.passwordVisibility(
                    isVisible: !_obscurePassword,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              // Olvidaste tu contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Acción para recuperar contraseña
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: orangeColor, // Usar color naranja
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    '¿Olvidaste la contraseña?',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),

              // Checkbox "Recordar usuario"
              Row(
                children: [
                  Checkbox(
                    value: rememberUser,
                    activeColor: primaryColor, // Usar color primario para el checkbox
                    onChanged: (value) {
                      setState(() {
                        rememberUser = value ?? false;
                      });
                    },
                  ),
                  const Text('Recordar usuario'),
                ],
              ),

              const SizedBox(height: 24),

              // Botón de inicio de sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor, // Usar color naranja para el botón
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Link para registrarse
              Center(
                child: TextButton(
                  onPressed: () {
                    // Acción para registrarse
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'No tenes una cuenta? Registrate',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método compartido para manejar el proceso de login
  void _handleLogin(BuildContext context) async {
    // Mostrar indicador de carga mientras se procesa el login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando sesión...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Obtener información de plataforma para diagnóstico
    final platformService = PlatformService();
    print('Intento de login en plataforma: ${platformService.getPlatformName()}');

    final username = emailController.text.isNotEmpty ? emailController.text : null;
    final password = passwordController.text.isNotEmpty ? passwordController.text : null;

    print('Iniciando login con email: ${username ?? "vacío"}');

    if (username == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese email y contraseña')),
      );
      return;
    }

    try {
      // Mostrar un indicador de progreso durante el login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Iniciando sesión'),
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.miColor),
                ),
                SizedBox(width: 20),
                Text('Conectando con el servidor...'),
              ],
            ),
          );
        },
      );

      await loginCubit.login(username, password);

      // Cerrar el diálogo de progreso
      Navigator.pop(context);

      if (loginCubit.state.isLogin) {
        await _saveOrRemoveCredentials(username, password);

        // Mostrar un mensaje para depuración (solo visible en la consola)
        print("⚠️ ESTADO DEL LOGIN: " +
            "isLogin=${loginCubit.state.isLogin}, " +
            "isPreference=${loginCubit.state.isPreference}, " +
            "needsOnlineAuth=${loginCubit.state.needsOnlineAuth}, " +
            "needsDataInitialization=${loginCubit.state.needsDataInitialization}, " +
            "hasUser=${loginCubit.state.user != null}, " +
            "hasToken=${loginCubit.state.userToken != null}");

        // Verificar la plataforma actual
        final platformService = PlatformService();
        final isMobile = platformService.isAndroid || platformService.isIOS;

        // Log para diagnóstico
        print("📱 Plataforma: ${platformService.getPlatformName()}, Es móvil: $isMobile");
        print("🔄 Estado actual: isPreference=${loginCubit.state.isPreference}, needsDataInitialization=${loginCubit.state.needsDataInitialization}");

        // LÓGICA SIMPLIFICADA:
        // 1. Para sincronización, siempre ir a SynchronizationPage
        // 2. Para móviles sin sincronización, SIEMPRE ir a InicializacionDatosPage
        // 3. Para escritorio sin sincronización, ir directamente a RootNavScreen

        if (!loginCubit.state.isPreference) {
          // Si necesita sincronización, siempre ir a la página de sincronización
          print("➡️ Redirigiendo a la página de sincronización (sincronización requerida)");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SynchronizationPage(
                token: loginCubit.state.userToken!,
                email: username,
              ),
            ),
          );
        } else if (isMobile) {
          // MÓVIL: Siempre forzar inicialización de datos cuando no requiere sincronización
          print("➡️ Dispositivo móvil: forzando inicialización de datos antes de ir a la pantalla principal");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InicializacionDatosPage(
                user: loginCubit.state.user!,
                token: loginCubit.state.userToken!,
              ),
            ),
          );
        } else {
          // ESCRITORIO: Ir directamente a la pantalla principal cuando no requiere sincronización
          print("➡️ Dispositivo de escritorio: yendo directamente a la pantalla principal");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RootNavScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso denegado. Compruebe sus credenciales.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de progreso si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Determinar el tipo de error para mensaje más específico
      String errorMessage;
      if (e is TimeoutException) {
        errorMessage = 'Tiempo de espera agotado. Verifique su conexión a internet.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMessage = 'No se puede conectar al servidor. Verifique su conexión a internet.';
      } else if (e.toString().contains('certificate')) {
        errorMessage = 'Error de seguridad en la conexión. Problema con certificados SSL.';
      } else {
        errorMessage = 'Error de conexión: ${e.toString()}';
      }

      // Mostrar mensaje de error más específico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 5),
          backgroundColor: Constants.miColor,
        ),
      );

      print('Error en login: $e');

      // Intentar conectar offline si hay credenciales guardadas previamente
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('remembered_email');
        final savedPassword = prefs.getString('remembered_password');

        if (savedEmail != null && savedEmail == username && savedPassword != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Intentando acceder con credenciales guardadas...'),
              duration: Duration(seconds: 2),
            ),
          );

          // Intentar iniciar sesión de forma offline
          await loginCubit.login(username, null);

          if (loginCubit.state.isLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RootNavScreen()),
            );
          }
        }
      } catch (fallbackError) {
        print('Error en intento de login offline: $fallbackError');
      }
    }
  }
}