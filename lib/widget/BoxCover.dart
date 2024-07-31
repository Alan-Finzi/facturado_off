import 'package:flutter/material.dart';



class BoxCover extends StatelessWidget {
    const BoxCover({
        Key? key,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
                width: 1000,
                height: 1000,
                child: Container(color: Colors.black),
            ),
        );
    }
}

