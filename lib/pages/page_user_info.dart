import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/datos_facturacion_model.dart';
import '../util/constants.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  // Datos del usuario actual en memoria
  Map<String, dynamic> _userData = {};

  // Datos de facturación en memoria
  List<Map<String, dynamic>> _facturacionData = [];

  // Lista de usuarios guardados en SharedPreferences
  List<Map<String, dynamic>> _savedUsers = [];

  // Para manejar las pestañas
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Cargar los datos del usuario actual en memoria (User.currencyUser)
      if (User.currencyUser != null) {
        _userData = {
          'id': User.currencyUser!.id,
          'username': User.currencyUser!.username,
          'email': User.currencyUser!.email,
          'comercioId': User.currencyUser!.comercioId,
          'sucursal': User.currencyUser!.sucursal,
          'idListaPrecio': User.currencyUser!.idListaPrecio,
          'profile': User.currencyUser!.profile,
          'status': User.currencyUser!.status,
          'nombreUsuario': User.currencyUser!.nombreUsuario,
          'apellidoUsuario': User.currencyUser!.apellidoUsuario,
        };
      }

      // 2. Cargar los datos de facturación en memoria
      for (var dato in DatosFacturacionModel.datosFacturacionCurrent) {
        _facturacionData.add({
          'id': dato.id,
          'razonSocial': dato.razonSocial,
          'comercioId': dato.comercioId,
          'condicionIva': dato.condicionIva?.toString().split('.').last,
          'cuit': dato.cuit,
          'ptoVenta': dato.ptoVenta,
          'domicilioFiscal': dato.domicilioFiscal,
          'predeterminado': dato.predeterminado,
        });
      }

      // 3. Cargar la lista de usuarios guardados en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? usersJson = prefs.getString('users');
      if (usersJson != null) {
        List<dynamic> users = jsonDecode(usersJson);
        _savedUsers = users.map<Map<String, dynamic>>((user) {
          // Ocultamos parte del token para seguridad
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
    }
  }

  // Widget para mostrar secciones de información con título
  Widget _buildInfoSection(String title, List<MapEntry<String, dynamic>> entries) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Constants.miColor,
              ),
            ),
            Divider(),
            ...entries.map((entry) => _buildInfoRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar filas de información (clave-valor)
  Widget _buildInfoRow(String key, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información de Usuario'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Usuario Actual'),
            Tab(text: 'Facturación'),
            Tab(text: 'Usuarios Guardados'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando información...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Usuario Actual (User.currencyUser)
                    _buildUserInfoTab(),

                    // Tab 2: Datos de Facturación
                    _buildDatosFacturacionTab(),

                    // Tab 3: Usuarios Guardados
                    _buildSavedUsersTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: Icon(Icons.refresh),
        tooltip: 'Actualizar datos',
      ),
    );
  }

  Widget _buildUserInfoTab() {
    if (_userData.isEmpty) {
      return Center(child: Text('No hay información del usuario actual'));
    }

    // Convertir el mapa a una lista de entradas para mostrar
    List<MapEntry<String, dynamic>> entries = _userData.entries.toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundColor: Constants.miColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 50,
              color: Constants.miColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '${_userData['username'] ?? 'Usuario'}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_userData['email'] ?? ''}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          _buildInfoSection('Información de Usuario', entries),
        ],
      ),
    );
  }

  Widget _buildDatosFacturacionTab() {
    if (_facturacionData.isEmpty) {
      return Center(child: Text('No hay información de facturación disponible'));
    }

    return ListView.builder(
      itemCount: _facturacionData.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> dato = _facturacionData[index];
        List<MapEntry<String, dynamic>> entries = dato.entries.toList();

        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dato['razonSocial'] ?? 'Sin Razón Social',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Constants.miColor,
                      ),
                    ),
                    if (dato['predeterminado'] == 1)
                      Chip(
                        label: Text('Predeterminado'),
                        backgroundColor: Colors.green[100],
                      ),
                  ],
                ),
                Divider(),
                ...entries.map((entry) {
                  // Omitir la razón social porque ya la mostramos como título
                  if (entry.key == 'razonSocial') return SizedBox();
                  return _buildInfoRow(entry.key, entry.value);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedUsersTab() {
    if (_savedUsers.isEmpty) {
      return Center(child: Text('No hay usuarios guardados'));
    }

    return ListView.builder(
      itemCount: _savedUsers.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> user = _savedUsers[index];

        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Constants.miColor.withOpacity(0.2),
              child: Text(
                user['email'].toString().substring(0, 1).toUpperCase(),
                style: TextStyle(color: Constants.miColor),
              ),
            ),
            title: Text(user['email'] ?? 'Sin email'),
            subtitle: Text('Token: ${user['token'] ?? 'Sin token'}'),
            trailing: Icon(Icons.arrow_right),
          ),
        );
      },
    );
  }
}