//
//  Hotel.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/22/26.
//

import Foundation

public struct Hotel: Decodable, Identifiable {
    public var id: String { objectID }

    public let objectID: String
    public let name: String
    public let cityName: String?
    public let state: String?
    public let stateCode: String?
    public let rating: Double?
    public let reviews: Int?
    public let pictureURL: URL?
    public let products: [HotelProduct]?

    private enum CodingKeys: String, CodingKey {
        case objectID
        case name
        case cityName = "city_name"
        case state
        case stateCode = "state_code"
        case rating
        case reviews
        case images = "image"
        case products
    }

    private struct ImageEntry: Decodable {
        let picture: Picture

        struct Picture: Decodable {
            let results: Variant

            struct Variant: Decodable {
                let url: String
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        objectID = try container.decode(String.self, forKey: .objectID)
        name = try container.decode(String.self, forKey: .name)
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        stateCode = try container.decodeIfPresent(String.self, forKey: .stateCode)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviews = try container.decodeIfPresent(Int.self, forKey: .reviews)
        // Lossy: a hotel whose products or images are partly malformed is still worth showing —
        // losing one product row beats losing the hotel.
        products = try container.decodeIfPresent(LossyArray<HotelProduct>.self, forKey: .products)?.elements

        let images = try container.decodeIfPresent(LossyArray<ImageEntry>.self, forKey: .images)?.elements
        let pictureURLString = images?.first?.picture.results.url
        pictureURL = pictureURLString.flatMap(URL.init(string:))
    }
}
