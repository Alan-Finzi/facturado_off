import 'package:facturador_offline/pages/page_synchronization.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../util/platform_service.dart';
import '../widget/platform_adaptive_widget.dart';


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
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: rememberUser,
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

    // Usar SingleChildScrollView para evitar errores de RenderFlex overflow
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // No usamos appBar para seguir el diseño de la imagen de referencia
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding reducido para hacer la pantalla más compacta
          padding: EdgeInsets.only(
            left: 24.0,
            top: 12.0,
            right: 24.0,
            bottom: 24.0 + (isKeyboardOpen ? 200 : 0), // Padding adicional para evitar el error de overflow
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo centrado (con padding reducido)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Container(
                    width: 150,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      "flaminco",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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

              const SizedBox(height: 16),

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
                  suffixIcon: const Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 12),

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
                obscureText: true,
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
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
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
                    foregroundColor: Colors.orange,
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
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      setState(() {
                        rememberUser = value ?? false;
                      });
                    },
                  ),
                  const Text('Recordar usuario'),
                ],
              ),

              const SizedBox(height: 16),

              // Botón de inicio de sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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

              const SizedBox(height: 12),

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
    final username = emailController.text.isNotEmpty ? emailController.text : null;
    final password = passwordController.text.isNotEmpty ? passwordController.text : null;

    if (username == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese email y contraseña')),
      );
      return;
    }

    await loginCubit.login(username, password);

    if (loginCubit.state.isLogin) {
      await _saveOrRemoveCredentials(username, password);

      if (loginCubit.state.isPreference) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RootNavScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SynchronizationPage(
              token: loginCubit.state.userToken!,
              email: username,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceso denegado')),
      );
    }
  }
}
