import Testing
import UIKit
@testable import MarketWatch

@Suite("Price chart layout")
struct PriceChartLayoutTests {
    private let plot = CGRect(x: 0, y: 0, width: 100, height: 50)

    @Test("Empty history produces no points")
    func emptyHistory() {
        #expect(PriceChartLayout.points(prices: [], in: plot).isEmpty)
    }

    @Test("A single price stays centered")
    func singlePoint() throws {
        let points = PriceChartLayout.points(prices: [100], in: plot)
        let point = try #require(points.first)
        #expect(points.count == 1)
        #expect(point.x == plot.midX)
        #expect(point.y == plot.midY)
    }

    @Test("Equal prices stay on the midline without dividing by zero")
    func equalPrices() {
        let points = PriceChartLayout.points(prices: [40, 40, 40], in: plot)
        #expect(points.count == 3)
        #expect(points.allSatisfy { $0.y == plot.midY })
        #expect(points.first?.x == plot.minX)
        #expect(points.last?.x == plot.maxX)
    }

    @Test("Prices scale from the bottom of the plot to the top")
    func proportionalScale() throws {
        let points = PriceChartLayout.points(prices: [10, 20], in: plot)
        let first = try #require(points.first)
        let last = try #require(points.last)
        #expect(first.y == plot.maxY)
        #expect(last.y == plot.minY)
        #expect(first.x == plot.minX)
        #expect(last.x == plot.maxX)
    }
}
