//
//  AutocompletePlaceTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import CoreLocation
import Foundation
import Testing
@testable import ResortPassKit

struct AutocompletePlaceTests {
    @Test func decodesAPlaceWithCoordinates() throws {
        let json = """
        {
            "id": 236,
            "name": "Newport Beach, California",
            "type": "city",
            "detailed_type": "city",
            "latitude": 33.6189,
            "longitude": -117.9298,
            "indexName": "staging_locations"
        }
        """.data(using: .utf8)!

        let place = try JSONDecoder().decode(AutocompletePlace.self, from: json)

        #expect(place.id == 236)
        #expect(place.name == "Newport Beach, California")
        #expect(place.type == .city)
        let location = try #require(place.location)
        #expect(location.coordinate.latitude == 33.6189)
        #expect(location.coordinate.longitude == -117.9298)
    }

    @Test func locationIsNilWhenCoordinatesAreMissing() throws {
        let json = """
        {
            "id": 1990,
            "name": "TWA Hotel",
            "type": "hotel"
        }
        """.data(using: .utf8)!

        let place = try JSONDecoder().decode(AutocompletePlace.self, from: json)

        #expect(place.location == nil)
    }

    @Test func locationIsNilWhenOnlyOneCoordinateIsPresent() throws {
        let json = """
        {
            "id": 1,
            "name": "Somewhere",
            "type": "city",
            "latitude": 12.34
        }
        """.data(using: .utf8)!

        let place = try JSONDecoder().decode(AutocompletePlace.self, from: json)

        #expect(place.location == nil)
    }
}
