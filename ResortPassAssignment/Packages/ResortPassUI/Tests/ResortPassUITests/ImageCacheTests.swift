//
//  ImageCacheTests.swift
//  ResortPassUITests
//

import Foundation
import Testing
import UIKit
@testable import ResortPassUI

@Suite(.serialized)
struct ImageCacheTests {
    private final class StubURLProtocol: URLProtocol {
        typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

        private static let lock = NSLock()
        nonisolated(unsafe) private static var storedHandler: Handler?
        nonisolated(unsafe) private static var storedRequestCount = 0

        static var handler: Handler? {
            get { lock.withLock { storedHandler } }
            set { lock.withLock { storedHandler = newValue } }
        }

        static var requestCount: Int {
            get { lock.withLock { storedRequestCount } }
            set { lock.withLock { storedRequestCount = newValue } }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            Self.lock.withLock { Self.storedRequestCount += 1 }
            guard let handler = Self.handler else {
                fatalError("StubURLProtocol.handler was not set before making a request")
            }
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private func makeCache(handler: @escaping StubURLProtocol.Handler) -> ImageCache {
        StubURLProtocol.handler = handler
        StubURLProtocol.requestCount = 0
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return ImageCache(session: URLSession(configuration: configuration))
    }

    private static let samplePNGData: Data = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }()

    private static let sampleURL = URL(string: "https://staging-app.resortpass.com/image.png")!

    @Test func decodesAnImageFromASuccessfulResponse() async throws {
        let cache = makeCache { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.samplePNGData)
        }

        let image = await cache.image(for: Self.sampleURL)

        #expect(image != nil)
    }

    @Test func returnsNilWhenTheResponseIsNotImageData() async throws {
        let cache = makeCache { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not an image".data(using: .utf8)!)
        }

        let image = await cache.image(for: Self.sampleURL)

        #expect(image == nil)
    }

    @Test func returnsNilWhenTheRequestFails() async throws {
        struct StubError: Error {}
        let cache = makeCache { _ in throw StubError() }

        let image = await cache.image(for: Self.sampleURL)

        #expect(image == nil)
    }

    @Test func onlyFetchesTheSameURLOnceAcrossRepeatedCalls() async throws {
        let cache = makeCache { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.samplePNGData)
        }

        _ = await cache.image(for: Self.sampleURL)
        _ = await cache.image(for: Self.sampleURL)

        #expect(StubURLProtocol.requestCount == 1)
    }
}
