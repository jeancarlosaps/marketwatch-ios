import Alamofire
import Foundation
import RxSwift
import Testing
@testable import MarketWatch

/// Serves canned responses to Alamofire without touching the network.
final class URLProtocolStub: URLProtocol {
    enum Reply {
        case response(status: Int, headers: [String: String], body: Data)
        case failure(URLError.Code)
        case never
    }

    nonisolated(unsafe) static var reply: Reply = .never
    nonisolated(unsafe) static var stoppedLoading = false

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        switch Self.reply {
        case let .response(status, headers, body):
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case .never:
            break
        }
    }

    override func stopLoading() {
        Self.stoppedLoading = true
    }
}

@Suite("Alamofire HTTP client", .serialized)
struct AlamofireHTTPClientTests {
    private let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets")!

    private func makeClient(_ reply: URLProtocolStub.Reply) -> AlamofireHTTPClient {
        URLProtocolStub.reply = reply
        URLProtocolStub.stoppedLoading = false
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return AlamofireHTTPClient(session: Session(configuration: configuration))
    }

    @Test("A 2xx response returns the body")
    func success() async throws {
        let client = makeClient(.response(status: 200, headers: [:], body: Data("[]".utf8)))

        let data = try await client.get(url).value

        #expect(data == Data("[]".utf8))
    }

    @Test("Non-2xx responses map to httpStatus", arguments: [404, 500, 503])
    func httpStatus(status: Int) async {
        let client = makeClient(.response(status: status, headers: [:], body: Data()))

        await #expect(throws: APIError.httpStatus(status)) {
            _ = try await client.get(url).value
        }
    }

    @Test("429 maps to rateLimited and reads Retry-After in seconds")
    func rateLimitedWithRetryAfter() async {
        let client = makeClient(.response(status: 429, headers: ["Retry-After": "30"], body: Data()))

        await #expect(throws: APIError.rateLimited(retryAfter: 30)) {
            _ = try await client.get(url).value
        }
    }

    @Test("429 without Retry-After maps to rateLimited with no delay")
    func rateLimitedWithoutRetryAfter() async {
        let client = makeClient(.response(status: 429, headers: [:], body: Data()))

        await #expect(throws: APIError.rateLimited(retryAfter: nil)) {
            _ = try await client.get(url).value
        }
    }

    @Test("Connection failures map to noConnection", arguments: [
        URLError.Code.notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
    ])
    func noConnection(code: URLError.Code) async {
        let client = makeClient(.failure(code))

        await #expect(throws: APIError.noConnection) {
            _ = try await client.get(url).value
        }
    }

    @Test("Disposing the subscription cancels the request without emitting")
    func cancellation() async throws {
        let client = makeClient(.never)
        var emitted = false

        let disposable = client.get(url).subscribe { _ in emitted = true }
        try await Task.sleep(for: .milliseconds(200))
        disposable.dispose()

        for _ in 0 ..< 20 where !URLProtocolStub.stoppedLoading {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(URLProtocolStub.stoppedLoading)
        #expect(!emitted)
    }
}
