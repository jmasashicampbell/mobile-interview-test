//
//  HotelTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation
import Testing
@testable import ResortPassKit

struct HotelTests {
    @Test func decodesAHotelWithAllFields() throws {
        let json = """
        {
            "id": 1990,
            "objectID": "1990:3227034",
            "name": "TWA Hotel",
            "city_name": "New York",
            "state": "New York",
            "state_code": "NY",
            "rating": 4.1,
            "reviews": 164,
            "image": [
                {
                    "picture": {
                        "results": {
                            "url": "https://example.com/results.jpg"
                        }
                    }
                }
            ],
            "products": [
                { "id": 1, "name": "Day Pass", "price": 50.0, "availability": "available", "quantity": 30 }
            ]
        }
        """.data(using: .utf8)!

        let hotel = try JSONDecoder().decode(Hotel.self, from: json)

        #expect(hotel.objectID == "1990:3227034")
        #expect(hotel.id == "1990:3227034")
        #expect(hotel.name == "TWA Hotel")
        #expect(hotel.cityName == "New York")
        #expect(hotel.state == "New York")
        #expect(hotel.stateCode == "NY")
        #expect(hotel.rating == 4.1)
        #expect(hotel.reviews == 164)
        #expect(hotel.pictureURL == URL(string: "https://example.com/results.jpg"))
        #expect(hotel.products?.count == 1)
        #expect(hotel.products?.first?.name == "Day Pass")
    }

    @Test func pictureURLIsNilWhenImageArrayIsMissing() throws {
        let json = """
        { "objectID": "1:1", "name": "No Image Hotel" }
        """.data(using: .utf8)!

        let hotel = try JSONDecoder().decode(Hotel.self, from: json)

        #expect(hotel.pictureURL == nil)
    }

    @Test func optionalFieldsDecodeToNilWhenAbsent() throws {
        let json = """
        { "objectID": "1:1", "name": "Bare Hotel" }
        """.data(using: .utf8)!

        let hotel = try JSONDecoder().decode(Hotel.self, from: json)

        #expect(hotel.cityName == nil)
        #expect(hotel.state == nil)
        #expect(hotel.stateCode == nil)
        #expect(hotel.rating == nil)
        #expect(hotel.reviews == nil)
        #expect(hotel.products == nil)
    }

    @Test func decodingFailsWhenObjectIDIsMissing() {
        let json = """
        { "name": "No ObjectID Hotel" }
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Hotel.self, from: json)
        }
    }

    @Test func keepsTheProductsThatParseWhenOneIsMalformed() throws {
        let json = """
        {
            "objectID": "1:1",
            "name": "Partly Broken Hotel",
            "products": [
                { "id": 1, "name": "Day Pass", "price": 50.0, "availability": "available", "quantity": 30 },
                { "id": 2, "name": "Cabana", "price": 250.0, "availability": "available" },
                { "id": 3, "name": "Daybed", "price": 150.0, "availability": "available", "quantity": 3 }
            ]
        }
        """.data(using: .utf8)!

        let hotel = try JSONDecoder().decode(Hotel.self, from: json)

        #expect(hotel.products?.map(\.name) == ["Day Pass", "Daybed"])
    }

    @Test func fallsBackToTheNextImageWhenTheFirstIsMalformed() throws {
        let json = """
        {
            "objectID": "1:1",
            "name": "Bad First Image Hotel",
            "image": [
                { "picture": { "url": "/no-results-variant.jpg" } },
                { "picture": { "results": { "url": "https://example.com/good.jpg" } } }
            ]
        }
        """.data(using: .utf8)!

        let hotel = try JSONDecoder().decode(Hotel.self, from: json)

        #expect(hotel.pictureURL == URL(string: "https://example.com/good.jpg"))
    }
}
