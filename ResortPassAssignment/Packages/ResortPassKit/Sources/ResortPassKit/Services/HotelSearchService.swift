//
//  HotelSearchService.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/23/26.
//

import CoreLocation
import Foundation

/// Calls `POST /api/search/algolia_hotels_v7`.
open class HotelSearchService: ResortPassService {
    private static let endpoint = ResortPassService.baseURL.appendingPathComponent("api/search/algolia_hotels_v7")

    open func searchHotels(near location: CLLocation, limit: Int = 30, offset: Int = 0) async throws -> HotelSearchResponse {
        let requestObject = HotelSearchRequest(location: location, limit: limit, offset: offset)
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestObject)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unexpectedStatusCode((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(HotelSearchResponse.self, from: data)
    }
}
