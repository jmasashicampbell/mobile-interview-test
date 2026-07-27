//
//  HotelSearchRequestTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import CoreLocation
import Foundation
import Testing
@testable import ResortPassKit

struct HotelSearchRequestTests {
    private struct DecodedRequest: Decodable {
        struct Location: Decodable {
            let latitude: Double
            let longitude: Double
        }

        let location: Location
        let limit: Int
        let offset: Int
    }

    @Test func encodesLocationAsANestedLatitudeLongitudeObject() throws {
        let location = CLLocation(latitude: 40.757, longitude: -73.736)
        let request = HotelSearchRequest(location: location, limit: 30, offset: 0)

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(DecodedRequest.self, from: data)

        #expect(decoded.location.latitude == 40.757)
        #expect(decoded.location.longitude == -73.736)
        #expect(decoded.limit == 30)
        #expect(decoded.offset == 0)
    }
}
