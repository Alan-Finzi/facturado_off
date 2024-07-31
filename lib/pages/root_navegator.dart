
import 'package:facturador_offline/pages/page_clientes.dart';
import 'package:facturador_offline/pages/page_home.dart';
import 'package:facturador_offline/pages/page_nueva_venta.dart';
import 'package:facturador_offline/pages/page_productos.dart';
import 'package:facturador_offline/pages/pege_connection.dart';
import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:permission_handler/permission_handler.dart';


class RootNavScreen extends StatefulWidget {
  const RootNavScreen({Key? key}) : super(key: key);

  @override
  _RootNavScreenState createState() => _RootNavScreenState();
}

class _RootNavScreenState extends State<RootNavScreen> {
  int _currentIndex = 0;



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: _body(),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _body() => SizedBox.expand(
    child: IndexedStack(

      index: _currentIndex,
      children:    <Widget>[
     //   const ProductSearchPage(),
      //  ClientesMostradorPage(),
      //  const HomePage(),
        NuevaVentaPage(),
        ConnectionPage(),
      ],
    ),
  );

  Widget _bottomNavBar() => BottomNavyBar(
    backgroundColor: Colors.white,
    selectedIndex: _currentIndex,
    showElevation: true,
    itemCornerRadius: 24,
    curve: Curves.easeIn,
    onItemSelected: (index) => setState(() => _currentIndex = index),
    items: <BottomNavyBarItem>[
    //  BottomNavyBarItem(
    //    icon: Icon(Icons.shop ),
    //    title: Text('Productos'),
    //    activeColor: Colors.blue,
    //    textAlign: TextAlign.center,
   //   ),
    //  BottomNavyBarItem(
   //     icon: Icon(Icons.person),
   //     title: Text('Cliente'),
   //     activeColor: Colors.blue,
   //     textAlign: TextAlign.center,
   //   ),

   //   BottomNavyBarItem(
    //    icon: Icon(Icons.home),
    //    title: Text('Venta'),
   //    activeColor: Colors.blue,
    //    textAlign: TextAlign.center,
    //  ),
      BottomNavyBarItem(
        icon: Icon(Icons.home),
        title: Text('Nueva Venta'),
        activeColor: Colors.blue,
        textAlign: TextAlign.center,
      ),
      BottomNavyBarItem(
        icon: const Icon(Icons.connected_tv_outlined),
        title: const Text('Status servicios'),
        activeColor: Colors.blue,
        textAlign: TextAlign.center,
      ),
    ],
  );

}
