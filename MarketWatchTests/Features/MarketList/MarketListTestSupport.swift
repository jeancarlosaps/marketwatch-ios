import Foundation
import RxSwift
@testable import MarketWatch

enum MarketListTestData {
    static func isSettled(_ state: MarketListContentState) -> Bool {
        switch state {
        case .loading:
            false
        case .items, .empty, .searchEmpty, .error:
            true
        }
    }

    static func fullPage(prefix: String, count: Int) -> Data {
        let coins = (0 ..< count).map { index in
            """
            {
              "id": "\(prefix)-\(index)",
              "symbol": "\(prefix)\(index)",
              "name": "Coin \(prefix)-\(index)",
              "image": null,
              "current_price": 1.5,
              "market_cap": 1000,
              "market_cap_rank": \(index + 1),
              "total_volume": 10,
              "high_24h": 2,
              "low_24h": 1,
              "price_change_24h": 0.1,
              "price_change_percentage_24h": 1.5,
              "last_updated": "2026-10-17T18:48:47.000Z"
            }
            """
        }.joined(separator: ",")
        return Data("[\(coins)]".utf8)
    }
}

final class ContentCollector {
    private let lock = NSLock()
    private var latestValue: MarketListContentState?
    private var waiters: [(MarketListContentState) -> Bool] = []
    private var continuations: [CheckedContinuation<MarketListContentState, Never>] = []
    private var disposable: Disposable?

    init(_ source: Observable<MarketListContentState>) {
        disposable = source.subscribe(onNext: { [weak self] value in
            self?.handle(value)
        })
    }

    deinit {
        disposable?.dispose()
    }

    func next(where predicate: @escaping (MarketListContentState) -> Bool) async -> MarketListContentState {
        if let latestValue, predicate(latestValue) {
            return latestValue
        }
        return await withCheckedContinuation { continuation in
            lock.lock()
            if let latestValue, predicate(latestValue) {
                lock.unlock()
                continuation.resume(returning: latestValue)
                return
            }
            waiters.append(predicate)
            continuations.append(continuation)
            lock.unlock()
        }
    }

    func latest() -> MarketListContentState? {
        lock.lock()
        defer { lock.unlock() }
        return latestValue
    }

    private func handle(_ value: MarketListContentState) {
        lock.lock()
        latestValue = value
        var matchedIndexes: [Int] = []
        for (index, predicate) in waiters.enumerated() where predicate(value) {
            matchedIndexes.append(index)
        }
        for index in matchedIndexes.reversed() {
            waiters.remove(at: index)
            let continuation = continuations.remove(at: index)
            continuation.resume(returning: value)
        }
        lock.unlock()
    }
}

final class FooterCollector {
    private let lock = NSLock()
    private var latestValue: MarketListFooterState?
    private var waiters: [(MarketListFooterState) -> Bool] = []
    private var continuations: [CheckedContinuation<MarketListFooterState, Never>] = []
    private var disposable: Disposable?

    init(_ source: Observable<MarketListFooterState>) {
        disposable = source.subscribe(onNext: { [weak self] value in
            self?.handle(value)
        })
    }

    deinit {
        disposable?.dispose()
    }

    func next(where predicate: @escaping (MarketListFooterState) -> Bool) async -> MarketListFooterState {
        if let latestValue, predicate(latestValue) {
            return latestValue
        }
        return await withCheckedContinuation { continuation in
            lock.lock()
            if let latestValue, predicate(latestValue) {
                lock.unlock()
                continuation.resume(returning: latestValue)
                return
            }
            waiters.append(predicate)
            continuations.append(continuation)
            lock.unlock()
        }
    }

    private func handle(_ value: MarketListFooterState) {
        lock.lock()
        latestValue = value
        var matchedIndexes: [Int] = []
        for (index, predicate) in waiters.enumerated() where predicate(value) {
            matchedIndexes.append(index)
        }
        for index in matchedIndexes.reversed() {
            waiters.remove(at: index)
            let continuation = continuations.remove(at: index)
            continuation.resume(returning: value)
        }
        lock.unlock()
    }
}

final class ScriptedHTTPClient: HTTPClient, @unchecked Sendable {
    private let handler: @Sendable (URL) async -> Result<Data, Error>
    private let lock = NSLock()
    private var urls: [URL] = []

    var requestedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return urls.count
    }

    init(handler: @escaping @Sendable (URL) async -> Result<Data, Error>) {
        self.handler = handler
    }

    func get(_ url: URL) -> Single<Data> {
        lock.lock()
        urls.append(url)
        lock.unlock()
        return Single.create { observer in
            let task = Task {
                let result = await self.handler(url)
                guard !Task.isCancelled else { return }
                switch result {
                case let .success(data):
                    observer(.success(data))
                case let .failure(error):
                    observer(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}

actor RequestFlags {
    private(set) var failPage2 = false
    private var page1Count = 0

    func setFailPage2(_ value: Bool) {
        failPage2 = value
    }

    func incrementPage1() -> Int {
        page1Count += 1
        return page1Count
    }
}

actor RequestGate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var armed = false

    func arm() {
        armed = true
        waiters.removeAll()
    }

    func waitIfNeeded() async {
        guard armed else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func waitUntilPending(count: Int = 1) async {
        while waiters.count < count {
            await Task.yield()
        }
    }

    func resume() {
        armed = false
        let pending = waiters
        waiters.removeAll()
        for waiter in pending {
            waiter.resume()
        }
    }
}
