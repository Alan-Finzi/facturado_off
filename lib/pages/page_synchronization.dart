import 'package:facturador_offline/pages/page_login.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_settings/app_settings.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_synchronization/synchronization_cubit.dart';
import 'inicializacion_datos_page.dart';

class SynchronizationPage extends StatelessWidget {
  final String token;
  final String email;

  SynchronizationPage({required this.token, required this.email});

  // Método para mostrar el diálogo de configuración de pantalla
  void _mostrarDialogoConfiguracionPantalla(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('¡Importante! Mantenga la pantalla encendida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La sincronización puede tardar varios minutos. Si la pantalla se apaga durante el proceso, la sincronización podría interrumpirse.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Para evitar interrupciones:'),
            SizedBox(height: 8),
            Text('• Mantenga la aplicación abierta'),
            Text('• No bloquee su dispositivo'),
            Text('• Aumente el tiempo de espera de la pantalla'),
            SizedBox(height: 16),
            Text('Puede modificar el tiempo de espera en:'),
            Text('Configuración → Pantalla → Tiempo de espera', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Presione el botón "Ir a Configuración" para acceder rápidamente.',
              style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          // Botón para abrir configuración de pantalla
          ElevatedButton.icon(
            icon: Icon(Icons.settings),
            label: Text('Ir a Configuración'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              try {
                // Intentar abrir la configuración de pantalla
                AppSettings.openAppSettings ();
              } catch (e) {
                print('Error al abrir configuración: $e');
                // Si falla, mostrar un mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir la configuración. Por favor, hágalo manualmente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Continuar'),
          ),
        ],
      ),
    );
  }

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
              // Mostrar el diálogo de configuración
              _mostrarDialogoConfiguracionPantalla(context);
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
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'NO BLOQUEE SU DISPOSITIVO. La sincronización se interrumpirá si la pantalla se apaga.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          try {
                            AppSettings.openAppSettings();
                          } catch (e) {
                            print('Error al abrir configuración: $e');
                          }
                        },
                        icon: Icon(Icons.settings),
                        label: Text('Cambiar tiempo de espera de pantalla'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
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