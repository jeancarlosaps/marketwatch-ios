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
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func openAsset(id: String, name: String) {
        let placeholder = UpcomingDetailViewController(assetID: id, assetName: name)
        navigationController.pushViewController(placeholder, animated: true)
    }
}

/// Temporary destination until the asset detail screen is implemented.
private final class UpcomingDetailViewController: UIViewController {
    private let assetID: String
    private let assetName: String

    init(assetID: String, assetName: String) {
        self.assetID = assetID
        self.assetName = assetName
        super.init(nibName: nil, bundle: nil)
        title = assetName
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MWColor.canvas

        let label = UILabel()
        label.text = "Detalhes em breve"
        label.font = MWFont.body()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = MWColor.secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let idLabel = UILabel()
        idLabel.text = assetID
        idLabel.font = MWFont.percent()
        idLabel.adjustsFontForContentSizeCategory = true
        idLabel.textColor = MWColor.tertiaryLabel
        idLabel.textAlignment = .center
        idLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(idLabel)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            idLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: MWLayout.spaceXS),
            idLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            idLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }
}
