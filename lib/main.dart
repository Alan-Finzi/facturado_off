import 'package:facturador_offline/bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import 'package:facturador_offline/bloc/cubit_payment_methods/payment_methods_cubit.dart';
import 'package:facturador_offline/bloc/cubit_resumen/resumen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:facturador_offline/bloc/cubit_productos/productos_cubit.dart';
import 'package:facturador_offline/bloc/cubit_status_apis/status_apis_cubit.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:facturador_offline/pages/splash_screen_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/cubit_lista_precios/lista_precios_cubit.dart';
import 'bloc/cubit_login/login_cubit.dart';
import '../services/user_repository.dart';
import 'bloc/cubit_producto_precio_stock/producto_precio_stock_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'util/platform_service.dart';
import 'util/constants.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Habilitar persistencia offline de Firestore
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // Plataformas que no soportan persistencia continúan sin ella
  }

  // Inicializar plataforma específica (tamaño de ventana en desktop, etc.)
  final platformService = PlatformService();
  await platformService.initPlatformSettings();

  // Inicializar preferencias compartidas
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstSyncDone') ?? false;
  if (!isFirstRun) {
    await prefs.setBool('isFirstSyncDone', true);
  }

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
        BlocProvider(create: (context) => LoginCubit()),
        BlocProvider(create: (context) => StatusApisCubit()),
        BlocProvider(create: (context) => ThemaCubit()),
        BlocProvider(create: (context) => ResumenCubit()),
        BlocProvider(create: (context) => ListaPreciosCubit(UserRepository())),
        BlocProvider(create: (context) => ClientesMostradorCubit(UserRepository())),
        BlocProvider(
          create: (context) => ProductosMaestroCubit(),
        ),
        BlocProvider(
            create: (context) =>
                ProductosCubit(UserRepository(), currentListProductCubit: [])),
        BlocProvider(create: (context) => PaymentMethodsCubit()),
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

    final primaryColor = Constants.miColor;
    const secondaryColor = Color(0xFF3F51B5);

    final ThemeData lightTheme = ThemeData(
      hoverColor: primaryColor,
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

    final double textScaleFactor =
        _platformService.isDesktop ? 1.0 : 1.0;

    return MaterialApp(
      title: 'Facturador Offline',
      theme: lightTheme,
      darkTheme: themeCubit.state.isDark ? darkTheme : lightTheme,
      themeMode:
          themeCubit.state.isDark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreenAuth(),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaleFactor: textScaleFactor),
          child: child!,
        );
      },
    );
  }
}
