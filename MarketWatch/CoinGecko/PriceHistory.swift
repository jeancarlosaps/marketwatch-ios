import Foundation

/// Price series from `/coins/{id}/market_chart`. Only `prices` is used.
struct PriceHistory: Decodable, Equatable {
    struct Point: Equatable {
        let date: Date
        let price: Decimal
    }

    let points: [Point]

    private enum CodingKeys: String, CodingKey {
        case prices
    }

    init(points: [Point]) {
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var prices = try container.nestedUnkeyedContainer(forKey: .prices)
        var points: [Point] = []
        while !prices.isAtEnd {
            // Each entry is a `[timestamp in milliseconds, price]` pair.
            var pair = try prices.nestedUnkeyedContainer()
            let milliseconds = try pair.decode(Double.self)
            let price = try pair.decode(Decimal.self)
            points.append(Point(date: Date(timeIntervalSince1970: milliseconds / 1000), price: price))
        }
        self.points = points
    }
}
