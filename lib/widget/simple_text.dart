import 'package:flutter/material.dart';

class SimpleText extends StatelessWidget {
  const SimpleText(
      this.text, {
        Key? key,
        this.maxLines = 3,
        this.color = const Color.fromRGBO(45, 42, 38, 1),
        this.size = 16,
        this.fontWeight = FontWeight.normal,
        this.textAlign = TextAlign.start,
        this.height = 1.4,
        this.shouldOverflow = false,
        this.shouldUseSoftWrap = true,
      }) : super(key: key);
  final double height;
  final int maxLines;
  final String text;
  final Color color;
  final double size;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final bool shouldOverflow;
  final bool shouldUseSoftWrap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        textScaleFactor: 1.0,
        maxLines: maxLines,
        softWrap: shouldUseSoftWrap,
        textAlign: textAlign,
        overflow: shouldOverflow ? TextOverflow.ellipsis : TextOverflow.visible,
        style: TextStyle(
            height: height,
            color: this.color,
            fontSize: this.size - 2,
            fontFamily: 'SairaCondensed',
            fontWeight: fontWeight),
      ),
    );
  }
}
