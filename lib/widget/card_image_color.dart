import 'package:flutter/material.dart';


class CardImageColor extends StatelessWidget {

    const CardImageColor({
        Key? key,
        required String imageUrl, required this.icon,required this.title,
    }) : _imageUrl = imageUrl, super(key: key);

    final String _imageUrl;
    final bool icon;
    final String title;

    @override
    Widget build(BuildContext context) {
        return Card(
            child:  Stack(
                children: [
                    Container(
                        decoration: BoxDecoration(
                            color: Colors.black,
                            image: DecorationImage(
                                image: AssetImage('assets/images/app_icon2.png'),
                                fit: BoxFit.cover,
                            ),
                        ),
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(title,style: const TextStyle(color: Colors.white,)),
                    ),
                    icon?
                    const Align(
                        alignment:Alignment.topRight,
                        child: Icon(Icons.offline_pin_outlined,color: Colors.green,size: 25,)
                    )
                        :
                        Container()
                ],
            ),
        );
    }
}
class CardImageListColor extends StatelessWidget {
    const CardImageListColor({
        Key? key,
        required String imageUrl,
        required this.icon,
        required this.title,
    }) : _imageUrl = imageUrl, super(key: key);

    final String _imageUrl;
    final bool icon;
    final String title;

    @override
    Widget build(BuildContext context) {
        // Limitar el título a un máximo de 20 caracteres
        final truncatedTitle = title.length > 18 ? '${title.substring(0, 18)}...' : title;

        return Card(
            child: Stack(
                children: [
                    Image.asset(
                        'assets/images/app_icon2.png',
                        fit: BoxFit.cover,
                        width: 150,
                        height: 200,
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(truncatedTitle, style: const TextStyle(color: Colors.white)),
                    ),
                    icon
                        ? const Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.offline_pin_outlined, color: Colors.green, size: 25),
                    )
                        : Container(),
                ],
            ),
        );
    }
}