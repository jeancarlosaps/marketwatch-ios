import UIKit

/// Owns the app navigation stack. Screens are built by `AppDependencies`.
@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let dependencies: AppDependencies
    private let navigationController: UINavigationController

    init(window: UIWindow, dependencies: AppDependencies) {
        self.window = window
        self.dependencies = dependencies
        navigationController = UINavigationController()
    }

    func start() {
        let list = dependencies.makeMarketListViewController { [weak self] id, name in
            self?.openAsset(id: id, name: name)
        }
        navigationController.setViewControllers([list], animated: false)
        dependencies.themeManager.attach(to: window)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func openAsset(id: String, name: String) {
        let detail = dependencies.makeAssetDetailViewController(id: id, name: name)
        navigationController.pushViewController(detail, animated: true)
    }
}
