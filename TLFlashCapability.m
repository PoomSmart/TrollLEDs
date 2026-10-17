#import "TLFlashCapability.h"
#import <dlfcn.h>
#import <mach/port.h>
#import <sys/sysctl.h>

BOOL TLFlashSegmentedControlIsAvailable(void) {
    return NO;
}

NSString *TLCopyProductType(void) {
    char buffer[64];
    size_t size = sizeof(buffer);
    if (sysctlbyname("hw.machine", buffer, &size, NULL, 0) != 0)
        return nil;
    return @(buffer);
}

BOOL TLProductPrefersQuadPhysicalLEDs(NSString *productType) {
    if (!productType.length)
        return NO;
    if (TLDetectFlashAPI() != TLFlashAPIQuadManual)
        return NO;
    if (![productType hasPrefix:@"iPad"])
        return NO;
    if ([productType hasPrefix:@"iPad8,"] || [productType hasPrefix:@"iPad13,"] ||
        [productType hasPrefix:@"iPad14,"] || [productType hasPrefix:@"iPad15,"])
        return YES;
    return NO;
}

// Match the live AppleH*CamIn service. Do not infer the active ISP from which
// H*ISP.mediacapture files an IPSW happens to contain.
int TLDetectISPHardwareVersion(void) {
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (!IOKit)
        return 0;

    mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
    if (!kIOMasterPortDefault)
        kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMainPortDefault");
    CFMutableDictionaryRef (*IOServiceMatching)(const char *name) =
        (CFMutableDictionaryRef(*)(const char *))dlsym(IOKit, "IOServiceMatching");
    mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) =
        (mach_port_t(*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
    kern_return_t (*IOObjectRelease)(mach_port_t object) =
        (kern_return_t(*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");

    if (!kIOMasterPortDefault || !IOServiceMatching || !IOServiceGetMatchingService || !IOObjectRelease) {
        dlclose(IOKit);
        return 0;
    }

    static const int kVersions[] = {16, 13, 10, 9, 6};
    int detected = 0;
    for (size_t i = 0; i < sizeof(kVersions) / sizeof(kVersions[0]); i++) {
        int ver = kVersions[i];
        char serviceName[16];
        snprintf(serviceName, sizeof(serviceName), "AppleH%dCamIn", ver);
        mach_port_t port = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching(serviceName));
        if (port) {
            IOObjectRelease(port);
            detected = ver;
            break;
        }
    }

    dlclose(IOKit);
    return detected;
}

static BOOL TLISPDlsym(int ispVersion, const char *symbol) {
    if (ispVersion <= 0 || !symbol)
        return NO;

    char imagePath[64];
    snprintf(imagePath, sizeof(imagePath), "/System/Library/MediaCapture/H%dISP.mediacapture", ispVersion);
    void *image = dlopen(imagePath, RTLD_NOW);
    if (!image)
        return NO;

    BOOL found = dlsym(image, symbol) != NULL;
    dlclose(image);
    return found;
}

BOOL TLISPSupportsSegmentedTorch(int ispVersion) {
    if (ispVersion < 10)
        return NO;

    char symbol[80];
    snprintf(symbol, sizeof(symbol), "__ZN6H%dISP12H%dISPDevice24SetSegmentTorchLEDLevelsEjhhhPKtPKy", ispVersion,
             ispVersion);
    return TLISPDlsym(ispVersion, symbol);
}

BOOL TLISPSupportsIndividualTorchLEDLevels(int ispVersion) {
    if (ispVersion <= 0)
        return NO;

    char symbol[72];
    if (ispVersion < 10)
        snprintf(symbol, sizeof(symbol), "__ZN5H%dISP11H%dISPDevice27SetIndividualTorchLEDLevelsEjj", ispVersion,
                 ispVersion);
    else
        snprintf(symbol, sizeof(symbol), "__ZN6H%dISP12H%dISPDevice27SetIndividualTorchLEDLevelsEjj", ispVersion,
                 ispVersion);

    return TLISPDlsym(ispVersion, symbol);
}

TLFlashAPI TLDetectFlashAPIForISPVersion(int ispVersion) {
    // TrollLEDs stream API: H6/H9 use TorchLevel + TorchColor. Everything else that this app
    // currently supports uses TorchManualParameters. Do not require a matching H*ISP.mediacapture
    // on disk: CamIn generation and plugin filename are not the same numbering, and IPSWs ship
    // extra plugins. Missing plugin used to be classified as legacy and showed two sliders on
    // iPhone 11.
    if (ispVersion == 6 || ispVersion == 9)
        return TLFlashAPILegacyDual;
    return TLFlashAPIQuadManual;
}

TLFlashAPI TLDetectFlashAPI(void) {
    int ispVersion = TLDetectISPHardwareVersion();
    TLFlashAPI api = TLDetectFlashAPIForISPVersion(ispVersion);
    NSLog(@"TrollLEDs: AppleH%dCamIn; flash API = %ld", ispVersion, (long)api);
    return api;
}
