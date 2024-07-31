import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          ],
        ),
      ),
    );
  }
}