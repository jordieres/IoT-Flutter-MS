#import "VeepooSdkPlugin.h"
#if __has_include(<veepoo_sdk/veepoo_sdk-Swift.h>)
#import <veepoo_sdk/veepoo_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "veepoo_sdk-Swift.h"
#endif

@implementation VeepooSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVeepooSdkPlugin registerWithRegistrar:registrar];
}
@end
