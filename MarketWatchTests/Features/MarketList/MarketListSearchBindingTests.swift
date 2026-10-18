import Foundation
import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("Market list search binding", .serialized, .timeLimit(.minutes(1)))
struct MarketListSearchBindingTests {
    @MainActor
    private struct Screen {
        let controller: MarketListViewController
        let viewModel: MarketListViewModel

        var searchBar: UISearchBar {
            controller.navigationItem.searchController!.searchBar
        }
    }

    private func makeScreen(handler: @escaping @Sendable (URL) async -> Result<Data, Error>) -> Screen {
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: ScriptedHTTPClient(handler: handler)), perPage: 30)
        let controller = MarketListViewController(viewModel: viewModel) { _, _ in }
        controller.loadViewIfNeeded()
        return Screen(controller: controller, viewModel: viewModel)
    }

    private func type(_ text: String, in searchBar: UISearchBar) {
        searchBar.text = text
        searchBar.delegate?.searchBar?(searchBar, textDidChange: text)
    }

    @Test("Typing in the search bar filters the loaded coins after the debounce")
    func typingFilters() async {
        let screen = makeScreen { _ in
            .success(MarketListTestData.fullPage(prefix: "a", count: 30))
        }
        let collector = ContentCollector(screen.viewModel.contentValues)
        _ = await collector.next(where: MarketListTestData.isSettled)

        type("a-1", in: screen.searchBar)
        let filtered = await collector.next { state in
            if case let .items(items) = state { return items.count < 30 }
            return false
        }

        guard case let .items(items) = filtered else {
            Issue.record("Expected filtered items")
            return
        }
        // "a-1" matches a-1 and a-10 ... a-19.
        #expect(items.count == 11)
        #expect(items.allSatisfy { $0.id.hasPrefix("a-1") })
        withExtendedLifetime(screen) {}
    }

    @Test("Clearing the search when editing ends restores the full list")
    func cancelRestoresList() async {
        let screen = makeScreen { _ in
            .success(MarketListTestData.fullPage(prefix: "a", count: 30))
        }
        let collector = ContentCollector(screen.viewModel.contentValues)
        _ = await collector.next(where: MarketListTestData.isSettled)
        type("a-2", in: screen.searchBar)
        _ = await collector.next { state in
            if case let .items(items) = state { return items.count < 30 }
            return false
        }

        screen.searchBar.text = ""
        screen.searchBar.delegate?.searchBarTextDidEndEditing?(screen.searchBar)
        let restored = await collector.next { state in
            if case let .items(items) = state { return items.count == 30 }
            return false
        }

        guard case let .items(items) = restored else {
            Issue.record("Expected the full list")
            return
        }
        #expect(items.count == 30)
        withExtendedLifetime(screen) {}
    }

    @Test("The search bar's initial value does not replace the loading state")
    func initialValueKeepsLoading() async throws {
        let screen = makeScreen { _ in
            try? await Task.sleep(for: .seconds(30))
            return .success(CoinGeckoFixtures.emptyList)
        }
        let collector = ContentCollector(screen.viewModel.contentValues)

        // Longer than the 300 ms search debounce.
        try await Task.sleep(for: .milliseconds(700))

        #expect(collector.latest() == .loading)
        withExtendedLifetime(screen) {}
    }
}
