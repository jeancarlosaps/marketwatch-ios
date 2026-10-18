import Foundation
import Testing
@testable import MarketWatch

@Suite("Market list view model")
struct MarketListViewModelTests {
    @Test("Initial load publishes the first page as items")
    func initialLoad() async {
        let client = ScriptedHTTPClient { url in
            #expect(url.queryValue("page") == "1")
            return .success(CoinGeckoFixtures.marketsPage1)
        }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        let content = await collector.next(where: MarketListTestData.isSettled)

        guard case let .items(items) = content else {
            Issue.record("Expected items, got \(String(describing: content))")
            return
        }
        #expect(items.count == 2)
        #expect(items[0].id == "bitcoin")
        #expect(items[0].symbol == "BTC")
        #expect(items[0].priceText.contains("$"))
        #expect(client.requestedCount == 1)
    }

    @Test("Local search filters loaded coins and blocks pagination")
    func searchFiltersAndBlocksPagination() async throws {
        let client = ScriptedHTTPClient { url in
            switch url.queryValue("page") {
            case "1":
                return .success(MarketListTestData.fullPage(prefix: "a", count: 30))
            default:
                return .success(CoinGeckoFixtures.marketsPage2)
            }
        }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        viewModel.updateSearchQuery("a-0")
        let filtered = await collector.next { state in
            if case let .items(items) = state { return items.count == 1 && items.first?.id == "a-0" }
            return false
        }
        guard case let .items(items) = filtered else {
            Issue.record("Expected filtered items")
            return
        }
        #expect(items.count == 1)

        let requestsBefore = client.requestedCount
        viewModel.loadNextPageIfNeeded(showingIndex: 0)
        try await Task.sleep(nanoseconds: 80_000_000)
        #expect(client.requestedCount == requestsBefore)

        viewModel.updateSearchQuery("")
        let restored = await collector.next { state in
            if case let .items(items) = state { return items.count == 30 }
            return false
        }
        guard case let .items(all) = restored else {
            Issue.record("Expected restored list")
            return
        }
        #expect(all.count == 30)
    }

    @Test("Search with no matches publishes searchEmpty")
    func searchEmptyState() async {
        let client = ScriptedHTTPClient { _ in .success(CoinGeckoFixtures.marketsPage1) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        viewModel.updateSearchQuery("xyz-inexistente")
        let state = await collector.next {
            if case .searchEmpty = $0 { return true }
            return false
        }
        #expect(state == .searchEmpty)
    }

    @Test("Search with an empty loaded list stays empty, not searchEmpty")
    func searchWithEmptyLoadedListStaysEmpty() async throws {
        let client = ScriptedHTTPClient { _ in .success(CoinGeckoFixtures.emptyList) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        let empty = await collector.next(where: MarketListTestData.isSettled)
        #expect(empty == .empty)

        viewModel.updateSearchQuery("bitcoin")
        try await Task.sleep(nanoseconds: 40_000_000)
        #expect(collector.latest() == .empty)
    }

    @Test("Refresh replaces the list instead of appending")
    func refreshReplaces() async {
        let flags = RequestFlags()
        let client = ScriptedHTTPClient { url in
            switch url.queryValue("page") {
            case "1":
                let count = await flags.incrementPage1()
                if count == 1 {
                    return .success(MarketListTestData.fullPage(prefix: "a", count: 30))
                }
                return .success(CoinGeckoFixtures.marketsPage1)
            default:
                return .success(CoinGeckoFixtures.emptyList)
            }
        }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        viewModel.refresh()
        let content = await collector.next { state in
            if case let .items(items) = state {
                return items.count == 2 && items.first?.id == "bitcoin"
            }
            return false
        }
        guard case let .items(items) = content else {
            Issue.record("Expected refreshed items")
            return
        }
        #expect(items.map(\.id) == ["bitcoin", "shiba-inu"])
    }

    @Test("Stale responses after refresh are ignored")
    func ignoresStaleResponseAfterRefresh() async throws {
        let gate = RequestGate()
        let flags = RequestFlags()
        let client = ScriptedHTTPClient { url in
            switch url.queryValue("page") {
            case "1":
                let count = await flags.incrementPage1()
                if count == 1 {
                    return .success(MarketListTestData.fullPage(prefix: "old", count: 30))
                }
                await gate.waitIfNeeded()
                return .success(CoinGeckoFixtures.marketsPage1)
            case "2":
                await gate.waitIfNeeded()
                return .success(MarketListTestData.fullPage(prefix: "stale", count: 30))
            default:
                return .success(CoinGeckoFixtures.emptyList)
            }
        }

        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        await gate.arm()
        viewModel.loadNextPageIfNeeded(showingIndex: 28)
        await gate.waitUntilPending()

        viewModel.refresh()
        await gate.waitUntilPending(count: 2)
        await gate.resume()

        let content = await collector.next { state in
            if case let .items(items) = state {
                return items.count == 2 && items.first?.id == "bitcoin"
            }
            return false
        }
        guard case let .items(items) = content else {
            Issue.record("Expected refreshed bitcoin list")
            return
        }
        #expect(items.map(\.id) == ["bitcoin", "shiba-inu"])
        try await Task.sleep(nanoseconds: 100_000_000)

        guard case let .items(finalItems) = collector.latest() else {
            Issue.record("Expected final items")
            return
        }
        #expect(finalItems.map(\.id) == ["bitcoin", "shiba-inu"])
        #expect(!finalItems.contains(where: { $0.id.hasPrefix("stale") }))
    }

    @Test("Initial failure publishes an error state")
    func initialError() async {
        let client = ScriptedHTTPClient { _ in .failure(APIError.noConnection) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        let content = await collector.next {
            if case .error = $0 { return true }
            return false
        }
        guard case let .error(message) = content else {
            Issue.record("Expected error")
            return
        }
        #expect(message.contains("conexão"))
    }
}
