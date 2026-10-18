import Alamofire
import Foundation

/// Failures surfaced by the networking layer. Cancellation is not an error: a disposed request emits nothing.
enum APIError: Error, Equatable {
    case noConnection
    case rateLimited(retryAfter: TimeInterval?)
    case httpStatus(Int)
    case decoding
    case unknown
}

extension APIError {
    private static let connectionErrors: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .cannotConnectToHost,
        .cannotFindHost,
        .dnsLookupFailed,
    ]

    init(_ error: AFError, response: HTTPURLResponse?) {
        if let response, !(200 ..< 300).contains(response.statusCode) {
            self = response.statusCode == 429
                ? .rateLimited(retryAfter: Self.retryAfter(in: response))
                : .httpStatus(response.statusCode)
        } else if let urlError = error.underlyingError as? URLError, Self.connectionErrors.contains(urlError.code) {
            self = .noConnection
        } else {
            self = .unknown
        }
    }

    /// Reads `Retry-After` when expressed in seconds; the HTTP-date form is ignored.
    private static func retryAfter(in response: HTTPURLResponse) -> TimeInterval? {
        response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
    }
}
