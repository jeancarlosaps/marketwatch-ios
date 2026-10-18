import Foundation
import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("Theme manager")
struct ThemeManagerTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "ThemeManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func makeWindow() -> UIWindow {
        UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    }

    @Test("Follows the system appearance by default")
    func defaultsToAutomatic() {
        let manager = ThemeManager(defaults: makeDefaults())
        let window = makeWindow()
        window.overrideUserInterfaceStyle = .dark

        manager.attach(to: window)

        #expect(manager.preference == .automatic)
        #expect(window.overrideUserInterfaceStyle == .unspecified)
    }

    @Test("Selecting a mode applies it to the window", arguments: [
        (AppearancePreference.light, UIUserInterfaceStyle.light),
        (.dark, .dark),
        (.automatic, .unspecified),
    ])
    func selectionAppliesToWindow(preference: AppearancePreference, style: UIUserInterfaceStyle) {
        let manager = ThemeManager(defaults: makeDefaults())
        let window = makeWindow()
        manager.attach(to: window)

        manager.select(preference)

        #expect(manager.preference == preference)
        #expect(window.overrideUserInterfaceStyle == style)
    }

    @Test("The preference survives a relaunch and is restored on the new window")
    func persistsAcrossLaunches() {
        let defaults = makeDefaults()
        ThemeManager(defaults: defaults).select(.dark)

        let relaunched = ThemeManager(defaults: defaults)
        let window = makeWindow()
        relaunched.attach(to: window)

        #expect(relaunched.preference == .dark)
        #expect(window.overrideUserInterfaceStyle == .dark)
    }

    @Test("An unknown stored value falls back to automatic")
    func unknownValueFallsBack() {
        let defaults = makeDefaults()
        defaults.set("sepia", forKey: ThemeManager.storageKey)

        #expect(ThemeManager(defaults: defaults).preference == .automatic)
    }

    @Test("The list menu offers the three modes and marks the current one")
    func menuMarksCurrentMode() throws {
        let defaults = makeDefaults()
        let manager = ThemeManager(defaults: defaults)
        manager.select(.light)
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: HTTPClientStub(.success(Data("[]".utf8)))))
        let controller = MarketListViewController(viewModel: viewModel, themeManager: manager) { _, _ in }

        controller.loadViewIfNeeded()

        let menu = try #require(controller.navigationItem.rightBarButtonItem?.menu)
        let actions = menu.children.compactMap { $0 as? UIAction }
        #expect(actions.map(\.title) == ["Automático", "Claro", "Escuro"])
        #expect(actions.map(\.state) == [.off, .on, .off])
        #expect(controller.navigationItem.rightBarButtonItem?.accessibilityValue == "Claro")
    }
}
