# TrollLEDs

 A TrollStore application to control individual flashlight LEDs for iOS devices.

 When used on a jailbroken device, remove Amber tweak becase this app will simply be overridden by it.

## Supported Devices

- iOS 12 or higher, lower versions are not supported/tested
- iPhone or iPad with multiple of different flashlight LEDs (e.g. amber and regular white)
- Devices with single-color flashlight LED(s) are not supported, such as iPhone 4s and iPhone 5
- **iPhone 14 series and higher are not supported**, as [Apple has completely redesigned the flashlight LEDs](https://appleinsider.com/articles/22/09/20/how-iphone-14-pro-adaptive-true-tone-flash-creates-perfect-light-for-your-photos)

## Usage (Quad-LEDs Devices)

Quad-LEDs devices are devices with four programmatically configurable flashlight LEDs, two white and two amber. This includes the devices such as iPhone 11 and iPad Pro 3rd generation.

### Sliders

There are four sliders in the app:

1. `Cool LED 0` - The brightness of the first white LED
2. `Cool LED 1` - The brightness of the second white LED
3. `Warm LED 0` - The brightness of the first amber LED
4. `Warm LED 1` - The brightness of the second amber LED

Each slider can be adjusted independently. The more the value, the more brightness of the LED will get. If the value is set to 0, the LED will be off. If all sliders are set to 0, all LEDs will be off.

Devices with four physical LEDs such as iPad Pro 3rd generation will get the maximum brightness of the LEDs when all sliders are set to 100%. However, devices with two physical LEDs such as iPhone 11 will get the maximum brightness of the LEDs when `Cool LED 0` and `Warm LED 0` are set to 100%, while the others are set to 0%. The `Cool LED 1` and `Warm LED 1` sliders only act as a low brightness mode for their `LED 0` equivalent.

### Physical LED Count

Despite being categorized as a quad-LEDs device, it may have only two physical LEDs. TrollLEDs allows you to explicitly set the physical LED count in the app (There is no good way to automatically detect the physical LED count, yet).

If the value is set to `Dual`:

1. The app shortcut `Amber On` will maximize the `Warm LED 0` slider only
2. The app shortcut `White On` will maximize the `Cool LED 0` slider only
3. The app shortcut `All On` will maximize the `Cool LED 0` and `Warm LED 0` sliders only

If the value is set to `Quad`, the app shortcuts will maximize all related sliders.

## Usage (Dual-LEDs Devices)

Dual-LEDs devices are devices with two programmatically configurable flashlight LEDs, such as iPhone 5s and iPhone SE 1st generation.

There are two sliders in the app:

1. `Torch Level` - The brightness of the LEDs
2. `Warmth` - The "warmth" of the light color

Unlike [Amber tweak](https://github.com/PoomSmart/Amber), this app cannot force the two LEDs to be on at the same time. You can use `Torch Level` slider to control the brightness of the LEDs just as you can from the Control Center, but the `Warmth` slider will only set the warm percentile of the scene. The more the value, the more brightness of the amber LED will get, resulting in a warmer light color. If `Warmth` is set to the max, only the amber LED will be on.

## Limitation

### Exclusive Control

TrollLEDs utilizes the `mediaserverd`-exclusive `BWFigCaptureDeviceVendor` class to control the flashlight LEDs.
This creates an instance of `BWFigCaptureDevice` (or `OpaqueFigCaptureDeviceRef`). There can only be one instance at a time, so if there is another app that creates it (i.e., `mediaserverd`), TrollLEDs will not be able to control the flashlight LEDs.
This is why there is a switch at the top of the app to lock the flashlight LEDs to TrollLEDs only. If you want to use the LEDs (or use the Camera app) from somewhere else, you can either turn off the switch (and wait few seconds) or kill the app.

### Battery Concern

As long as TrollLEDs app is running, the flashlight device connection will be kept alive. This may cause battery drain, as reported by some users. To mitigate this issue, the app will automatically kill itself after 5 minutes of inactivity.

## Building

Build `.tipa` (sandboxed and unsandboxed) and `.deb` (rootful and rootless) with:

```sh
./build.sh
```

## Future Plans

1. More accessible sliders (are they too small?)
2. Better error handling?
