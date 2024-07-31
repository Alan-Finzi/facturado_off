import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


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
                    CachedNetworkImage(
                        imageUrl: _imageUrl,
                        imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                                 color: Colors.black,
                                image: DecorationImage(

                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                ),
                            ),
                        ),
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(backgroundColor: Colors.purpleAccent,)),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
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
                    Image.network(
                        _imageUrl,
                        fit: BoxFit.cover,
                        width: 150, // Ajusta el ancho según tus necesidades
                        height: 200, // Ajusta la altura según tus necesidades
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