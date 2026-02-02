import 'package:facturador_offline/pages/inicializacion_datos_page.dart';
import 'package:facturador_offline/pages/page_login.dart';
import 'package:facturador_offline/pages/page_synchronization.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../helper/database_helper.dart';
import '../models/user.dart';
import '../util/constants.dart';

class SplashScreenAuth extends StatefulWidget {
  const SplashScreenAuth({Key? key}) : super(key: key);

  @override
  _SplashScreenAuthState createState() => _SplashScreenAuthState();
}

class _SplashScreenAuthState extends State<SplashScreenAuth> {
  bool _isChecking = true;
  String _statusMessage = 'Verificando credenciales...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      setState(() {
        _statusMessage = 'Verificando credenciales...';
      });

      // Obtenemos instancia de LoginCubit
      final loginCubit = BlocProvider.of<LoginCubit>(context);

      // Verificar si hay credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remembered_email');
      final savedPassword = prefs.getString('remembered_password');

      // Si no hay credenciales guardadas, vamos a la pantalla de login
      if (savedEmail == null || savedPassword == null) {
        _navigateToLogin();
        return;
      }

      // Intentar login automático
      setState(() {
        _statusMessage = 'Iniciando sesión automáticamente...';
      });

      // Intentamos iniciar sesión sin necesidad de proporcionar contraseña
      // (el flujo interno de login usará la credencial almacenada)
      await loginCubit.login(savedEmail, null);

      if (loginCubit.state.isLogin) {
        setState(() {
          _statusMessage = 'Verificando estado de sincronización...';
        });

        // Verificar el estado de sincronización y decidir a dónde navegar
        if (!loginCubit.state.isPreference) {
          // Si isPreference es false, se requiere sincronización
          _navigateToSynchronization(savedEmail, loginCubit.state.userToken!);
        } else if (loginCubit.state.needsDataInitialization) {
          // Si se necesita inicializar datos en memoria
          _navigateToInitData(loginCubit.state.user!, loginCubit.state.userToken!);
        } else {
          // Todo está listo, ir a la pantalla principal
          _navigateToMain();
        }
      } else {
        // Si el login falló, ir a la pantalla de login
        _navigateToLogin();
      }
    } catch (e) {
      print('Error en verificación de autenticación: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    setState(() {
      _isChecking = false;
    });

    // Añadimos un pequeño delay para mostrar el splash
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    });
  }

  void _navigateToSynchronization(String email, String token) {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Preparando sincronización...';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SynchronizationPage(
            token: token,
            email: email,
          ),
        ),
      );
    });
  }

  void _navigateToInitData(User user, String token) {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Preparando inicialización de datos...';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InicializacionDatosPage(
            user: user,
            token: token,
          ),
        ),
      );
    });
  }

  void _navigateToMain() {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Iniciando aplicación...';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RootNavScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Text(
                "flaminco",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Constants.miColor,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 50),

              // Indicador de progreso
              if (_isChecking)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.miColor),
                ),

              const SizedBox(height: 20),

              // Mensaje de estado
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}