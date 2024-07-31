import 'package:flutter/material.dart';



class TextContainer extends StatelessWidget {
    final double width;
    final double? h;
    final Widget widget;
    final double paddH;
    final double paddv;
    final Color colors;
    const TextContainer({
        Key? key, required this.widget, required this.width, this.h, required this.paddH, required this.paddv, required this.colors,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration:  BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                ),
                color: colors,
            ),
            height: h,
            width: width,
            //color: Colors.white,
            child: Padding(
                padding:  EdgeInsets.symmetric(
                    horizontal: paddH,
                    vertical:paddv),
                child: widget
            ),
        );
    }
}