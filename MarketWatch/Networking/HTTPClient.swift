import Alamofire
import Foundation
import RxSwift

/// Performs HTTP GET requests. Knows nothing about the API being called.
protocol HTTPClient {
    func get(_ url: URL) -> Single<Data>
}

/// `HTTPClient` backed by Alamofire. Disposing the subscription cancels the request.
final class AlamofireHTTPClient: HTTPClient {
    private let session: Session
    private let responseQueue: DispatchQueue

    init(session: Session = .default, responseQueue: DispatchQueue = .global(qos: .userInitiated)) {
        self.session = session
        self.responseQueue = responseQueue
    }

    func get(_ url: URL) -> Single<Data> {
        Single.create { [session, responseQueue] observer in
            let request = session.request(url)
                .validate(statusCode: 200 ..< 300)
                .responseData(queue: responseQueue) { response in
                    switch response.result {
                    case let .success(data):
                        observer(.success(data))
                    case let .failure(error):
                        guard !error.isExplicitlyCancelledError else { return }
                        observer(.failure(APIError(error, response: response.response)))
                    }
                }
            return Disposables.create { request.cancel() }
        }
    }
}
