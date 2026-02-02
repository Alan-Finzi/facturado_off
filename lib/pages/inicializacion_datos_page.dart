import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cubit_inicializacion_datos/inicializacion_datos_cubit.dart';
import '../models/user.dart';
import '../widget/theme.dart';
import 'page_root.dart';

class InicializacionDatosPage extends StatefulWidget {
  final User user;
  final String token;

  const InicializacionDatosPage({
    Key? key,
    required this.user,
    required this.token
  }) : super(key: key);

  @override
  State<InicializacionDatosPage> createState() => _InicializacionDatosPageState();
}

class _InicializacionDatosPageState extends State<InicializacionDatosPage> {
  late InicializacionDatosCubit _inicializacionCubit;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _inicializacionCubit = InicializacionDatosCubit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstTime) {
      _isFirstTime = false;
      // Iniciar el proceso automáticamente
      _inicializacionCubit.inicializarDatos(widget.user, widget.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => _inicializacionCubit,
        child: BlocConsumer<InicializacionDatosCubit, InicializacionDatosState>(
          listener: (context, state) {
            if (state is InicializacionDatosExitosa) {
              print("✅ Inicialización completada con éxito, navegando a la pantalla principal");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => RootPage()),
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            return Container(
              decoration: ThemeGeneral.scaffoldBox(),
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Inicialización",
                        style: TextStyle(
                          fontSize: 28.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildContent(state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(InicializacionDatosState state) {
    if (state is InicializacionDatosInicial) {
      return const CircularProgressIndicator(color: Colors.white);
    } else if (state is InicializacionDatosEnProgreso) {
      return Column(
        children: [
          // Mostrar progreso
          LinearProgressIndicator(
            value: state.progreso,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          // Mensaje de progreso
          Text(
            state.mensaje,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (state is InicializacionDatosError) {
      return Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            "Error: ${state.mensaje}",
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _inicializacionCubit.inicializarDatos(widget.user, widget.token);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reintentar"),
          )
        ],
      );
    } else {
      return const CircularProgressIndicator(color: Colors.white);
    }
  }

  @override
  void dispose() {
    _inicializacionCubit.close();
    super.dispose();
  }
}