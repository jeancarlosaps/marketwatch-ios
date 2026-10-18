import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("Market coin cell")
struct MarketCoinCellTests {
    @Test("Variation badge keeps a finite corner radius relative to its height")
    func badgeCornerRadiusFitsHeight() throws {
        let badge = VariationBadgeView()
        try badge.configure(percent: #require(Decimal(string: "3.45")))
        badge.layoutIfNeeded()

        let size = badge.intrinsicContentSize
        #expect(size.height > 16)
        #expect(badge.layer.cornerRadius <= size.height / 2 + 0.5)
        #expect(badge.layer.cornerRadius > 0)
    }

    @Test("Variation badge keeps a visible size inside the price stack")
    func badgeKeepsVisibleSizeInsidePriceStack() throws {
        let badge = VariationBadgeView()
        try badge.configure(percent: #require(Decimal(string: "3.45")))

        let priceLabel = UILabel()
        priceLabel.text = "$81,025.00"
        priceLabel.font = MWFont.percent()

        let priceStack = UIStackView(arrangedSubviews: [priceLabel, badge])
        priceStack.axis = .vertical
        priceStack.alignment = .trailing
        priceStack.translatesAutoresizingMaskIntoConstraints = false

        let host = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        host.addSubview(priceStack)
        NSLayoutConstraint.activate([
            priceStack.topAnchor.constraint(equalTo: host.topAnchor, constant: 8),
            priceStack.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -8),
        ])
        host.setNeedsLayout()
        host.layoutIfNeeded()

        #expect(badge.isHidden == false)
        #expect(badge.bounds.height > 16, "bounds=\(badge.bounds) intrinsic=\(badge.intrinsicContentSize)")
        #expect(badge.bounds.width > 40, "bounds=\(badge.bounds)")
    }

    @Test("Configured cell shows the badge when change percent is present")
    func configureShowsBadgeForChangePercent() throws {
        let item = try MarketListItem(
            id: "bitcoin",
            name: "Bitcoin",
            symbol: "BTC",
            imageURL: nil,
            priceText: "$81,025.00",
            changePercent: #require(Decimal(string: "-1.15")),
            accessibilityLabel: "Bitcoin"
        )

        let cell = MarketCoinCell(style: .default, reuseIdentifier: MarketCoinCell.reuseIdentifier)
        cell.prepareForReuse()
        cell.configure(with: item)

        let fitting = cell.systemLayoutSizeFitting(
            CGSize(width: 390, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        cell.bounds = CGRect(x: 0, y: 0, width: 390, height: fitting.height)
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()

        let badge = try #require(firstVariationBadge(in: cell.contentView))
        #expect(badge.isHidden == false)
        #expect(visibleText(in: badge) == "-1,15%")
        #expect(badge.intrinsicContentSize.height > 16)
        #expect(badge.layer.cornerRadius <= badge.intrinsicContentSize.height / 2 + 0.5)
        #expect(fitting.height >= 64)
    }

    @Test("ViewModel maps 24h change into cells that keep a visible badge")
    func viewModelItemsRenderVisibleBadges() async throws {
        let client = ScriptedHTTPClient { _ in .success(CoinGeckoFixtures.marketsPage1) }
        let viewModel = MarketListViewModel(service: CoinGeckoService(client: client), perPage: 30)
        let collector = ContentCollector(viewModel.contentValues)

        viewModel.loadInitial()
        let content = await collector.next(where: MarketListTestData.isSettled)
        guard case let .items(items) = content else {
            Issue.record("Expected items")
            return
        }
        #expect(items[0].changePercent != nil)

        let cell = MarketCoinCell(style: .default, reuseIdentifier: MarketCoinCell.reuseIdentifier)
        cell.prepareForReuse()
        cell.configure(with: items[0])
        let fitting = cell.systemLayoutSizeFitting(
            CGSize(width: 390, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        cell.bounds = CGRect(x: 0, y: 0, width: 390, height: max(fitting.height, 88))
        cell.layoutIfNeeded()

        let badge = try #require(firstVariationBadge(in: cell.contentView))
        #expect(badge.isHidden == false)
        #expect(badge.intrinsicContentSize.height > 16)
        #expect(badge.layer.cornerRadius <= badge.intrinsicContentSize.height / 2 + 0.5)
        #expect(visibleText(in: badge) != nil)
    }
}

private func firstVariationBadge(in view: UIView) -> VariationBadgeView? {
    if let badge = view as? VariationBadgeView {
        return badge
    }
    for subview in view.subviews {
        if let badge = firstVariationBadge(in: subview) {
            return badge
        }
    }
    return nil
}

private func visibleText(in view: UIView) -> String? {
    if let label = view as? UILabel {
        return label.text
    }
    for subview in view.subviews {
        if let text = visibleText(in: subview) {
            return text
        }
    }
    return nil
}
