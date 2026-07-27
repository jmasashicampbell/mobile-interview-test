//
//  APIError.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation

/// Thrown by the services when the server responds outside the 2xx range, so callers get a
/// clear signal distinct from a transport failure (`URLError`) or a decoding failure.
public enum APIError: Error {
    case unexpectedStatusCode(Int)
}
