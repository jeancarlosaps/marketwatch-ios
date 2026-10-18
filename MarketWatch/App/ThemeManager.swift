import UIKit

enum AppearancePreference: String, CaseIterable {
    case automatic
    case light
    case dark

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .automatic:
            .unspecified
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

/// Stores the appearance preference and applies it to the app window, so every screen follows it.
@MainActor
final class ThemeManager {
    static let storageKey = "appearancePreference"

    private let defaults: UserDefaults
    private weak var window: UIWindow?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var preference: AppearancePreference {
        defaults.string(forKey: Self.storageKey).flatMap(AppearancePreference.init(rawValue:)) ?? .automatic
    }

    func attach(to window: UIWindow) {
        self.window = window
        apply()
    }

    func select(_ preference: AppearancePreference) {
        defaults.set(preference.rawValue, forKey: Self.storageKey)
        apply()
    }

    private func apply() {
        window?.overrideUserInterfaceStyle = preference.interfaceStyle
    }
}
