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
import 'util/platform_service.dart';
import 'widget/platform_adaptive_widget.dart';
import 'util/constants.dart';


void main() async {
  // Inicializar el entorno Flutter y la base de datos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar plataforma específica
  final platformService = PlatformService();
  await platformService.initPlatformSettings();

  // Configurar SQLite para todas las plataformas
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Configuración para desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Configuración para móviles (SQLite ya está incluido por defecto)
    print('Inicializando SQLite para ${Platform.operatingSystem}');
    // No es necesario ninguna configuración adicional para móviles, pero
    // es bueno registrar la información para depuración
  }

  // Inicializar preferencias compartidas
  final prefs = await SharedPreferences.getInstance();
  final isFirstSyncDone = prefs.getBool('isFirstSyncDone') ?? false;

  if (!isFirstSyncDone) {
    // 🔥 Solo borra la DB la primera vez
    await DatabaseHelper.instance.deleteDatabaseIfExists();
    await prefs.setBool('isFirstSyncDone', true);
  }

  await DatabaseHelper.instance.database; // Siempre inicializa la base

  // Configurar manejo de foco
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusManager.instance.primaryFocus?.unfocus();
  });

  // Ejecutar la aplicación
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
  final PlatformService _platformService = PlatformService();

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemaCubit>();

    // Definir colores principales
    final primaryColor = Constants.miColor; // Usar el rojo puro desde Constants
    const secondaryColor = Color(0xFF3F51B5);

    // Crear tema para aplicación
    final ThemeData lightTheme = ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        onPrimary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 2.0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'ubuntuBold',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
      ),
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
    );

    // Crear tema oscuro
    final ThemeData darkTheme = ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        onPrimary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 2.0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'ubuntuBold',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
      ),
    );

    // Ajustar tamaños de fuente para móvil/desktop
    double fontSizeAdjustment = _platformService.isMobile ? 0.0 : 2.0;

    return MaterialApp(
      title: 'Facturador Offline',
      theme: lightTheme,
      darkTheme: themeCubit.state.isDark ? darkTheme : lightTheme,
      themeMode: themeCubit.state.isDark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,

      // Definir el widget inicial adaptado a la plataforma
      home: const LoginScreen(),

      // Configuraciones de plataforma adicionales
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);

        // Ajuste de escala para diferentes tamaños de pantalla
        final textScaleFactor = _platformService.isDesktop
            ? 1.0
            : (mediaQueryData.size.width < 360 ? 0.9 : 1.0);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaleFactor: textScaleFactor,
          ),
          child: child!,
        );
      },
    );
  }
}