import Foundation
import Testing
@testable import MarketWatch

@Suite("Market list pagination")
struct MarketListPaginationTests {
    @Test("Pagination appends the next page")
    func paginationAppends() async {
        let client = ScriptedHTTPClient { url in
            switch url.queryValue("page") {
            case "1":
                return .success(MarketListTestData.fullPage(prefix: "a", count: 30))
            case "2":
                return .success(CoinGeckoFixtures.marketsPage2)
            default:
                return .success(CoinGeckoFixtures.emptyList)
            }
        }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        viewModel.loadNextPageIfNeeded(showingIndex: 28)
        let content = await collector.next { state in
            if case let .items(items) = state { return items.count > 30 }
            return false
        }

        guard case let .items(items) = content else {
            Issue.record("Expected appended items")
            return
        }
        #expect(items.count == 31)
        #expect(client.requestedCount == 2)
    }

    @Test("A short page ends pagination")
    func shortPageEndsPagination() async throws {
        let client = ScriptedHTTPClient { _ in .success(CoinGeckoFixtures.marketsPage1) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        _ = await collector.next(where: MarketListTestData.isSettled)

        viewModel.loadNextPageIfNeeded(showingIndex: 1)
        try await Task.sleep(nanoseconds: 80_000_000)
        #expect(client.requestedCount == 1)
    }

    @Test("Concurrent pagination requests are ignored while a fetch is in flight")
    func blocksConcurrentPagination() async {
        let gate = RequestGate()
        let client = ScriptedHTTPClient { url in
            await gate.waitIfNeeded()
            if url.queryValue("page") == "1" {
                return .success(MarketListTestData.fullPage(prefix: "p", count: 30))
            }
            return .success(CoinGeckoFixtures.marketsPage2)
        }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        await gate.arm()
        viewModel.loadInitial()
        await gate.waitUntilPending()
        await gate.resume()
        _ = await collector.next(where: MarketListTestData.isSettled)

        await gate.arm()
        viewModel.loadNextPageIfNeeded(showingIndex: 28)
        await gate.waitUntilPending()
        viewModel.loadNextPageIfNeeded(showingIndex: 29)
        viewModel.loadNextPageIfNeeded(showingIndex: 29)
        #expect(client.requestedCount == 2)
        await gate.resume()
        _ = await collector.next { state in
            if case let .items(items) = state { return items.count > 30 }
            return false
        }
        #expect(client.requestedCount == 2)
    }

    @Test("Pagination failure keeps previous items and allows retry")
    func paginationFailureAndRetry() async {
        let flags = RequestFlags()
        await flags.setFailPage2(true)
        let client = ScriptedHTTPClient { url in
            switch url.queryValue("page") {
            case "1":
                return .success(MarketListTestData.fullPage(prefix: "a", count: 30))
            case "2":
                if await flags.failPage2 {
                    return .failure(APIError.noConnection)
                }
                return .success(CoinGeckoFixtures.marketsPage2)
            default:
                return .success(CoinGeckoFixtures.emptyList)
            }
        }

        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let contentCollector = ContentCollector(viewModel.contentValues)
        let footerCollector = FooterCollector(viewModel.footerValues)

        viewModel.loadInitial()
        _ = await contentCollector.next(where: MarketListTestData.isSettled)

        viewModel.loadNextPageIfNeeded(showingIndex: 28)
        let footer = await footerCollector.next {
            if case .error = $0 { return true }
            return false
        }
        guard case .error = footer else {
            Issue.record("Expected footer error")
            return
        }

        guard case let .items(itemsAfterFailure) = contentCollector.latest() else {
            Issue.record("Expected items to remain after pagination failure")
            return
        }
        #expect(itemsAfterFailure.count == 30)

        await flags.setFailPage2(false)
        viewModel.retryPagination()
        let content = await contentCollector.next { state in
            if case let .items(items) = state { return items.count > 30 }
            return false
        }
        guard case let .items(items) = content else {
            Issue.record("Expected retry to append")
            return
        }
        #expect(items.count == 31)
    }
}
