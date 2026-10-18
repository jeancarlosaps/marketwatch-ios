import Foundation
import RxSwift
@testable import MarketWatch

/// Returns a canned result and records the requested URLs.
final class HTTPClientStub: HTTPClient {
    private let result: Result<Data, Error>
    private(set) var requestedURLs: [URL] = []

    init(_ result: Result<Data, Error>) {
        self.result = result
    }

    func get(_ url: URL) -> Single<Data> {
        requestedURLs.append(url)
        return Single.create { [result] observer in
            observer(result)
            return Disposables.create()
        }
    }
}

extension URL {
    func queryValue(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
