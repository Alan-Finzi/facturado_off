import 'package:facturador_offline/pages/page_synchronization.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/cubit_login/login_cubit.dart';



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
              onPressed: () async {
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
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
