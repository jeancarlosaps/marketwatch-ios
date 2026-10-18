import Foundation
import RxSwift

/// CoinGecko operations used by the app. Stateless: callers own paging state.
final class CoinGeckoService {
    static let defaultPerPage = 30
    static let defaultHistoryDays = 7

    private let client: HTTPClient
    private let decoder: JSONDecoder

    init(client: HTTPClient, decoder: JSONDecoder = CoinGeckoService.makeDecoder()) {
        self.client = client
        self.decoder = decoder
    }

    /// One page of coins ordered by market cap. Pages start at 1; an empty array means there are no more pages.
    func markets(page: Int, perPage: Int = CoinGeckoService.defaultPerPage) -> Single<[MarketCoin]> {
        request(.markets(page: page, perPage: perPage))
    }

    /// The coin with the given CoinGecko id, or `nil` when the id is unknown.
    func market(id: String) -> Single<MarketCoin?> {
        request(.market(id: id)).map { (coins: [MarketCoin]) in coins.first }
    }

    func priceHistory(id: String, days: Int = CoinGeckoService.defaultHistoryDays) -> Single<PriceHistory> {
        request(.priceHistory(id: id, days: days))
    }

    private func request<Response: Decodable>(_ endpoint: CoinGeckoEndpoint) -> Single<Response> {
        client.get(endpoint.url).map { [decoder] data in
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decoding
            }
        }
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            // CoinGecko sends ISO 8601 timestamps with milliseconds, e.g. 2026-10-17T18:48:47.000Z.
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return decoder
    }
}
