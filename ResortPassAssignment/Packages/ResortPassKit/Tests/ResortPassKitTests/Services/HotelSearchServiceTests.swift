//
//  HotelSearchServiceTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import CoreLocation
import Foundation
import Testing
@testable import ResortPassKit

@Suite(.serialized)
struct HotelSearchServiceTests {
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

    private func makeService(handler: @escaping StubURLProtocol.Handler) -> HotelSearchService {
        StubURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return HotelSearchService(session: URLSession(configuration: configuration))
    }

    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)
            guard bytesRead > 0 else { break }
            data.append(buffer, count: bytesRead)
        }
        return data
    }

    private static let sampleResponseJSON = """
    {
        "total": 1, "pages": 1, "page": 0, "hits_per_page": 30,
        "currency": { "iso_code": "USD" },
        "hotels": [{ "objectID": "1990:3227034", "name": "TWA Hotel" }]
    }
    """.data(using: .utf8)!

    @Test func decodesHotelsFromASuccessfulResponse() async throws {
        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.sampleResponseJSON)
        }

        let result = try await service.searchHotels(near: CLLocation(latitude: 40.757, longitude: -73.736))

        #expect(result.hotels.count == 1)
        #expect(result.hotels.first?.name == "TWA Hotel")
        #expect(result.currencyCode == "USD")
    }

    @Test func postsLocationLimitAndOffsetAsTheRequestBody() async throws {
        var capturedBody: Data?
        var capturedMethod: String?
        let service = makeService { request in
            capturedBody = Self.body(of: request)
            capturedMethod = request.httpMethod
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.sampleResponseJSON)
        }

        _ = try await service.searchHotels(near: CLLocation(latitude: 40.757, longitude: -73.736), limit: 5, offset: 2)

        #expect(capturedMethod == "POST")
        let body = try #require(capturedBody)
        let decoded = try JSONDecoder().decode(DecodedBody.self, from: body)
        #expect(decoded.location.latitude == 40.757)
        #expect(decoded.location.longitude == -73.736)
        #expect(decoded.limit == 5)
        #expect(decoded.offset == 2)
    }

    @Test func throwsUnexpectedStatusCodeOnAServerError() async throws {
        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await #expect(throws: APIError.self) {
            _ = try await service.searchHotels(near: CLLocation(latitude: 0, longitude: 0))
        }
    }

    @Test func decodesAnEmptyHotelsArrayWithoutThrowing() async throws {
        let json = """
        { "total": 0, "pages": 1, "page": 0, "hits_per_page": 30, "currency": { "iso_code": "USD" }, "hotels": [] }
        """.data(using: .utf8)!
        let service = makeService { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let result = try await service.searchHotels(near: CLLocation(latitude: 0, longitude: -150))

        #expect(result.hotels.isEmpty)
    }

    private struct DecodedBody: Decodable {
        struct Location: Decodable {
            let latitude: Double
            let longitude: Double
        }

        let location: Location
        let limit: Int
        let offset: Int
    }
}
