import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:usb_thermal_printer_web/usb_thermal_printer_web.dart';

class Imprimir extends StatefulWidget {
  const Imprimir({super.key});

  @override
  State<Imprimir> createState() => _ImprimirState();
}

class _ImprimirState extends State<Imprimir> {


  WebThermalPrinter _printer = WebThermalPrinter();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              //Pairing Device is required.
              await _printer.pairDevice(vendorId: 0x6868, productId: 0x0200);

              await _printer.printText('DKT Mart',
                  bold: true, centerAlign: true);
              await _printer.printEmptyLine();

              await _printer.printRow("Products", "Sale");
              await _printer.printEmptyLine();

              for (int i = 0; i < 10; i++) {

                await _printer.printRow('A big title very big title ${i + 1}',
                    '${(i + 1) * 510}.00 AED');
                await _printer.printEmptyLine();

              }

              await _printer.printDottedLine();
              await _printer.printEmptyLine();

              await _printer.printBarcode('123456');
              await _printer.printEmptyLine();

              await _printer.printEmptyLine();
              await _printer.closePrinter();
            },
            child: const Text('Imprimir "Hola mundo"'),
          ),
        ),
      ),
    );
  }

  // Método para imprimir utilizando CUPS
  printUsingCUPS(String filePath) async {
    print('Ruta completa del archivo: $filePath');
    var result = await Process.run('lp', ['-d', 'Xprinter_USB_Printer_P', filePath]);
    print('Resultado del comando: ${result.stdout}');
    print('Error del comando: ${result.stderr}');

    if (result.exitCode == 0) {
      print('Impresión enviada correctamente.');
      _showMessage('Impresión enviada correctamente.');
    } else {
      print('Error al enviar la impresión: ${result.stderr}');
      _showMessage('Error al enviar la impresión.');
    }
  }

  Future<String> createPrintFile(String content) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/print_file.txt');

    // Comandos ESC/POS para centrar el texto y agregar un salto de línea
    List<int> bytes = [];
    bytes += utf8.encode('\x1B\x61\x01');  // Centra el texto
    bytes += utf8.encode(content);
    bytes += utf8.encode('\n');  // Salto de línea
    bytes += utf8.encode('\x1B\x64\x02');  // Avanza 2 líneas
    bytes += utf8.encode('\x1D\x56\x00');  // Corte de papel

    await file.writeAsBytes(bytes);

    // Verifica el contenido del archivo
    String fileContent = await file.readAsString();
    print('Contenido del archivo: $fileContent');

    return file.path;
  }


  // Mostrar mensaje al usuario
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
