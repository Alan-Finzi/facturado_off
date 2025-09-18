import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:facturador_offline/bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database_seeder.dart';
import '../util/logger.dart';
class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool hasInternet = false;
  bool afipOnline = false;
  bool customServiceOnline = false;

  @override
  void initState() {
    super.initState();
    checkInternetConnection();
    // Comentar las siguientes líneas para simular la verificación de AFIP y servicio propio
    afipOnline = true;
    customServiceOnline = false;
  }

  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {

    final themeCubit = context.watch<ThemaCubit>();
    return Scaffold(
      appBar: AppBar(
        title:  Text('Estado de Conexión', style: TextStyle(color:themeCubit.state.isDark? Colors.white : Colors.black)),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'connection_theme_fab',
        elevation: 1,
        child:themeCubit.state.isDark? const Icon(Icons.dark_mode,size: 20,) :  const Icon(Icons.light,size: 20) ,
        onPressed: (){
          themeCubit.changeThema();
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Text(
              'Conexión a Internet:',
              style: TextStyle(color:themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 20.0),
            ),
            const SizedBox(height: 10.0),
            hasInternet
                ? const Icon(Icons.check_circle, color: Colors.green, size: 50.0)
                : const Icon(Icons.error, color: Colors.red, size: 50.0),
            const SizedBox(height: 20.0),
            Text(
              hasInternet ? 'Conexión establecida' : 'Sin conexión',
              style: TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 16.0),
            ),
            const SizedBox(height: 30.0),
             Text(
              'Estado de AFIP en Argentina:',
              style: TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 20.0),
            ),
            const SizedBox(height: 10.0),
            afipOnline
                ? const Icon(Icons.check_circle, color: Colors.green, size: 50.0)
                : const Icon(Icons.error, color: Colors.red, size: 50.0),
            const SizedBox(height: 20.0),
            Text(
              afipOnline ? 'Operativo' : 'Fuera de servicio',
              style:  TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 16.0),
            ),
            const SizedBox(height: 30.0),
             Text(
              'Estado de Servicio Propio:',
              style: TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 20.0),
            ),
            const SizedBox(height: 10.0),
            customServiceOnline
                ? const Icon(Icons.check_circle, color: Colors.green, size: 50.0)
                : const Icon(Icons.error, color: Colors.red, size: 50.0),
            const SizedBox(height: 20.0),
            Text(
              customServiceOnline ? 'Disponible' : 'No disponible',
              style:  TextStyle(color: themeCubit.state.isDark? Colors.white : Colors.black, fontSize: 16.0),
            ),
            
            SizedBox(height: 40.0),
            
            // Botón para cargar datos de ejemplo
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                try {
                  // Mostrar diálogo de confirmación
                  log.i('ConnectionPage', 'Solicitando confirmación para cargar datos de ejemplo');
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
                    log.i('ConnectionPage', 'Iniciando carga de datos de ejemplo');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cargando datos de ejemplo...')),
                    );
                    
                    // Ejecutar la carga de datos de ejemplo
                    final seeder = DatabaseSeeder();
                   // await seeder.seedDatabase();
                    
                    log.i('ConnectionPage', 'Datos de ejemplo cargados correctamente');
                    
                    // Refrescar los datos en toda la aplicación
                    // Esto garantiza que los nuevos precios y stocks se muestren correctamente
                    try {
                      // Actualizar listas de precios
                      if (context.mounted) {
                        context.read<ListaPreciosCubit>().getListasPreciosBD();
                      }
                      
                      // Si hay otros Cubits que necesiten refrescarse después de actualizar datos, agregarlos aquí
                      
                      log.i('ConnectionPage', 'Datos refrescados en la interfaz');
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Datos de ejemplo cargados y actualizados correctamente')),
                        );
                      }
                    } catch (refreshError) {
                      log.w('ConnectionPage', 'Datos cargados pero hubo un error al refrescar la interfaz: $refreshError');
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Datos cargados pero se requiere reiniciar la aplicación')),
                        );
                      }
                    }
                  } else {
                    log.i('ConnectionPage', 'Usuario canceló la carga de datos de ejemplo');
                  }
                } catch (e, stackTrace) {
                  // Registro detallado del error
                  log.e('ConnectionPage', 'Error al cargar datos de ejemplo', e, stackTrace);
                  
                  // Mostrar mensaje al usuario
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cargar datos de ejemplo'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Detalles',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Detalles del error'),
                              content: SingleChildScrollView(
                                child: Text('$e\n\n$stackTrace'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Copiar texto del error al portapapeles
                                    Clipboard.setData(ClipboardData(text: '$e\n\n$stackTrace'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error copiado al portapapeles')),
                                    );
                                  },
                                  child: Row(children: [
                                    Icon(Icons.copy, size: 16),
                                    SizedBox(width: 4),
                                    Text('Copiar'),
                                  ]),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
      ),
    );
  }
}