//
//  AutocompleteService.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation

/// Calls `GET /api/search/places/autocomplete`.
open class AutocompleteService: ResortPassService {
    private static let endpoint = ResortPassService.baseURL.appendingPathComponent("api/search/places/autocomplete")

    open func autocompletePlaces(terms: String, limit: Int = 10, offset: Int = 0) async throws -> [AutocompletePlace] {
        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "terms", value: terms),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unexpectedStatusCode((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        // Lossy: the response is a bare array, so one unparseable place would otherwise empty the
        // whole suggestion list mid-keystroke.
        return try JSONDecoder().decode(LossyArray<AutocompletePlace>.self, from: data).elements
    }
}
