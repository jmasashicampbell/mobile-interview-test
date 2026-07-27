//
//  HotelSearchResponseTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation
import Testing
@testable import ResortPassKit

struct HotelSearchResponseTests {
    @Test func keepsTheHotelsThatParseWhenOneIsMalformed() throws {
        let json = """
        {
            "total": 3, "pages": 1, "page": 0, "hits_per_page": 30,
            "currency": { "iso_code": "USD" },
            "hotels": [
                { "objectID": "1", "name": "Good One" },
                { "name": "Missing Its objectID" },
                { "objectID": "3", "name": "Good Two" }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(HotelSearchResponse.self, from: json)

        #expect(response.hotels.map(\.name) == ["Good One", "Good Two"])
        // `total` still reflects what the server has, not what survived decoding — pagination
        // stays driven by the server's count.
        #expect(response.total == 3)
    }

    @Test func decodesAFullResponse() throws {
        let json = """
        {
            "stage": 1,
            "total": 164,
            "pages": 6,
            "page": 0,
            "hits_per_page": 30,
            "offset": 0,
            "limit": 30,
            "queryID": "abc",
            "indexName": "staging_hotels_v3",
            "currency": {
                "id": 7,
                "symbol": "$",
                "name": "United States Dollar",
                "iso_code": "USD",
                "active": true
            },
            "hotels": [
                { "objectID": "1990:3227034", "name": "TWA Hotel" }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(HotelSearchResponse.self, from: json)

        #expect(response.total == 164)
        #expect(response.pages == 6)
        #expect(response.page == 0)
        #expect(response.hitsPerPage == 30)
        #expect(response.currencyCode == "USD")
        #expect(response.hotels.count == 1)
        #expect(response.hotels.first?.name == "TWA Hotel")
    }

    @Test func decodesAnEmptyHotelsArray() throws {
        let json = """
        {
            "total": 0,
            "pages": 0,
            "page": 0,
            "hits_per_page": 30,
            "currency": { "iso_code": "USD" },
            "hotels": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(HotelSearchResponse.self, from: json)

        #expect(response.hotels.isEmpty)
    }

    @Test func decodingFailsWhenCurrencyIsMissing() {
        let json = """
        {
            "total": 0,
            "pages": 0,
            "page": 0,
            "hits_per_page": 30,
            "hotels": []
        }
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(HotelSearchResponse.self, from: json)
        }
    }
}
