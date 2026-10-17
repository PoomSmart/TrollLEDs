# Compatibility

TrollLEDs needs iOS 10 or later and a rear flashlight with more than one color (white and amber). Devices with a single-color LED are not supported.

**API** is which control surface the app uses:

| API | UI |
|-----|----|
| Dual-LED | `Torch Level` + `Warmth`. `SetTorchManualParameters` is not used. |
| Quad-LED | Four sliders via `SetTorchManualParameters` (`Cool LED 0/1`, `Warm LED 0/1`). |
| Not supported | Adaptive / redesigned flash, or no multi-color rear LED. |

**Physical LEDs** is how many emitters the housing has. Quad-LED API devices may still have only two bulbs; the in-app Dual/Quad control is for that. There is no reliable automatic physical-count detection. Devices that share the same Apple flash name use the same physical LED count. Four physical LEDs use the Quad-LED API.

Apple’s **Dual-LED** / **Quad-LED True Tone** wording is a spec clue, not the same as TrollLEDs Dual vs Quad. iPhone 11 is Dual-LED True Tone in Apple’s identify text and two physical LEDs in this app.

**Status:** **Proven** means known with TrollLEDs, or the same four-channel `SetIndividualTorchLEDLevels` path verified on device (white and amber independently). Spec clues and failed/unconfirmed third-party reports do not make a row Proven. Unsupported devices use **N/A**.

Detection: live `AppleH6CamIn` or `AppleH9CamIn` → Dual-LED API; otherwise Quad-LED API (known CamIn list `{16, 13, 10, 9, 6}`). That is what the app implements, not a per-model guarantee.

## iPhone

| Device | API | Physical LEDs | Apple flash | Status |
|--------|-----|---------------|-------------|--------|
| iPhone 4s | Not supported | 1 | LED | N/A |
| iPhone 5 | Not supported | 1 | LED | N/A |
| iPhone 5c | Not supported | 1 | LED | N/A |
| iPhone 5s | Dual-LED | 2 (white + amber) | True Tone | Proven |
| iPhone 6 / 6 Plus | Dual-LED | 2 (white + amber) | True Tone | Proven |
| iPhone 6s / 6s Plus | Dual-LED | 2 (white + amber) | True Tone | Proven |
| iPhone SE (1st generation) | Dual-LED | 2 (white + amber) | True Tone | Proven |
| iPhone 7 / 7 Plus | Quad-LED | 4 | Quad-LED True Tone | Unverified |
| iPhone 8 / 8 Plus | Quad-LED | 4 | Quad-LED True Tone with Slow Sync | Unverified |
| iPhone X | Quad-LED | 4 | Quad-LED True Tone with Slow Sync | Unverified |
| iPhone XR | Quad-LED | 4 | Quad-LED True Tone | Proven |
| iPhone XS / XS Max | Quad-LED | 4 | Quad-LED True Tone with Slow Sync | Proven |
| iPhone 11 | Quad-LED | 2 | Dual-LED True Tone | Proven |
| iPhone 11 Pro / 11 Pro Max | Quad-LED | 2 | Dual-LED True Tone | Proven |
| iPhone SE (2nd generation) | Quad-LED | 4 | Quad-LED True Tone | Proven |
| iPhone 12 / 12 mini / 12 Pro / 12 Pro Max | Unverified | 2 | Dual-LED True Tone | Unverified |
| iPhone 13 / 13 mini / 13 Pro / 13 Pro Max | Unverified | 2 | Dual-LED True Tone | Unverified |
| iPhone SE (3rd generation) | Unverified | 2 | True Tone | Unverified |
| iPhone 14 / 14 Plus | Not supported | 2 | True Tone (not Adaptive) | N/A |
| iPhone 14 Pro / 14 Pro Max | Not supported | 9 | Adaptive True Tone | N/A |
| iPhone 15 and later (non-Pro) | Not supported | 2 | True Tone | N/A |
| iPhone 15 Pro and later Pro | Not supported | 9 | Adaptive True Tone | N/A |

## iPad

Retina Flash (front screen) is not TrollLEDs. Only a rear LED flash counts.

| Device | API | Physical LEDs | Apple flash | Status |
|--------|-----|---------------|-------------|--------|
| iPad Pro 12.9-inch (1st generation) | Not supported | None | No rear True Tone flash | N/A |
| iPad Pro 9.7-inch | Unverified | 2 | True Tone | Unverified |
| iPad Pro 12.9-inch (2nd generation) | Quad-LED | 4 | Quad-LED True Tone | Unverified |
| iPad Pro 12.9-inch (3rd generation) | Quad-LED | 4 | Quad-LED True Tone | Proven |
| iPad Pro 11-inch (1st generation) | Quad-LED | 4 | Quad-LED True Tone | Unverified |
| iPad Pro 11-inch (2nd generation) | Quad-LED | 4 | Brighter True Tone | Unverified |
| iPad Pro 11-inch (3rd generation) | Quad-LED | 4 | Brighter True Tone | Proven |
| iPad Pro 11-inch (4th generation) / 12.9-inch (4th generation) and later until M4 | Quad-LED | 4 | Brighter True Tone | Unverified |
| iPad Pro 11-inch / 13-inch (M4) | Unverified | 9 | Adaptive True Tone | Unverified |
| iPad mini (6th generation) | Quad-LED | 4 | Quad-LED True Tone | Unverified |
| iPad mini (A17 Pro) | Unverified | 2 | True Tone | Unverified |
| iPad / iPad Air (all generations) | Not supported | None | No rear flash | N/A |
| Older iPad mini (5th generation and earlier) | Not supported | None | No rear flash | N/A |
