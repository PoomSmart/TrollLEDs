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

@available(iOS 16.0, *)
struct AllOffIntent: AppIntent {
    static let title: LocalizedStringResource = "All Off"
    static let description = IntentDescription(
        "Turn off all LEDs",
        categoryName: "Device"
    )
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "leds://com.ps.TrollLEDs.AllOff") {
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct ManualIntent: AppIntent {
    static let title: LocalizedStringResource = "Manual"
    static let description = IntentDescription(
        "Configure LEDs levels manually (0 - 255) (For Quad-LEDs devices only)",
        categoryName: "Device"
    )
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Cool LED 0", inclusiveRange: (0, 255))
    var coolLED0: Int

    @Parameter(title: "Cool LED 1", inclusiveRange: (0, 255))
    var coolLED1: Int

    @Parameter(title: "Warm LED 0", inclusiveRange: (0, 255))
    var warmLED0: Int

    @Parameter(title: "Warm LED 1", inclusiveRange: (0, 255))
    var warmLED1: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Configure LEDs levels to (\(\.$coolLED0), \(\.$coolLED1), \(\.$warmLED0), \(\.$warmLED1))")
    }

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "leds://com.ps.TrollLEDs.Manual?coolLED0=\(coolLED0)&coolLED1=\(coolLED1)&warmLED0=\(warmLED0)&warmLED1=\(warmLED1)") {
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            }
        }
        return .result()
    }
}
