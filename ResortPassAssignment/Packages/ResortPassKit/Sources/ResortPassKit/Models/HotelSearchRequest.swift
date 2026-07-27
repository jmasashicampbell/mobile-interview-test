//
//  HotelSearchRequest.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/22/26.
//

import CoreLocation

/// Request body for `POST /api/search/algolia_hotels_v7`.
public struct HotelSearchRequest: Encodable {
    private let latitude: CLLocationDegrees
    private let longitude: CLLocationDegrees
    public let limit: Int
    public let offset: Int

    public init(location: CLLocation, limit: Int, offset: Int) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        self.limit = limit
        self.offset = offset
    }

    private enum CodingKeys: String, CodingKey {
        case location, limit, offset
    }

    private enum LocationCodingKeys: String, CodingKey {
        case latitude, longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(limit, forKey: .limit)
        try container.encode(offset, forKey: .offset)

        var locationContainer = container.nestedContainer(keyedBy: LocationCodingKeys.self, forKey: .location)
        try locationContainer.encode(latitude, forKey: .latitude)
        try locationContainer.encode(longitude, forKey: .longitude)
    }
}
