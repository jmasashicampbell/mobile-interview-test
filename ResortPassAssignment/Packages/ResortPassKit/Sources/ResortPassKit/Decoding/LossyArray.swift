//
//  LossyArray.swift
//  ResortPassKit
//

import Foundation

/// Decodes a JSON array element by element, keeping what parses and discarding what doesn't.
struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        elements.reserveCapacity(container.count ?? 0)

        let elementName = String(describing: Element.self)

        while !container.isAtEnd {
            switch try container.decode(DecodedElement<Element>.self) {
            case .success(let element):
                elements.append(element)
            case .failure(let error):
                print("LossyArray dropped \(elementName) at index \(container.currentIndex - 1): \(error)")
            }
        }

        self.elements = elements
    }

    /// Absorbs the error instead of rethrowing so that decoding always succeeds.
    /// An unkeyed container does not advance past an element whose decode threw,
    /// so calling `decode(Element.self)` directly and catching would retry the
    /// same index forever.
    private enum DecodedElement<Wrapped: Decodable>: Decodable {
        case success(Wrapped)
        case failure(Error)

        init(from decoder: Decoder) throws {
            do {
                self = .success(try Wrapped(from: decoder))
            } catch {
                self = .failure(error)
            }
        }
    }
}
