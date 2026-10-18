import UIKit

/// Composition root: the single place where screens and their dependencies are built.
@MainActor
struct AppDependencies {
    let coinGeckoService: CoinGeckoService

    init(coinGeckoService: CoinGeckoService = CoinGeckoService(client: AlamofireHTTPClient())) {
        self.coinGeckoService = coinGeckoService
    }

    func makeMarketListViewController(
        onSelectAsset: @escaping (String, String) -> Void
    ) -> UIViewController {
        let viewModel = MarketListViewModel(service: coinGeckoService)
        return MarketListViewController(viewModel: viewModel, onSelectAsset: onSelectAsset)
    }
}
