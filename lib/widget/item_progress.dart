
// @dart=2.12
import 'package:flutter/material.dart';


class ItemProgress extends StatefulWidget {
    final int status;
    final int index;

    const ItemProgress({required Key key,  required this.status, required this.index}) : super(key: key);
    @override
    _ItemProgressState createState() => _ItemProgressState();
}


class _ItemProgressState extends State<ItemProgress> {




    @override
    Widget build(BuildContext context) {
        return  const Center(child:CircularProgressIndicator(backgroundColor: Colors.purpleAccent,),);
    }
}
