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
        navigationController.setViewControllers([dependencies.makePlaceholderViewController()], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
