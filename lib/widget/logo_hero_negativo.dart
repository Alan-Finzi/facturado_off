import 'package:flutter/material.dart';


class LogoHeroNegativo extends StatelessWidget {
    const LogoHeroNegativo({
        Key? key,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Hero(
            tag: " imageHero",
            child: getIcon(),
        );
    }

    getIcon() {
        return SizedBox(
            width: 140,
            height: 140,
            child: Image.asset('assets/img/logo_1jpg.jpg'),
        );
    }

}


