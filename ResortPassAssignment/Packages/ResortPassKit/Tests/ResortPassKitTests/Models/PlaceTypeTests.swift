//
//  PlaceTypeTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/24/26.
//

import Foundation
import Testing
@testable import ResortPassKit

struct PlaceTypeTests {
    @Test(arguments: [
        ("city", PlaceType.city),
        ("hotel", PlaceType.hotel),
        ("alias", PlaceType.alias),
        ("state", PlaceType.state),
        ("country", PlaceType.country),
    ])
    func decodesEachKnownValue(rawValue: String, expected: PlaceType) throws {
        let json = "\"\(rawValue)\"".data(using: .utf8)!

        let type = try JSONDecoder().decode(PlaceType.self, from: json)

        #expect(type == expected)
    }

    @Test func decodesAnUnrecognizedValueAsUnknownRatherThanThrowing() throws {
        let json = "\"neighborhood\"".data(using: .utf8)!

        let type = try JSONDecoder().decode(PlaceType.self, from: json)

        #expect(type == .unknown("neighborhood"))
    }
}
