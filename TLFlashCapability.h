#ifndef TLFlashCapability_h
#define TLFlashCapability_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TLFlashAPI) {
    /// Adaptive True Tone flash; use TorchSegmentParameters / segmented ISP path (not quad manual).
    TLFlashAPISegmentedAdaptive = 0,
    /// TorchLevel + TorchColor / warmth (H6-class and similar).
    TLFlashAPILegacyDual,
    /// TorchManualParameters / SetIndividualTorchLEDLevels path.
    TLFlashAPIQuadManual,
};

/// Whether the app implements UI and property writes for @c TLFlashAPISegmentedAdaptive.
BOOL TLFlashSegmentedControlIsAvailable(void);

/// `hw.machine` product type (e.g. iPhone15,2), or nil if unavailable.
NSString *TLCopyProductType(void);

/// Default physical LED count preference for quad-manual devices (iPad Pro quad module).
BOOL TLProductPrefersQuadPhysicalLEDs(NSString *productType);

/// Live AppleH*CamIn from the known list {16, 13, 10, 9, 6}, or 0 if none.
int TLDetectISPHardwareVersion(void);

/// Whether the ISP image exports SetSegmentTorchLEDLevels (adaptive / segmented flash stack).
BOOL TLISPSupportsSegmentedTorch(int ispVersion);

/// Whether the loaded ISP image exports SetIndividualTorchLEDLevels.
BOOL TLISPSupportsIndividualTorchLEDLevels(int ispVersion);

/// H6/H9 CamIn → legacy dual; otherwise TorchManualParameters (quad-manual) for this app.
TLFlashAPI TLDetectFlashAPIForISPVersion(int ispVersion);

/// Chooses the flashlight stream API from the live AppleH*CamIn service.
TLFlashAPI TLDetectFlashAPI(void);

#endif /* TLFlashCapability_h */
