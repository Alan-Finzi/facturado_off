import 'package:facturador_offline/pages/page_synchronization.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:facturador_offline/bloc/cubit_login/login_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late LoginCubit loginCubit;
  @override
  void initState() {
    super.initState();
    loginCubit = BlocProvider.of<LoginCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Si el usuario ha ingresado credenciales
                final username = emailController.text.isNotEmpty ? emailController.text : null;
                final password = passwordController.text.isNotEmpty ? passwordController.text : null;

                // Intentamos hacer login con las credenciales proporcionadas o las guardadas en SharedPreferences
                await loginCubit.login(username, password);

                if (loginCubit.state.isLogin) {

                  if (loginCubit.state.isPreference) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RootNavScreen()),
                    );

                  }else{
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SynchronizationPage(token: loginCubit.state.userToken!,email: username!)),
                    );
                  }

                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acceso denegado')),
                  );
                }
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
