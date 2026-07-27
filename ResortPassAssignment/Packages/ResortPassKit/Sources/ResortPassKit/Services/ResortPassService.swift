//
//  ResortPassService.swift
//  ResortPassKit
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation


open class ResortPassService {
    static let baseURL = URL(string: "https://staging-app.resortpass.com")!

    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }
}
