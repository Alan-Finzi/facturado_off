import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Constants {
    // Cambio del color de magenta a rojo puro
    static const Color miColor = Color(0xFFFF0000);
    static const String serviceId = '3';
    static const String API_URL = Foundation.kReleaseMode
        ? "https://api-dev.moobfans.com"
        : "https://api-dev.moobfans.com";
    static const String ASSETS_URL = Foundation.kReleaseMode
        ? "https://moobfans-assets.s3.us-east-2.amazonaws.com/"
        : "https://moobfans-assets.s3.us-east-2.amazonaws.com/";
    static const String TOPIC = Foundation.kReleaseMode ? "staging" : "staging";

    static const String FLAVOR = Foundation.kReleaseMode ? "STAGING" : "STAGING";

}
