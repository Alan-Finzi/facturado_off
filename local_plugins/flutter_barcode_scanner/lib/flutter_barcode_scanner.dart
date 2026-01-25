import 'dart:async';
import 'package:flutter/services.dart';

enum ScanMode { DEFAULT, QR, BARCODE }

class FlutterBarcodeScanner {
  static const MethodChannel _channel =
      const MethodChannel('flutter_barcode_scanner');

  /// Initialize barcode scanner with default options
  static Future<String> scanBarcode(
      String lineColor, String cancelButtonText, bool isShowFlashIcon, ScanMode scanMode) async {
    try {
      final String barcodeScanResult = await _channel.invokeMethod('scanBarcode', <String, dynamic>{
        "lineColor": lineColor,
        "cancelButtonText": cancelButtonText,
        "isShowFlashIcon": isShowFlashIcon,
        "scanMode": scanMode.index,
      });
      return barcodeScanResult;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }
}