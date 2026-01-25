#import "FlutterBarcodeScannerPlugin.h"
#if __has_include(<flutter_barcode_scanner/flutter_barcode_scanner-Swift.h>)
#import <flutter_barcode_scanner/flutter_barcode_scanner-Swift.h>
#else
#import "flutter_barcode_scanner-Swift.h"
#endif

@implementation FlutterBarcodeScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterBarcodeScannerPlugin registerWithRegistrar:registrar];
}
@end