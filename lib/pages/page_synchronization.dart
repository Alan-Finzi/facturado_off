import 'package:facturador_offline/pages/page_login.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_synchronization/synchronization_cubit.dart';
import 'inicializacion_datos_page.dart';

class SynchronizationPage extends StatelessWidget {
  final String token;
  final String email;

  SynchronizationPage({required this.token, required this.email});

  @override
  Widget build(BuildContext context) {
    final loginCubit = BlocProvider.of<LoginCubit>(context);

    print("Construyendo SynchronizationPage");
    return Scaffold(
      appBar: AppBar(
        title: Text('Sincronización'),
      ),
      body: BlocProvider(
        create: (context) {
          print("Iniciando SynchronizationCubit");
          return SynchronizationCubit()..startSynchronization(token, email, loginCubit);
        },
        child: BlocListener<SynchronizationCubit, SynchronizationState>(
          listener: (context, state) {
            if (state is SynchronizationInitial) {
              // Mostrar un mensaje cuando inicia la sincronización
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mantenga la pantalla encendida durante la sincronización para evitar interrupciones'),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.blue,
                ),
              );
            } else if (state is SynchronizationCompleted) {
              // CORREGIDO: Navegamos a InicializacionDatosPage en lugar de RootNavScreen
              // para cargar los datos desde la BD a memoria antes de mostrar la pantalla principal
              print("✅ Sincronización completada. Ahora cargando datos en memoria...");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => InicializacionDatosPage(
                    user: loginCubit.state.user!,
                    token: loginCubit.state.userToken!,
                  ),
                ),
              );
            } else if (state is SynchronizationFailed) {
              // Mostramos un mensaje de error y volvemos a la pantalla anterior
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage)),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );// Navegación hacia atrás
            }
          },
          child: BlocBuilder<SynchronizationCubit, SynchronizationState>(
            builder: (context, state) {
              if (state is SynchronizationInProgress) {
                // Mostrar la barra de progreso mientras la sincronización está en progreso
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Sincronización en progreso...', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber.shade800),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mantenga la pantalla encendida para evitar interrupciones en la sincronización',
                                style: TextStyle(color: Colors.amber.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      LinearProgressIndicator(value: state.progress, minHeight: 8.0),
                      SizedBox(height: 20),
                      Text('${(state.progress * 100).toInt()}% completado', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      Text(state.currentTask, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              } else if (state is SynchronizationInitial) {
                // Mostrar mensaje mientras se prepara la sincronización
                return Center(child: Text("Preparando la sincronización..."));
              } else if (state is SynchronizationFailed) {
                // Mostrar un mensaje cuando haya un error en la sincronización
                return Center(child: Text("Ocurrió un error en la sincronización."));
              } else {
                // Mostrar algo cuando la sincronización haya finalizado
                return Center(child: Text("Sincronización completada."));
              }
            },
          ),
        ),
      ),
    );
  }
}