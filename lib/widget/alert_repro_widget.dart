import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return  AlertDialog(
            backgroundColor:  Colors.purple[700]!,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: const EdgeInsets.all(0.0),
            content: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    gradient: LinearGradient(
                        colors: [
                            Colors.purple[700]!,
                            Colors.purple[500]!,
                            Colors.purple[300]!,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                    ),
                ),
                width: double.maxFinite,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                              'Que desea realizar?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                            onPressed: () {
                                // Acción para reproducir
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                ),
                            ),
                            label: Text('Compartir '),
                            icon: Icon(Icons.share),
                        ),
                        ElevatedButton.icon(
                            onPressed: () {
                                // Acción para reproducir
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                ),
                            ),
                            label: Text('Reproducir'),
                            icon: Icon(Icons.play_circle_fill ),
                        ),
                        ElevatedButton.icon(
                            onPressed: () {
                                // Acción para reproducir
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                ),
                            ),
                            label: Text('  Enviar  '),
                            icon: Icon(Icons.cast ),
                        ),
                    ],
                ),
            ),
        );
    }
}

// Para mostrar el diálogo en algún evento, como un botón presionado:
// showDialog(
//   context: context,
//   builder: (BuildContext context) => CustomDialog(),
// );
