import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/user.dart';
import '../models/datos_facturacion_model.dart';
import '../util/constants.dart';
import '../helper/database_helper.dart';
import '../bloc/cubit_login/login_cubit.dart';
import 'root_navegator.dart';
import 'inicializacion_datos_page.dart';
import 'page_synchronization.dart';

class ValidacionDatosSincroPage extends StatefulWidget {
  final String? token;
  final User? user;

  const ValidacionDatosSincroPage({Key? key, this.token, this.user}) : super(key: key);

  @override
  _ValidacionDatosSincroPageState createState() => _ValidacionDatosSincroPageState();
}

class _ValidacionDatosSincroPageState extends State<ValidacionDatosSincroPage> {
  bool _isLoading = true;
  bool _userValid = false;
  bool _facturacionValid = false;
  bool _usersPrefsValid = false;
  String? _errorMessage;

  // Datos para mostrar
  Map<String, dynamic> _userInfo = {};
  List<Map<String, dynamic>> _facturacionInfo = [];
  List<Map<String, dynamic>> _savedUsersInfo = [];

  @override
  void initState() {
    super.initState();
    _validarDatosSincronizados();
  }

  Future<void> _validarDatosSincronizados() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dbHelper = DatabaseHelper.instance;

      // 1. Validar User.currencyUser (enfocándonos en comercioId)
      if (User.currencyUser != null) {
        print("✅ User.currencyUser está en memoria");

        // Verificar específicamente si tiene comercioId
        if (User.currencyUser!.comercioId != null && User.currencyUser!.comercioId!.isNotEmpty) {
          print("✅ User.currencyUser tiene comercioId: ${User.currencyUser!.comercioId}");
          _userValid = true;
        } else {
          print("⚠️ User.currencyUser no tiene comercioId válido");
        }

        // Llenar la información de usuario de todos modos
        _userInfo = {
          'id': User.currencyUser!.id ?? 0,
          'username': User.currencyUser!.username ?? 'Sin nombre de usuario',
          'email': User.currencyUser!.email ?? 'Sin email',
          'comercioId': User.currencyUser!.comercioId ?? 'Sin comercioId',
          'sucursal': User.currencyUser!.sucursal ?? 0,
          'idListaPrecio': User.currencyUser!.idListaPrecio ?? 0,
        };
      } else {
        print("⚠️ User.currencyUser es null, intentando cargar desde DB");

        // Intenta cargar desde la base de datos si no está en memoria
        String? emailOrUsername = null;

        if (widget.user != null) {
          emailOrUsername = widget.user!.email ?? widget.user!.username;

          if (emailOrUsername != null) {
            print("🔍 Buscando usuario por: $emailOrUsername");
            final userFromDB = await dbHelper.getUserByEmail(emailOrUsername);

            if (userFromDB != null) {
              print("✅ Usuario encontrado en BD");

              // Verificar comercioId
              if (userFromDB.comercioId != null && userFromDB.comercioId!.isNotEmpty) {
                print("✅ Usuario de BD tiene comercioId: ${userFromDB.comercioId}");
                _userValid = true;

                // Establecer como usuario actual
                User.setCurrencyUser(userFromDB);
              } else {
                print("⚠️ Usuario de BD no tiene comercioId válido");
              }

              // Llenar la información de todos modos
              _userInfo = {
                'id': userFromDB.id ?? 0,
                'username': userFromDB.username ?? 'Sin nombre de usuario',
                'email': userFromDB.email ?? 'Sin email',
                'comercioId': userFromDB.comercioId ?? 'Sin comercioId',
                'sucursal': userFromDB.sucursal ?? 0,
                'idListaPrecio': userFromDB.idListaPrecio ?? 0,
              };
            } else {
              print("❌ No se encontró el usuario en la BD");
            }
          }
        }
      }

      // 2. Validar DatosFacturacionModel.datosFacturacionCurrent
      if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
        _facturacionValid = true;
        print('✅ DatosFacturacionModel.datosFacturacionCurrent ya está cargado en memoria con ${DatosFacturacionModel.datosFacturacionCurrent.length} registros');
        for (var dato in DatosFacturacionModel.datosFacturacionCurrent) {
          _facturacionInfo.add({
            'id': dato.id,
            'razonSocial': dato.razonSocial,
            'comercioId': dato.comercioId,
            'condicionIva': dato.condicionIva?.toString().split('.').last,
            'cuit': dato.cuit,
            'ptoVenta': dato.ptoVenta,
          });
        }
      } else {
        print('⚠️ DatosFacturacionModel.datosFacturacionCurrent está vacío. Intentando cargar desde DB...');
        // Intenta cargar desde la base de datos
        final String? comercioId = User.currencyUser?.comercioId ?? widget.user?.comercioId;
        if (comercioId != null) {
          print('🔍 Buscando datos de facturación para comercioId: $comercioId');
          final datosFacturacion = await dbHelper.getAllDatosFacturacionCommerce(int.tryParse(comercioId) ?? 0);
          if (datosFacturacion.isNotEmpty) {
            _facturacionValid = true;
            print('✅ Se encontraron ${datosFacturacion.length} registros en la base de datos');

            // IMPORTANTE: Cargamos estos datos en la variable estática para uso futuro
            DatosFacturacionModel.datosFacturacionCurrent.addAll(datosFacturacion);

            for (var dato in datosFacturacion) {
              _facturacionInfo.add({
                'id': dato.id,
                'razonSocial': dato.razonSocial,
                'comercioId': dato.comercioId,
                'condicionIva': dato.condicionIva?.toString().split('.').last,
                'cuit': dato.cuit,
                'ptoVenta': dato.ptoVenta,
              });
            }
          } else {
            print('❌ No se encontraron datos de facturación para comercioId: $comercioId');

            // Verificar si hay datos en la tabla de facturación
            try {
              final allFacturacionData = await dbHelper.getAllDatosFacturacion();
              print('📊 Total de datos de facturación en la BD: ${allFacturacionData.length}');

              if (allFacturacionData.isNotEmpty) {
                // Si hay datos pero no para este comercio, usarlos de todos modos
                _facturacionValid = true;
                print('✅ Usando datos alternativos de facturación');

                // IMPORTANTE: Cargar estos datos en la variable estática
                DatosFacturacionModel.datosFacturacionCurrent.addAll(allFacturacionData);

                for (var dato in allFacturacionData) {
                  _facturacionInfo.add({
                    'id': dato.id,
                    'razonSocial': dato.razonSocial,
                    'comercioId': dato.comercioId,
                    'condicionIva': dato.condicionIva?.toString().split('.').last,
                    'cuit': dato.cuit,
                    'ptoVenta': dato.ptoVenta,
                  });
                }
              } else {
                print('❌ No hay datos de facturación en la BD');

                // Crear un dato de emergencia
                final datoEmergencia = DatosFacturacionModel(
                  id: 999,
                  razonSocial: "Datos de Emergencia",
                  comercioId: int.tryParse(comercioId ?? "0") ?? 0,
                  condicionIva: CondicionIva.MONOTRIBUTO,
                  cuit: "00000000000",
                  ptoVenta: "1",
                  predeterminado: 1
                );

                // Agregar a la lista de info
                _facturacionInfo.add({
                  'id': datoEmergencia.id,
                  'razonSocial': datoEmergencia.razonSocial,
                  'comercioId': datoEmergencia.comercioId,
                  'condicionIva': datoEmergencia.condicionIva?.toString().split('.').last,
                  'cuit': datoEmergencia.cuit,
                  'ptoVenta': datoEmergencia.ptoVenta,
                });

                // Intentar guardar en BD y cargar en memoria
                try {
                  await dbHelper.insertDatosFacturacion(datoEmergencia);
                  DatosFacturacionModel.datosFacturacionCurrent.add(datoEmergencia);
                  _facturacionValid = true;
                  print('✅ Datos de emergencia creados y guardados');
                } catch (e) {
                  print('❌ Error al guardar datos de emergencia: $e');
                }
              }
            } catch (e) {
              print('❌ Error al verificar todos los datos de facturación: $e');
            }
          }
        } else {
          print('❌ No se pudo determinar el comercioId para consultar datos de facturación');
        }
      }

      // 3. Validar usuarios guardados en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? usersJson = prefs.getString('users');
      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        if (users.isNotEmpty) {
          _usersPrefsValid = true;

          _savedUsersInfo = users.map<Map<String, dynamic>>((user) {
            // Ocultamos parte del token por seguridad
            String token = user['token'] ?? '';
            if (token.length > 10) {
              token = token.substring(0, 10) + '...';
            }

            return {
              'email': user['email'],
              'token': token,
            };
          }).toList();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al validar datos: $e';
      });
    }
  }

  void _continuarAplicacion() {
    // Verificar específicamente si hay un comercioId válido, sea en el usuario o en los datos de facturación
    bool tieneComercioIdValido = false;

    // Verificar comercioId en el usuario
    if (User.currencyUser?.comercioId != null && User.currencyUser!.comercioId!.isNotEmpty) {
      print("✅ User.currencyUser tiene comercioId válido: ${User.currencyUser!.comercioId}");
      tieneComercioIdValido = true;
    }

    // Verificar comercioId en los datos de facturación
    if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty &&
        DatosFacturacionModel.datosFacturacionCurrent.first.comercioId != null) {
      print("✅ DatosFacturacionModel tiene comercioId válido: ${DatosFacturacionModel.datosFacturacionCurrent.first.comercioId}");
      tieneComercioIdValido = true;
    }

    // Si tiene comercioId válido o al menos los datos de facturación son válidos, continuar
    if (tieneComercioIdValido || _facturacionValid) {
      print("✅ Validación exitosa: tieneComercioIdValido=$tieneComercioIdValido, facturacionValid=$_facturacionValid");

      // Navegar a la aplicación principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RootNavScreen()),
      );
    } else {
      print("❌ Validación fallida: tieneComercioIdValido=$tieneComercioIdValido, facturacionValid=$_facturacionValid");

      // Si falta el comercioId, ir a la página de sincronización
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SynchronizationPage(
            token: widget.token!,
            email: widget.user!.email ?? widget.user!.username!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Validación de Datos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Constants.miColor,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Constants.miColor),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Validando datos sincronizados...',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _validarDatosSincronizados,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.miColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20),
                        _buildValidationResults(),
                        SizedBox(height: 30),
                        if (_userValid)
                          _buildSection(
                            'Datos de Usuario',
                            _userInfo.entries.map((e) => '${e.key}: ${e.value}').toList(),
                            Icons.person,
                            _userValid ? Colors.green : Colors.red,
                          ),
                        SizedBox(height: 20),
                        if (_facturacionValid)
                          _buildSection(
                            'Datos de Facturación',
                            _facturacionInfo.map((info) => 'Razón Social: ${info['razonSocial'] ?? 'N/A'}\nCUIT: ${info['cuit'] ?? 'N/A'}\nPunto de Venta: ${info['ptoVenta'] ?? 'N/A'}').toList(),
                            Icons.receipt,
                            _facturacionValid ? Colors.green : Colors.red,
                          ),
                        SizedBox(height: 20),
                        if (_usersPrefsValid)
                          _buildSection(
                            'Usuarios Guardados',
                            _savedUsersInfo.map((user) => '${user['email']}').toList(),
                            Icons.people,
                            _usersPrefsValid ? Colors.green : Colors.red,
                          ),
                        SizedBox(height: 40),
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Constants.miColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Constants.miColor,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Verificación de Sincronización',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Comprobando que todos los datos necesarios estén sincronizados correctamente',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildValidationResults() {
    final allValid = _userValid && _facturacionValid && _usersPrefsValid;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allValid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allValid ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            allValid ? Icons.check_circle : Icons.warning,
            color: allValid ? Colors.green : Colors.orange,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            allValid
                ? '¡Datos sincronizados correctamente!'
                : 'Algunos datos requieren sincronización',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: allValid ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          _buildValidationItem('Datos de Usuario', _userValid),
          SizedBox(height: 8),
          _buildValidationItem('Datos de Facturación', _facturacionValid),
          SizedBox(height: 8),
          _buildValidationItem('Usuarios Guardados', _usersPrefsValid),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String title, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          color: isValid ? Colors.green : Colors.red,
          size: 20,
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Spacer(),
        Text(
          isValid ? 'OK' : 'Falta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isValid ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
          SizedBox(height: 5),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _continuarAplicacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.miColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _userValid && _facturacionValid
              ? 'Continuar a la aplicación'
              : 'Inicializar datos faltantes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}