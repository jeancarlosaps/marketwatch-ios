import Foundation

/// A coin as returned by `/coins/markets`. Most market fields can be null in the API.
struct MarketCoin: Decodable, Equatable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let image: String?
    let currentPrice: Decimal?
    let priceChange24h: Decimal?
    let priceChangePercentage24h: Decimal?
    let high24h: Decimal?
    let low24h: Decimal?
    let marketCap: Decimal?
    let marketCapRank: Int?
    let totalVolume: Decimal?
    let lastUpdated: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case priceChange24h = "price_change_24h"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
        case totalVolume = "total_volume"
        case lastUpdated = "last_updated"
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    /// Price 24 hours ago (current price minus the 24h change).
    /// Crypto trades around the clock, so this is a reference value, not an official close.
    var referencePrice24h: Decimal? {
        guard let currentPrice, let priceChange24h else { return nil }
        return currentPrice - priceChange24h
    }
}
