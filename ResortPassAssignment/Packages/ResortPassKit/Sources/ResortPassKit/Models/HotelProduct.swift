//
//  HotelProduct.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/22/26.
//

import Foundation

public struct HotelProduct: Decodable, Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let price: Double
    public let availability: String
    public let quantity: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, price, availability, quantity
    }
}
