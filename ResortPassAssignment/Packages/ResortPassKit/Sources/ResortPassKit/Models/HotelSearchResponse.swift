//
//  HotelSearchResponse.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/22/26.
//

import Foundation

/// Response body for `POST /api/search/algolia_hotels_v7`.
public struct HotelSearchResponse: Decodable {
    public let total: Int
    public let pages: Int
    public let page: Int
    public let hitsPerPage: Int
    public let currencyCode: String
    public let hotels: [Hotel]

    private enum CodingKeys: String, CodingKey {
        case total, pages, page, hotels, currency
        case hitsPerPage = "hits_per_page"
    }

    private enum CurrencyCodingKeys: String, CodingKey {
        case isoCode = "iso_code"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        pages = try container.decode(Int.self, forKey: .pages)
        page = try container.decode(Int.self, forKey: .page)
        hitsPerPage = try container.decode(Int.self, forKey: .hitsPerPage)
        hotels = try container.decode(LossyArray<Hotel>.self, forKey: .hotels).elements

        let currencyContainer = try container.nestedContainer(keyedBy: CurrencyCodingKeys.self, forKey: .currency)
        currencyCode = try currencyContainer.decode(String.self, forKey: .isoCode)
    }
}
