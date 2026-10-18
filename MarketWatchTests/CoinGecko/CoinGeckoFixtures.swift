import Foundation

/// Trimmed responses based on real CoinGecko payloads.
enum CoinGeckoFixtures {
    static let marketsPage1 = Data("""
    [
      {
        "id": "bitcoin",
        "symbol": "btc",
        "name": "Bitcoin",
        "image": "https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png",
        "current_price": 81476.12,
        "market_cap": 1637565382796,
        "market_cap_rank": 1,
        "total_volume": 14959625132,
        "high_24h": 81733,
        "low_24h": 80967,
        "price_change_24h": 381.87,
        "price_change_percentage_24h": 0.49985,
        "last_updated": "2026-10-17T18:48:47.000Z"
      },
      {
        "id": "shiba-inu",
        "symbol": "shib",
        "name": "Shiba Inu",
        "image": "https://coin-images.coingecko.com/coins/images/11939/large/shiba.png",
        "current_price": 0.00001234,
        "market_cap": 7270000000,
        "market_cap_rank": 20,
        "total_volume": 150000000,
        "high_24h": 0.00001301,
        "low_24h": 0.00001198,
        "price_change_24h": -0.00000056,
        "price_change_percentage_24h": -4.3412,
        "last_updated": "2026-10-17T18:48:30.000Z"
      }
    ]
    """.utf8)

    static let marketsPage2 = Data("""
    [
      {
        "id": "new-token",
        "symbol": "new",
        "name": "New Token",
        "image": null,
        "current_price": 0.1,
        "market_cap": null,
        "market_cap_rank": null,
        "total_volume": null,
        "high_24h": null,
        "low_24h": null,
        "price_change_24h": null,
        "price_change_percentage_24h": null,
        "last_updated": null
      }
    ]
    """.utf8)

    static let emptyList = Data("[]".utf8)

    static let priceHistory = Data("""
    {
      "prices": [
        [1792176600000, 81131.0002859423],
        [1792180200000, 80916.88],
        [1792183800000, 81041.41]
      ],
      "market_caps": [[1792176600000, 1630000000000]],
      "total_volumes": [[1792176600000, 15000000000]]
    }
    """.utf8)
}
