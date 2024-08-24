import 'dart:io';
import 'package:facturador_offline/bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import 'package:facturador_offline/bloc/cubit_resumen/resumen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/bloc/cubit_status_apis/status_apis_cubit.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:facturador_offline/pages/page_login.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'bloc/cubit_login/login_cubit.dart';
import '../services/user_repository.dart';
import 'data/database_seeder.dart';
import 'helper/database_helper.dart';
import 'models/producto.dart';
import 'models/lista_precio_model.dart';
import 'models/user.dart';
import 'package:desktop_window/desktop_window.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await _initDatabase();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setWindowSize();
    });
  }
  runApp(BlocProviders());

}

Future<void> setWindowSize() async {
//  await DesktopWindow.toggleFullScreen();
  await DesktopWindow.setWindowSize(const Size(400, 800));
  await DesktopWindow.setFullScreen(true);
 // await DesktopWindow.setWindowSize( Size.infinite);
}

Future<void> _initDatabase() async {
  await DatabaseHelper.instance.deleteDatabaseIfExists();
  final seeder = DatabaseSeeder();
  await seeder.seedDatabase();
}

class BlocProviders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context)=> LoginCubit(UserRepository())),
        BlocProvider(create: (context)=> StatusApisCubit()),
        BlocProvider(create: (context)=> ThemaCubit()),
        BlocProvider(create: (context)=> ResumenCubit()),
        BlocProvider(create: (context)=> ListaPreciosCubit(UserRepository())),
        BlocProvider(create: (context)=> ClientesMostradorCubit(UserRepository())),
        BlocProvider(create: (context)=> ProductosCubit(UserRepository(), currentListProductCubit: [])),
      ],
      child: const Myapp()
    );
  }
}


class Myapp extends StatefulWidget {
  const Myapp({super.key});

  @override
  State<Myapp> createState() => _MyappState();
}

class _MyappState extends State<Myapp> {
  @override
  Widget build(BuildContext context) {

    final themeCubit = context.watch<ThemaCubit>();
    return MaterialApp(
      title: 'Facturador Offline',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 24),
          displayMedium: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 22),
          displaySmall: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 20),
          headlineLarge: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 18),
          headlineMedium: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 16),
          headlineSmall: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 14),
          titleLarge: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 18),
          titleSmall: TextStyle(fontFamily: 'ubuntuBold', fontWeight: FontWeight.bold, fontSize: 16),
          bodyLarge: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 14),
          bodySmall: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 12),
          labelLarge: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 14),
          labelMedium: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 12),
          labelSmall: TextStyle(fontFamily: 'ubuntuRegular', fontWeight: FontWeight.normal, fontSize: 10),
        ),
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false, // Quita el banner de depuración
      darkTheme: themeCubit.state.isDark? ThemeData.dark() :ThemeData.light() , // Tema oscuro
      themeMode:themeCubit.state.isDark?   ThemeMode.dark : ThemeMode.light, // Establece el modo de tema a oscuro
    );
  }
}

