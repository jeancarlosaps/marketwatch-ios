import UIKit

/// Composition root: the single place where screens and their dependencies are built.
@MainActor
struct AppDependencies {
    func makePlaceholderViewController() -> UIViewController {
        PlaceholderViewController()
    }
}
