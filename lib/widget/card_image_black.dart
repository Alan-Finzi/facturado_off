import 'package:flutter/material.dart';



class CardImageBlack extends StatelessWidget {
    const CardImageBlack({
        Key? key,
        required String imageUrl, required this.title,
    }) : _imageUrl = imageUrl, super(key: key);

    final String _imageUrl;
    final String title;

    @override
    Widget build(BuildContext context) {
        return Card(
            child:  Container(
                child:  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(title,style: const TextStyle(color: Colors.white)),
                    ),
                ),
                decoration:  BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(3.0)
                    ),
                    image:  DecorationImage(
                        fit: BoxFit.cover,
                        colorFilter:  const ColorFilter.mode(Colors.white, BlendMode.saturation),
                        image:  NetworkImage(_imageUrl,),
                    ),
                ),
            ),
        );
    }
}