//
//  HotelProductTests.swift
//  ResortPassKitTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation
import Testing
@testable import ResortPassKit

struct HotelProductTests {
    @Test func decodesAProduct() throws {
        let json = """
        {
            "availability": "available",
            "id": 3227029,
            "name": "Day Pass",
            "price": 50.0,
            "product_categories": ["Pool"],
            "product_type_id": 2,
            "product_type_name": "Day Pass",
            "quantity": 30,
            "show_currency": false
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder().decode(HotelProduct.self, from: json)

        #expect(product.id == 3227029)
        #expect(product.name == "Day Pass")
        #expect(product.price == 50.0)
        #expect(product.availability == "available")
        #expect(product.quantity == 30)
    }
}
