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

      // 1. Validar User.currencyUser
      if (User.currencyUser != null) {
        _userValid = true;
        _userInfo = {
          'id': User.currencyUser!.id,
          'username': User.currencyUser!.username,
          'email': User.currencyUser!.email,
          'comercioId': User.currencyUser!.comercioId,
          'sucursal': User.currencyUser!.sucursal,
          'idListaPrecio': User.currencyUser!.idListaPrecio,
        };
      } else {
        // Intenta cargar desde la base de datos si no está en memoria
        if (widget.user != null && widget.user!.username != null) {
          final userFromDB = await dbHelper.getUserByEmail(widget.user!.username!);
          if (userFromDB != null) {
            _userValid = true;
            _userInfo = {
              'id': userFromDB.id,
              'username': userFromDB.username,
              'email': userFromDB.email,
              'comercioId': userFromDB.comercioId,
              'sucursal': userFromDB.sucursal,
              'idListaPrecio': userFromDB.idListaPrecio,
            };
          }
        }
      }

      // 2. Validar DatosFacturacionModel.datosFacturacionCurrent
      if (DatosFacturacionModel.datosFacturacionCurrent.isNotEmpty) {
        _facturacionValid = true;
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
        // Intenta cargar desde la base de datos
        final String? comercioId = User.currencyUser?.comercioId ?? widget.user?.comercioId;
        if (comercioId != null) {
          final datosFacturacion = await dbHelper.getAllDatosFacturacionCommerce(int.tryParse(comercioId) ?? 0);
          if (datosFacturacion.isNotEmpty) {
            _facturacionValid = true;
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
          }
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
    if (_userValid && _facturacionValid) {
      // Si todo está validado correctamente, navegar a la aplicación principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RootNavScreen()),
      );
    } else {
      // Si falta algún dato, ir a la página de sincronización
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