import AppIntents
import UIKit

@available(iOS 16.0, *)
struct AmberOnIntent: AppIntent {
    static let title: LocalizedStringResource = "Amber On"
    static let description = IntentDescription(
        "Turn on all amber LEDs",
        categoryName: "Device"
    )
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "leds://com.ps.TrollLEDs.AmberOn") {
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct WhiteOnIntent: AppIntent {
    static let title: LocalizedStringResource = "White On"
    static let description = IntentDescription(
        "Turn on all white LEDs",
        categoryName: "Device"
    )
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "leds://com.ps.TrollLEDs.WhiteOn") {
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct AllOnIntent: AppIntent {
    static let title: LocalizedStringResource = "All On"
    static let description = IntentDescription(
        "Turn on all LEDs",
        categoryName: "Device"
    )
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "leds://com.ps.TrollLEDs.AllOn") {
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}
