import 'package:facturador_offline/pages/page_login.dart';
import 'package:facturador_offline/pages/root_navegator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_login/login_cubit.dart';
import '../bloc/cubit_synchronization/synchronization_cubit.dart';
import '../data/database_seeder.dart';

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
            if (state is SynchronizationCompleted) {
              // Navegamos a RootNavScreen cuando la sincronización está completada
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => RootNavScreen()),
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
                      SizedBox(height: 20),
                      LinearProgressIndicator(value: state.progress, minHeight: 8.0),
                      SizedBox(height: 20),
                      Text('${(state.progress * 100).toInt()}% completado', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      Text(state.currentTask, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          try {
                            // Mostrar diálogo de confirmación
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmar carga de datos de ejemplo'),
                                content: Text('Esta acción actualizará los precios y stocks de los productos con valores aleatorios. ¿Desea continuar?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Continuar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmar == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cargando datos de ejemplo...')),
                              );
                              
                              // Ejecutar la carga de datos de ejemplo
                              final seeder = DatabaseSeeder();
                              await seeder.seedDatabase();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Datos de ejemplo cargados correctamente')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cargar datos de ejemplo: $e')),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.dataset),
                            SizedBox(width: 8),
                            Text('Carga de datos ejemplo'),
                          ],
                        ),
                      ),
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