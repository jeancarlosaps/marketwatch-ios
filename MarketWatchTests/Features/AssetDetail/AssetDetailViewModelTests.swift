import Foundation
import RxSwift
import Testing
@testable import MarketWatch

@Suite("Asset detail")
struct AssetDetailViewModelTests {
    @Test("Loads the coin, the reference price and the 7-day series")
    func loadDetailAndHistory() async {
        let client = ScriptedHTTPClient { url in
            url.path.contains("market_chart")
                ? .success(CoinGeckoFixtures.priceHistory)
                : .success(CoinGeckoFixtures.marketsPage1)
        }
        let viewModel = AssetDetailViewModel(id: "bitcoin", service: CoinGeckoService(client: client))
        let collector = DetailCollector(viewModel.stateValues)

        viewModel.load()
        let state = await collector.next(where: isSettled)

        guard case let .content(content) = state else {
            Issue.record("Expected content, got \(state)")
            return
        }
        #expect(content.name == "Bitcoin")
        #expect(content.symbol == "BTC")
        #expect(content.priceText == "$81,476.12")
        #expect(content.referencePriceText == "$81,094.25")
        #expect(content.highText == "$81,733.00")
        #expect(content.lowText == "$80,967.00")
        #expect(content.marketCapText == "$1,637,565,382,796")
        #expect(content.changePercent == Decimal(string: "0.49985"))
        guard case let .prices(prices) = content.chart else {
            Issue.record("Expected prices")
            return
        }
        #expect(prices.count == 3)
        #expect(content.chartAccessibilityLabel == "Gráfico de 7 dias, tendência de baixa")
        #expect(client.requestedCount == 2)
    }

    @Test("Initial failure can be retried")
    func errorThenRetry() async {
        let marketAttempts = AttemptCounter()
        let client = ScriptedHTTPClient { url in
            if url.path.contains("market_chart") {
                return .success(CoinGeckoFixtures.priceHistory)
            }
            return marketAttempts.next() == 1
                ? .failure(APIError.noConnection)
                : .success(CoinGeckoFixtures.marketsPage1)
        }
        let viewModel = AssetDetailViewModel(id: "bitcoin", service: CoinGeckoService(client: client))
        let collector = DetailCollector(viewModel.stateValues)

        viewModel.load()
        let failed = await collector.next { state in
            if case .error = state { return true }
            return false
        }
        #expect(failed == .error("Sem conexão com a internet."))

        viewModel.retry()
        let recovered = await collector.next { state in
            if case .content = state { return true }
            return false
        }
        guard case .content = recovered else {
            Issue.record("Expected content after retry")
            return
        }
    }

    @Test("A failed chart keeps the coin and can be reloaded")
    func partialChartFailure() async {
        let chartAttempts = AttemptCounter()
        let client = ScriptedHTTPClient { url in
            guard url.path.contains("market_chart") else {
                return .success(CoinGeckoFixtures.marketsPage1)
            }
            if chartAttempts.next() == 1 {
                return .failure(APIError.httpStatus(500))
            }
            return .success(CoinGeckoFixtures.priceHistory)
        }
        let viewModel = AssetDetailViewModel(id: "bitcoin", service: CoinGeckoService(client: client))
        let collector = DetailCollector(viewModel.stateValues)

        viewModel.load()
        let partial = await collector.next { state in
            if case let .content(content) = state, content.chart == .unavailable { return true }
            return false
        }
        guard case let .content(content) = partial else {
            Issue.record("Expected partial content")
            return
        }
        #expect(content.priceText == "$81,476.12")
        #expect(content.referencePriceText == "$81,094.25")

        viewModel.retryChart()
        let restored = await collector.next { state in
            if case let .content(content) = state, content.chart != .unavailable { return true }
            return false
        }
        guard case let .content(restoredContent) = restored, case let .prices(prices) = restoredContent.chart else {
            Issue.record("Expected chart prices after retry")
            return
        }
        #expect(prices.count == 3)
    }

    @Test("Empty, single-point and flat histories stay presentable")
    func historyEdges() async {
        let empty = await chartState(history: #"{"prices":[]}"#)
        #expect(empty == .empty)

        let single = await chartState(history: #"{"prices":[[1792176600000, 100]]}"#)
        #expect(single == .prices([100]))

        let flat = await chartState(history: #"{"prices":[[1, 50],[2, 50]]}"#)
        #expect(flat == .prices([50, 50]))
    }

    private func chartState(history: String) async -> AssetDetailChart? {
        let client = ScriptedHTTPClient { url in
            url.path.contains("market_chart")
                ? .success(Data(history.utf8))
                : .success(CoinGeckoFixtures.marketsPage1)
        }
        let viewModel = AssetDetailViewModel(id: "bitcoin", service: CoinGeckoService(client: client))
        let collector = DetailCollector(viewModel.stateValues)
        viewModel.load()
        let state = await collector.next(where: isSettled)
        guard case let .content(content) = state else { return nil }
        return content.chart
    }

    @Test("Reference price uses two decimals from $1 up and keeps precision below $1", arguments: [
        ("81568.56937603", "$81,568.57"),
        ("81094.25", "$81,094.25"),
        ("1", "$1.00"),
        ("0.99934123", "$0.99934123"),
        ("0.0000129", "$0.0000129"),
    ])
    func referencePriceFormatting(value: String, expected: String) throws {
        let price = try #require(Decimal(string: value))

        let text = AssetDetailFormatting.referencePrice(
            price,
            priceFormatter: AssetDetailFormatting.priceFormatter(),
            dollarFormatter: AssetDetailFormatting.dollarFormatter()
        )

        #expect(text == expected)
    }

    @Test("Missing reference price shows a dash")
    func missingReferencePrice() {
        let text = AssetDetailFormatting.referencePrice(
            nil,
            priceFormatter: AssetDetailFormatting.priceFormatter(),
            dollarFormatter: AssetDetailFormatting.dollarFormatter()
        )

        #expect(text == "—")
    }
}

private func isSettled(_ state: AssetDetailState) -> Bool {
    switch state {
    case .loading:
        false
    case .content, .error:
        true
    }
}

private final class AttemptCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
}

private final class DetailCollector {
    private let lock = NSLock()
    private var latest: AssetDetailState?
    private var waiters: [((AssetDetailState) -> Bool, CheckedContinuation<AssetDetailState, Never>)] = []
    private var disposable: Disposable?

    init(_ source: Observable<AssetDetailState>) {
        disposable = source.subscribe(onNext: { [weak self] value in
            self?.handle(value)
        })
    }

    deinit {
        disposable?.dispose()
    }

    func next(where predicate: @escaping (AssetDetailState) -> Bool) async -> AssetDetailState {
        await withCheckedContinuation { continuation in
            lock.lock()
            if let latest, predicate(latest) {
                lock.unlock()
                continuation.resume(returning: latest)
                return
            }
            waiters.append((predicate, continuation))
            lock.unlock()
        }
    }

    private func handle(_ value: AssetDetailState) {
        lock.lock()
        latest = value
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        var remaining: [((AssetDetailState) -> Bool, CheckedContinuation<AssetDetailState, Never>)] = []
        for (predicate, continuation) in pending {
            if predicate(value) {
                continuation.resume(returning: value)
            } else {
                remaining.append((predicate, continuation))
            }
        }
        if !remaining.isEmpty {
            lock.lock()
            waiters.insert(contentsOf: remaining, at: 0)
            lock.unlock()
        }
    }
}
