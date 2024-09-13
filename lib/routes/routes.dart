import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../main.dart';
import '../pages/page_forma_cobro.dart';
import '../pages/page_home.dart';
import '../pages/root_navegator.dart';



Route<dynamic>? onGeneratedRoutes(RouteSettings settings) {
    switch (settings.name) {
        case "home":
            return PageTransition(
                duration: const Duration(milliseconds: 200),
                //child: const PublicHomeScreen(),
                child:   HomePage(),
                type: PageTransitionType.rightToLeft);

        default:
            return PageTransition(
                duration: const Duration(milliseconds: 200),
                child: customRoutes[settings.name]!,
                type: PageTransitionType.fade,
                settings: settings);
    }
}

var customRoutes = <String, Widget>{
   // "splash": const SplashScreen(),
    "home"  :  HomePage(),
   // "main"  :   App(),
    "Root"  : const RootNavScreen(),

};
