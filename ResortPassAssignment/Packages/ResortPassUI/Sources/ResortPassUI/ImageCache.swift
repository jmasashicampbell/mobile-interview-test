//
//  ImageCache.swift
//  ResortPassUI
//

import UIKit


/// Safe to use from anywhere — which is what lets one shared instance serve concurrent lookups
/// from every row on screen — because both stored properties are immutable and each is itself
/// thread-safe: `NSCache` documents that it synchronises its own access, and `URLSession` is
/// designed to be called from multiple threads.
final class ImageCache {
    static let shared = ImageCache()

    private static let cacheLimitBytes = 100 * 1024 * 1024

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        cache.totalCostLimit = Self.cacheLimitBytes
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        guard let (data, _) = try? await session.data(from: url), let image = UIImage(data: data) else {
            return nil
        }

        let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }
}
