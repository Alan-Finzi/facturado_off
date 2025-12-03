import 'dart:io';
import 'package:facturador_offline/bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import 'package:facturador_offline/bloc/cubit_payment_methods/payment_methods_cubit.dart';
import 'package:facturador_offline/bloc/cubit_resumen/resumen_cubit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/bloc/cubit_status_apis/status_apis_cubit.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:facturador_offline/pages/page_login.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'bloc/cubit_login/login_cubit.dart';
import '../services/user_repository.dart';
import 'bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import 'data/database_seeder.dart';
import 'helper/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  sqfliteFfiInit();
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;

  final prefs = await SharedPreferences.getInstance();
  final isFirstSyncDone = prefs.getBool('isFirstSyncDone') ?? false;

  if (!isFirstSyncDone) {
    // 🔥 Solo borra la DB la primera vez
    await DatabaseHelper.instance.deleteDatabaseIfExists();
    await prefs.setBool('isFirstSyncDone', true);
  }

  await DatabaseHelper.instance.database; // Siempre inicializa la base

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusManager.instance.primaryFocus?.unfocus();
  });

  runApp(BlocProviders());
}




class BlocProviders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LoginCubit( )),
        BlocProvider(create: (context) => StatusApisCubit()),
        BlocProvider(create: (context) => ThemaCubit()),
        BlocProvider(create: (context) => ResumenCubit()),
        BlocProvider(create: (context) => ListaPreciosCubit(UserRepository())),
        BlocProvider(create: (context) => ClientesMostradorCubit(UserRepository())),
        BlocProvider(
            create: (context) {
              final loginCubit = BlocProvider.of<LoginCubit>(context);
              return ProductosMaestroCubit( );
            }
        ),
        BlocProvider(create: (context) => ProductosCubit(UserRepository(), currentListProductCubit: [])),
        BlocProvider(create: (context) => PaymentMethodsCubit(databaseHelper: DatabaseHelper.instance)),
      ],
      child: const Myapp(),
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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false, // Quita el banner de depuración
      darkTheme: themeCubit.state.isDark? ThemeData.dark() :ThemeData.light() , // Tema oscuro
      themeMode:themeCubit.state.isDark?   ThemeMode.dark : ThemeMode.light, // Establece el modo de tema a oscuro
    );
  }
}

