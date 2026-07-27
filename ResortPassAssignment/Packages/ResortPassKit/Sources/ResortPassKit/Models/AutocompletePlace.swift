//
//  AutocompletePlace.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/22/26.
//

import CoreLocation

public struct AutocompletePlace: Decodable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let type: PlaceType
    public let location: CLLocation?

    private enum CodingKeys: String, CodingKey {
        case id, name, type, latitude, longitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(PlaceType.self, forKey: .type)

        location = if let latitude = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .latitude),
                      let longitude = try container.decodeIfPresent(CLLocationDegrees.self, forKey: .longitude) {
            CLLocation(latitude: latitude, longitude: longitude)
        } else {
            nil
        }
    }

    public static func == (lhs: AutocompletePlace, rhs: AutocompletePlace) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
