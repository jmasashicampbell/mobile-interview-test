//
//  PlaceType.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/24/26.
//

import Foundation


public enum PlaceType: Decodable, Equatable {
    case city
    case hotel
    case alias
    case state
    case country
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "city": self = .city
        case "hotel": self = .hotel
        case "alias": self = .alias
        case "state": self = .state
        case "country": self = .country
        default: self = .unknown(rawValue)
        }
    }
}
