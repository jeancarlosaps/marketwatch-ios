import Foundation
import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("Market list layout")
struct MarketListLayoutTests {
    @Test("Table extends under the navigation bar so the large title stays visible")
    func tableUnderlapsNavigationBar() throws {
        let client = ScriptedHTTPClient { _ in .success(MarketListTestData.fullPage(prefix: "a", count: 30)) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let controller = MarketListViewController(viewModel: viewModel, themeManager: ThemeManager()) { _, _ in }
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        navigation.view.layoutIfNeeded()

        let tableView = try #require(controller.view.subviews.compactMap { $0 as? UITableView }.first)

        #expect(tableView.frame.minY == 0)
        #expect(tableView.adjustedContentInset.top >= navigation.navigationBar.frame.maxY)
        window.isHidden = true
    }
}
