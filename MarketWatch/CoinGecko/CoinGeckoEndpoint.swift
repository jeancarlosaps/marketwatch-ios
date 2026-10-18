import Foundation

/// CoinGecko public API routes used by the app. Prices are always quoted in USD.
enum CoinGeckoEndpoint: Equatable {
    case markets(page: Int, perPage: Int)
    case market(id: String)
    case priceHistory(id: String, days: Int)

    static let baseURL = URL(string: "https://api.coingecko.com/api/v3")!
    static let currency = "usd"

    var url: URL {
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems
        return components.url!
    }

    private var path: String {
        switch self {
        case .markets, .market:
            "coins/markets"
        case let .priceHistory(id, _):
            "coins/\(id)/market_chart"
        }
    }

    private var queryItems: [URLQueryItem] {
        let currency = URLQueryItem(name: "vs_currency", value: Self.currency)
        switch self {
        case let .markets(page, perPage):
            return [
                currency,
                URLQueryItem(name: "order", value: "market_cap_desc"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page)),
            ]
        case let .market(id):
            return [currency, URLQueryItem(name: "ids", value: id)]
        case let .priceHistory(_, days):
            return [currency, URLQueryItem(name: "days", value: String(days))]
        }
    }
}
