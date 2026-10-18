import Foundation
import Testing
@testable import MarketWatch

@Suite("CoinGecko service")
struct CoinGeckoServiceTests {
    @Test("First page requests page 1 with the default page size and decodes the coins")
    func firstPage() async throws {
        let client = HTTPClientStub(.success(CoinGeckoFixtures.marketsPage1))
        let service = CoinGeckoService(client: client)

        let coins = try await service.markets(page: 1).value

        #expect(coins.map(\.id) == ["bitcoin", "shiba-inu"])
        let url = try #require(client.requestedURLs.first)
        #expect(url.path == "/api/v3/coins/markets")
        #expect(url.queryValue("page") == "1")
        #expect(url.queryValue("per_page") == "30")
        #expect(url.queryValue("vs_currency") == "usd")
        #expect(url.queryValue("order") == "market_cap_desc")
    }

    @Test("Page and page size are forwarded as query parameters", arguments: [(2, 30), (3, 50), (10, 100)])
    func pagingParameters(page: Int, perPage: Int) async throws {
        let client = HTTPClientStub(.success(CoinGeckoFixtures.marketsPage2))
        let service = CoinGeckoService(client: client)

        let coins = try await service.markets(page: page, perPage: perPage).value

        #expect(coins.map(\.id) == ["new-token"])
        let url = try #require(client.requestedURLs.first)
        #expect(url.queryValue("page") == String(page))
        #expect(url.queryValue("per_page") == String(perPage))
    }

    @Test("An empty page decodes to an empty list")
    func emptyPage() async throws {
        let service = CoinGeckoService(client: HTTPClientStub(.success(CoinGeckoFixtures.emptyList)))

        let coins = try await service.markets(page: 99).value

        #expect(coins.isEmpty)
    }

    @Test("Detail requests the coin by id")
    func detailById() async throws {
        let client = HTTPClientStub(.success(CoinGeckoFixtures.marketsPage1))
        let service = CoinGeckoService(client: client)

        let coin = try await service.market(id: "bitcoin").value

        #expect(coin?.id == "bitcoin")
        let url = try #require(client.requestedURLs.first)
        #expect(url.path == "/api/v3/coins/markets")
        #expect(url.queryValue("ids") == "bitcoin")
        #expect(url.queryValue("vs_currency") == "usd")
    }

    @Test("Detail returns nil for an unknown id")
    func detailUnknownId() async throws {
        let service = CoinGeckoService(client: HTTPClientStub(.success(CoinGeckoFixtures.emptyList)))

        let coin = try await service.market(id: "unknown").value

        #expect(coin == nil)
    }

    @Test("Price history requests 7 days by default and decodes the price points")
    func priceHistory() async throws {
        let client = HTTPClientStub(.success(CoinGeckoFixtures.priceHistory))
        let service = CoinGeckoService(client: client)

        let history = try await service.priceHistory(id: "bitcoin").value

        #expect(history.points.count == 3)
        #expect(history.points.first?.date == Date(timeIntervalSince1970: 1_792_176_600))
        #expect(history.points.last?.price == Decimal(string: "81041.41"))
        let url = try #require(client.requestedURLs.first)
        #expect(url.path == "/api/v3/coins/bitcoin/market_chart")
        #expect(url.queryValue("days") == "7")
        #expect(url.queryValue("vs_currency") == "usd")
    }

    @Test("Malformed responses fail with a decoding error")
    func decodingFailure() async {
        let service = CoinGeckoService(client: HTTPClientStub(.success(Data("{\"unexpected\": true}".utf8))))

        await #expect(throws: APIError.decoding) {
            _ = try await service.markets(page: 1).value
        }
    }

    @Test("Client errors are forwarded unchanged", arguments: [
        APIError.rateLimited(retryAfter: 30),
        .httpStatus(500),
        .noConnection,
    ])
    func forwardsClientErrors(error: APIError) async {
        let service = CoinGeckoService(client: HTTPClientStub(.failure(error)))

        await #expect(throws: error) {
            _ = try await service.priceHistory(id: "bitcoin").value
        }
    }
}
