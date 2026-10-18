import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("App coordinator")
struct AppCoordinatorTests {
    @Test("Start installs a navigation stack with the market list as the window root")
    func startInstallsNavigationStack() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let coordinator = AppCoordinator(window: window, dependencies: AppDependencies())

        coordinator.start()

        let navigationController = try #require(window.rootViewController as? UINavigationController)
        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first is MarketListViewController)
    }

    @Test("Selecting an asset pushes a temporary detail placeholder")
    func openAssetPushesPlaceholder() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let coordinator = AppCoordinator(window: window, dependencies: AppDependencies())
        coordinator.start()

        let navigationController = try #require(window.rootViewController as? UINavigationController)
        coordinator.openAsset(id: "bitcoin", name: "Bitcoin")

        #expect(navigationController.viewControllers.count == 2)
        #expect(navigationController.viewControllers.last?.title == "Bitcoin")
    }
}
