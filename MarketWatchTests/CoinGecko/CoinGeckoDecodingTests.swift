import Foundation
import Testing
@testable import MarketWatch

@Suite("CoinGecko decoding")
struct CoinGeckoDecodingTests {
    private let decoder = CoinGeckoService.makeDecoder()

    @Test("Prices decode as exact decimals, including fractional and very small values", arguments: [
        ("81476.12", "81476.12"),
        ("0.00001234", "0.00001234"),
        ("0.1", "0.1"),
        ("-0.00000056", "-0.00000056"),
    ])
    func exactDecimals(json: String, expected: String) throws {
        let data = Data("""
        [{"id": "x", "symbol": "x", "name": "X", "current_price": \(json)}]
        """.utf8)

        let coin = try #require(try decoder.decode([MarketCoin].self, from: data).first)

        #expect(coin.currentPrice == Decimal(string: expected))
    }

    @Test("Reference price is the current price minus the 24h change")
    func referencePrice() throws {
        let coins = try decoder.decode([MarketCoin].self, from: CoinGeckoFixtures.marketsPage1)

        #expect(coins[0].referencePrice24h == Decimal(string: "81094.25"))
        #expect(coins[1].referencePrice24h == Decimal(string: "0.0000129"))
    }

    @Test("Null market fields decode as nil")
    func nullFields() throws {
        let coin = try #require(try decoder.decode([MarketCoin].self, from: CoinGeckoFixtures.marketsPage2).first)

        #expect(coin.imageURL == nil)
        #expect(coin.marketCapRank == nil)
        #expect(coin.priceChangePercentage24h == nil)
        #expect(coin.lastUpdated == nil)
        #expect(coin.referencePrice24h == nil)
    }

    @Test("Timestamps with milliseconds and image URLs decode")
    func datesAndImages() throws {
        let coin = try #require(try decoder.decode([MarketCoin].self, from: CoinGeckoFixtures.marketsPage1).first)

        #expect(coin.lastUpdated == Date(timeIntervalSince1970: 1_792_262_927))
        #expect(coin.imageURL?.host == "coin-images.coingecko.com")
        #expect(coin.high24h == 81733)
        #expect(coin.marketCapRank == 1)
    }
}
