
import 'package:facturador_offline/pages/page_lista_cliente.dart';
import 'package:facturador_offline/pages/page_product_list.dart';
import 'package:facturador_offline/pages/page_nueva_venta.dart';
import 'package:facturador_offline/pages/page_venta_mobile.dart';
import 'package:facturador_offline/pages/page_ventas_sincronizacion.dart';
import 'package:facturador_offline/pages/pege_connection.dart';
import 'package:facturador_offline/widget/platform_adaptive_widget.dart';
import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';

class RootNavScreen extends StatefulWidget {
  const RootNavScreen({Key? key}) : super(key: key);

  @override
  _RootNavScreenState createState() => _RootNavScreenState();
}

class _RootNavScreenState extends State<RootNavScreen> {
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home, label: 'Nueva Venta'),
    _NavItem(icon: Icons.person, label: 'Clientes'),
    _NavItem(icon: Icons.pageview_rounded, label: 'Productos'),
    _NavItem(icon: Icons.sync, label: 'Sincronización'),
    _NavItem(icon: Icons.connected_tv_outlined, label: 'Status servicios'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    final isWide = MediaQuery.of(context).size.width >= 1200;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            labelType: isWide
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
            backgroundColor: Colors.white,
            selectedIconTheme:
                const IconThemeData(color: Colors.blue),
            selectedLabelTextStyle:
                const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            destinations: _navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _body(),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _body() => SizedBox.expand(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            ResponsiveLayoutWidget(
              smallScreenWidget: VentaMainPageMobile(),
              mediumScreenWidget: VentaMainPageMobile(),
              largeScreenWidget: VentaMainPage(),
            ),
            ClientesListPage(),
            ProductsPage(),
            PageVentasSincronizacion(),
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
        items: _navItems
            .map((item) => BottomNavyBarItem(
                  icon: Icon(item.icon),
                  title: Text(item.label),
                  activeColor: Colors.blue,
                  textAlign: TextAlign.center,
                ))
            .toList(),
      );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
