import UIKit

/// Composition root: the single place where screens and their dependencies are built.
@MainActor
struct AppDependencies {
    let coinGeckoService: CoinGeckoService
    let themeManager: ThemeManager

    init(coinGeckoService: CoinGeckoService = CoinGeckoService(client: AlamofireHTTPClient()),
         themeManager: ThemeManager? = nil)
    {
        self.coinGeckoService = coinGeckoService
        self.themeManager = themeManager ?? ThemeManager()
    }

    func makeMarketListViewController(onSelectAsset: @escaping (String, String) -> Void) -> UIViewController {
        let viewModel = MarketListViewModel(service: coinGeckoService)
        return MarketListViewController(viewModel: viewModel, themeManager: themeManager, onSelectAsset: onSelectAsset)
    }

    func makeAssetDetailViewController(id: String, name: String) -> UIViewController {
        let viewModel = AssetDetailViewModel(id: id, service: coinGeckoService)
        let controller = AssetDetailViewController(viewModel: viewModel)
        controller.title = name
        return controller
    }
}
