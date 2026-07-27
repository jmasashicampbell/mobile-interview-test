//
//  AutocompleteServiceTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation
import Testing
@testable import ResortPassKit


@Suite(.serialized)
struct AutocompleteServiceTests {
    private final class StubURLProtocol: URLProtocol {
        typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

        private static let lock = NSLock()
        nonisolated(unsafe) private static var storedHandler: Handler?

        static var handler: Handler? {
            get { lock.withLock { storedHandler } }
            set { lock.withLock { storedHandler = newValue } }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
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

    private func makeService(handler: @escaping StubURLProtocol.Handler) -> AutocompleteService {
        StubURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return AutocompleteService(session: URLSession(configuration: configuration))
    }

    @Test func decodesPlacesFromASuccessfulResponse() async throws {
        let json = """
        [{ "id": 236, "name": "Newport Beach, California", "type": "city", "latitude": 33.6189, "longitude": -117.9298 }]
        """.data(using: .utf8)!

        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let places = try await service.autocompletePlaces(terms: "newport")

        #expect(places.count == 1)
        #expect(places.first?.name == "Newport Beach, California")
    }

    @Test func sendsTermsLimitAndOffsetAsQueryParameters() async throws {
        var capturedURL: URL?
        let service = makeService { request in
            capturedURL = request.url
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await service.autocompletePlaces(terms: "new york", limit: 5, offset: 2)

        let url = try #require(capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)
        #expect(queryItems.contains(URLQueryItem(name: "terms", value: "new york")))
        #expect(queryItems.contains(URLQueryItem(name: "limit", value: "5")))
        #expect(queryItems.contains(URLQueryItem(name: "offset", value: "2")))
    }

    @Test func throwsUnexpectedStatusCodeOnAServerError() async throws {
        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await #expect(throws: APIError.self) {
            _ = try await service.autocompletePlaces(terms: "new")
        }
    }

    @Test func decodesAnEmptyArrayWithoutThrowing() async throws {
        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        let places = try await service.autocompletePlaces(terms: "zzznonexistent")

        #expect(places.isEmpty)
    }
}
