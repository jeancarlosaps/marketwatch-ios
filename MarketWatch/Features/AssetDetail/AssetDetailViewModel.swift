import Foundation
import RxCocoa
import RxSwift

enum AssetDetailChart: Equatable {
    case prices([Decimal])
    case empty
    case unavailable
}

struct AssetDetailContent: Equatable {
    let name: String
    let symbol: String
    let imageURL: URL?
    let priceText: String
    let changePercent: Decimal?
    let referencePriceText: String
    let highText: String
    let lowText: String
    let marketCapText: String
    let chart: AssetDetailChart
    let chartAccessibilityLabel: String
    let accessibilityLabel: String
}

enum AssetDetailState: Equatable {
    case loading
    case content(AssetDetailContent)
    case error(String)
}

/// Loads one coin and its 7-day price series. UIKit-free.
final class AssetDetailViewModel {
    private let id: String
    private let service: CoinGeckoService
    private let stateRelay = BehaviorRelay<AssetDetailState>(value: .loading)
    private var loadDisposable: Disposable?
    private var chartDisposable: Disposable?
    private var generation = 0

    private let priceFormatter = AssetDetailFormatting.priceFormatter()
    private let dollarFormatter = AssetDetailFormatting.dollarFormatter()
    private let marketCapFormatter = AssetDetailFormatting.marketCapFormatter()

    var state: Driver<AssetDetailState> {
        stateRelay.asDriver()
    }

    var stateValues: Observable<AssetDetailState> {
        stateRelay.asObservable()
    }

    init(id: String, service: CoinGeckoService) {
        self.id = id
        self.service = service
    }

    func load() {
        chartDisposable?.dispose()
        loadDisposable?.dispose()
        generation += 1
        let requestGeneration = generation
        stateRelay.accept(.loading)

        let history = service.priceHistory(id: id)
            .map { Result<PriceHistory, Error>.success($0) }
            .catch { error in .just(.failure(error)) }

        loadDisposable = Single.zip(service.market(id: id), history)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] coin, historyResult in
                           self?.apply(coin: coin, history: historyResult, generation: requestGeneration)
                       },
                       onFailure: { [weak self] error in
                           guard let self, requestGeneration == self.generation else { return }
                           self.stateRelay.accept(.error(AssetDetailFormatting.message(for: error)))
                       })
    }

    func retry() {
        load()
    }

    func retryChart() {
        guard case let .content(content) = stateRelay.value, content.chart == .unavailable else { return }
        chartDisposable?.dispose()
        let requestGeneration = generation

        chartDisposable = service.priceHistory(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] history in
                    guard let self, requestGeneration == self.generation else { return }
                    guard case let .content(current) = self.stateRelay.value else { return }
                    let chart = AssetDetailFormatting.chart(from: history.points.map(\.price))
                    self.stateRelay.accept(.content(current.replacing(chart: chart)))
                },
                onFailure: { [weak self] _ in
                    guard let self, requestGeneration == self.generation else { return }
                    guard case let .content(current) = self.stateRelay.value else { return }
                    self.stateRelay.accept(.content(current.replacing(chart: .unavailable)))
                }
            )
    }

    private func apply(coin: MarketCoin?, history: Result<PriceHistory, Error>, generation: Int) {
        guard generation == self.generation else { return }
        guard let coin else {
            stateRelay.accept(.error(String(localized: "Não encontramos esse ativo.")))
            return
        }

        let chart: AssetDetailChart
        switch history {
        case let .success(series):
            chart = AssetDetailFormatting.chart(from: series.points.map(\.price))
        case .failure:
            chart = .unavailable
        }
        stateRelay.accept(.content(makeContent(from: coin, chart: chart)))
    }

    private func makeContent(from coin: MarketCoin, chart: AssetDetailChart) -> AssetDetailContent {
        let symbol = coin.symbol.uppercased()
        let priceText = AssetDetailFormatting.text(coin.currentPrice, formatter: priceFormatter)
        let referenceText = AssetDetailFormatting.referencePrice(coin.referencePrice24h,
                                                                 priceFormatter: priceFormatter,
                                                                 dollarFormatter: dollarFormatter)
        let change = coin.priceChangePercentage24h
        let chartLabel = AssetDetailFormatting.chartAccessibilityLabel(chart)
        let accessibilityLabel = String(localized: "\(coin.name), \(symbol), \(priceText). Preço há 24h \(referenceText). \(chartLabel)")

        return AssetDetailContent(name: coin.name, symbol: symbol, imageURL: coin.imageURL,
                                  priceText: priceText, changePercent: change, referencePriceText: referenceText,
                                  highText: AssetDetailFormatting.text(coin.high24h, formatter: priceFormatter),
                                  lowText: AssetDetailFormatting.text(coin.low24h, formatter: priceFormatter),
                                  marketCapText: AssetDetailFormatting.text(coin.marketCap, formatter: marketCapFormatter),
                                  chart: chart, chartAccessibilityLabel: chartLabel,
                                  accessibilityLabel: accessibilityLabel)
    }
}

private extension AssetDetailContent {
    func replacing(chart: AssetDetailChart) -> AssetDetailContent {
        let chartLabel = AssetDetailFormatting.chartAccessibilityLabel(chart)
        let accessibilityLabel = String(localized: "\(name), \(symbol), \(priceText). Preço há 24h \(referencePriceText). \(chartLabel)")
        return AssetDetailContent(name: name, symbol: symbol, imageURL: imageURL,
                                  priceText: priceText, changePercent: changePercent, referencePriceText: referencePriceText,
                                  highText: highText, lowText: lowText, marketCapText: marketCapText,
                                  chart: chart, chartAccessibilityLabel: chartLabel,
                                  accessibilityLabel: accessibilityLabel)
    }
}

enum AssetDetailFormatting {
    static func priceFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        return formatter
    }

    static func dollarFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    /// The 24h reference price is computed, so it can carry many decimals.
    /// From $1 up it shows two decimals; below $1 it keeps up to eight for low-priced coins.
    static func referencePrice(_ value: Decimal?, priceFormatter: NumberFormatter,
                               dollarFormatter: NumberFormatter) -> String {
        guard let value else { return "—" }
        let magnitude = value < 0 ? -value : value
        return text(value, formatter: magnitude >= 1 ? dollarFormatter : priceFormatter)
    }

    static func marketCapFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }

    static func text(_ value: Decimal?, formatter: NumberFormatter) -> String {
        guard let value else { return "—" }
        return formatter.string(from: value as NSDecimalNumber) ?? "—"
    }

    static func chart(from prices: [Decimal]) -> AssetDetailChart {
        prices.isEmpty ? .empty : .prices(prices)
    }

    static func chartAccessibilityLabel(_ chart: AssetDetailChart) -> String {
        switch chart {
        case .empty:
            return String(localized: "Gráfico de 7 dias sem dados")
        case .unavailable:
            return String(localized: "Gráfico de 7 dias indisponível")
        case let .prices(prices):
            guard let first = prices.first, let last = prices.last, prices.count > 1 else {
                return String(localized: "Gráfico de 7 dias com um ponto")
            }
            if last > first { return String(localized: "Gráfico de 7 dias, tendência de alta") }
            if last < first { return String(localized: "Gráfico de 7 dias, tendência de baixa") }
            return String(localized: "Gráfico de 7 dias, preço estável")
        }
    }

    static func message(for error: Error) -> String {
        switch error as? APIError {
        case .noConnection:
            return String(localized: "Sem conexão com a internet.")
        case .rateLimited:
            return String(localized: "Muitas requisições. Tente novamente em instantes.")
        case .httpStatus, .decoding, .unknown, .none:
            return String(localized: "Não foi possível carregar o ativo.")
        }
    }
}
