import 'package:flutter/material.dart';

class SimpleTitle extends StatelessWidget {
  const SimpleTitle({
    Key? key,
    required this.title,
    this.size = 24,
    this.height = 1.0,
    this.letterSpacing = 0.5,
    this.color = const Color.fromRGBO(45, 42, 38, 1),
    this.hasPadding = true,
  }) : super(key: key);
  final Color color;
  final double size;
  final String? title;
  final double height;
  final double letterSpacing;
  final bool hasPadding;

  @override
  Widget build(BuildContext context) {
    if (hasPadding) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          title!,
          textScaleFactor: 1.0,
          style: TextStyle(
            letterSpacing: letterSpacing,
            height: height,
            color: this.color,
            fontWeight: FontWeight.w900,
            fontSize: this.size - 2,
            fontFamily: 'SairaExtraCondensed',
          ),
        ),
      );
    }
    return Text(
      title!,
      textScaleFactor: 1.0,
      style: TextStyle(
        letterSpacing: letterSpacing,
        height: height,
        color: this.color,
        fontWeight: FontWeight.w900,
        fontSize: this.size - 2,
        fontFamily: 'SairaExtraCondensed',
      ),
    );
  }
}
