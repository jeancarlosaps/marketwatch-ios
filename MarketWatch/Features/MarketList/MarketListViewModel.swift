import Foundation
import RxCocoa
import RxSwift

struct MarketListItem: Equatable {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let priceText: String
    let changePercent: Decimal?
    let accessibilityLabel: String
}

enum MarketListContentState: Equatable {
    case loading
    case items([MarketListItem])
    case empty
    case searchEmpty
    case error(String)
}

enum MarketListFooterState: Equatable {
    case hidden
    case loading
    case error(String)
}

/// Owns list loading, local search, pagination and refresh. UIKit-free.
final class MarketListViewModel {
    private let service: CoinGeckoService
    private let perPage: Int
    private var fetchDisposable: Disposable?

    private let contentRelay = BehaviorRelay<MarketListContentState>(value: .loading)
    private let footerRelay = BehaviorRelay<MarketListFooterState>(value: .hidden)
    private let isRefreshingRelay = BehaviorRelay<Bool>(value: false)
    private let assetSelectedRelay = PublishRelay<(id: String, name: String)>()

    private var allCoins: [MarketCoin] = []
    private var searchQuery = ""
    private var nextPage = 1
    private var hasMore = true
    private var isFetching = false
    private var generation = 0

    private let priceFormatter = MarketListViewModel.makePriceFormatter()
    private let percentFormatter = MarketListViewModel.makePercentFormatter()

    var content: Driver<MarketListContentState> {
        contentRelay.asDriver()
    }

    var footer: Driver<MarketListFooterState> {
        footerRelay.asDriver()
    }

    var isRefreshing: Driver<Bool> {
        isRefreshingRelay.asDriver()
    }

    var assetSelected: Signal<(id: String, name: String)> {
        assetSelectedRelay.asSignal()
    }

    /// Observable mirrors for unit tests that avoid Driver's main-thread requirement.
    var contentValues: Observable<MarketListContentState> {
        contentRelay.asObservable()
    }

    var footerValues: Observable<MarketListFooterState> {
        footerRelay.asObservable()
    }

    var isRefreshingValues: Observable<Bool> {
        isRefreshingRelay.asObservable()
    }

    init(service: CoinGeckoService, perPage: Int = CoinGeckoService.defaultPerPage) {
        self.service = service
        self.perPage = perPage
    }

    func loadInitial() {
        guard allCoins.isEmpty else { return }
        contentRelay.accept(.loading)
        footerRelay.accept(.hidden)
        fetch(page: 1, replace: true, triggeredByRefresh: false)
    }

    func refresh() {
        isRefreshingRelay.accept(true)
        fetch(page: 1, replace: true, triggeredByRefresh: true)
    }

    func retryInitial() {
        contentRelay.accept(.loading)
        footerRelay.accept(.hidden)
        fetch(page: 1, replace: true, triggeredByRefresh: false)
    }

    func retryPagination() {
        guard !isSearchActive, hasMore else { return }
        fetch(page: nextPage, replace: false, triggeredByRefresh: false)
    }

    func loadNextPageIfNeeded(showingIndex index: Int) {
        guard !isSearchActive, hasMore, !isFetching else { return }
        let threshold = max(allCoins.count - 5, 0)
        guard index >= threshold else { return }
        fetch(page: nextPage, replace: false, triggeredByRefresh: false)
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        publishContent()
        if isSearchActive {
            footerRelay.accept(.hidden)
        }
    }

    func selectItem(at index: Int) {
        let items = visibleItems()
        guard items.indices.contains(index) else { return }
        let item = items[index]
        assetSelectedRelay.accept((id: item.id, name: item.name))
    }

    private var isSearchActive: Bool {
        !searchQuery.isEmpty
    }

    private func fetch(page: Int, replace: Bool, triggeredByRefresh: Bool) {
        if replace {
            fetchDisposable?.dispose()
            generation += 1
            isFetching = false
            nextPage = 1
            hasMore = true
            footerRelay.accept(.hidden)
        }

        guard !isFetching else { return }
        guard hasMore || replace else { return }

        isFetching = true
        let requestGeneration = generation

        if !replace {
            footerRelay.accept(.loading)
        }

        fetchDisposable = service.markets(page: page, perPage: perPage)
            .subscribe(
                onSuccess: { [weak self] coins in
                    self?.handleSuccess(
                        coins,
                        page: page,
                        replace: replace,
                        triggeredByRefresh: triggeredByRefresh,
                        generation: requestGeneration
                    )
                },
                onFailure: { [weak self] error in
                    self?.handleFailure(
                        error,
                        replace: replace,
                        triggeredByRefresh: triggeredByRefresh,
                        generation: requestGeneration
                    )
                }
            )
    }

    private func handleSuccess(
        _ coins: [MarketCoin],
        page: Int,
        replace: Bool,
        triggeredByRefresh: Bool,
        generation requestGeneration: Int
    ) {
        guard requestGeneration == generation else { return }

        isFetching = false
        if triggeredByRefresh {
            isRefreshingRelay.accept(false)
        }

        if replace {
            allCoins = coins
        } else {
            let existingIDs = Set(allCoins.map(\.id))
            let unique = coins.filter { !existingIDs.contains($0.id) }
            allCoins.append(contentsOf: unique)
        }

        nextPage = page + 1
        hasMore = coins.count >= perPage
        footerRelay.accept(.hidden)
        publishContent()
    }

    private func handleFailure(
        _ error: Error,
        replace: Bool,
        triggeredByRefresh: Bool,
        generation requestGeneration: Int
    ) {
        guard requestGeneration == generation else { return }

        isFetching = false
        if triggeredByRefresh {
            isRefreshingRelay.accept(false)
        }

        let message = Self.userMessage(for: error)

        if allCoins.isEmpty {
            contentRelay.accept(.error(message))
            footerRelay.accept(.hidden)
            return
        }

        if replace {
            publishContent()
            footerRelay.accept(.hidden)
            return
        }

        footerRelay.accept(.error(message))
        publishContent()
    }

    private func publishContent() {
        if allCoins.isEmpty {
            contentRelay.accept(.empty)
            return
        }

        let items = visibleItems()
        if isSearchActive, items.isEmpty {
            contentRelay.accept(.searchEmpty)
        } else {
            contentRelay.accept(.items(items))
        }
    }

    private func visibleItems() -> [MarketListItem] {
        let source: [MarketCoin]
        if isSearchActive {
            let query = searchQuery.lowercased()
            source = allCoins.filter {
                $0.name.lowercased().contains(query) || $0.symbol.lowercased().contains(query)
            }
        } else {
            source = allCoins
        }
        return source.map(makeItem)
    }

    private func makeItem(from coin: MarketCoin) -> MarketListItem {
        let priceText = coin.currentPrice.map(formatPrice) ?? "—"
        let symbol = coin.symbol.uppercased()
        let change = coin.priceChangePercentage24h
        let changeDescription = change.map(formatChangeDescription) ?? "variação indisponível"

        return MarketListItem(
            id: coin.id,
            name: coin.name,
            symbol: symbol,
            imageURL: coin.imageURL,
            priceText: priceText,
            changePercent: change,
            accessibilityLabel: "\(coin.name), \(symbol), \(priceText), \(changeDescription)"
        )
    }

    private func formatPrice(_ value: Decimal) -> String {
        priceFormatter.string(from: value as NSDecimalNumber) ?? "—"
    }

    private func formatChangeDescription(_ percent: Decimal) -> String {
        let magnitude = percent < 0 ? -percent : percent
        let value = percentFormatter.string(from: magnitude as NSDecimalNumber) ?? "0,00%"
        if percent > 0 {
            return "alta +\(value)"
        }
        if percent < 0 {
            return "baixa -\(value)"
        }
        return "estável \(value)"
    }

    private static func makePriceFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        return formatter
    }

    private static func makePercentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .percent
        formatter.multiplier = 1
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = ""
        formatter.negativePrefix = ""
        return formatter
    }

    private static func userMessage(for error: Error) -> String {
        switch error as? APIError {
        case .noConnection:
            return "Sem conexão com a internet."
        case .rateLimited:
            return "Muitas requisições. Tente novamente em instantes."
        case .httpStatus, .decoding, .unknown, .none:
            return "Não foi possível carregar as cotações."
        }
    }
}
