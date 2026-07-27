//
//  LossyArrayTests.swift
//  ResortPassKitTests
//

import Foundation
import Testing
@testable import ResortPassKit

struct LossyArrayTests {
    private struct Item: Decodable, Equatable {
        let id: Int
        let name: String
    }

    private func decode(_ json: String) throws -> [Item] {
        try JSONDecoder().decode(LossyArray<Item>.self, from: json.data(using: .utf8)!).elements
    }

    @Test func keepsEveryElementWhenAllOfThemParse() throws {
        let items = try decode(#"[{"id":1,"name":"A"},{"id":2,"name":"B"}]"#)

        #expect(items == [Item(id: 1, name: "A"), Item(id: 2, name: "B")])
    }

    @Test func dropsOnlyTheElementsThatFail() throws {
        let items = try decode(#"[{"id":1,"name":"A"},{"id":2},{"id":3,"name":"C"}]"#)

        #expect(items == [Item(id: 1, name: "A"), Item(id: 3, name: "C")])
    }

    @Test func dropsElementsOfEntirelyTheWrongShape() throws {
        let items = try decode(#"[{"id":1,"name":"A"},"not an object",7,null,{"id":2,"name":"B"}]"#)

        #expect(items == [Item(id: 1, name: "A"), Item(id: 2, name: "B")])
    }

    @Test func returnsEmptyWhenNothingParses() throws {
        let items = try decode(#"[{"id":1},{"id":2}]"#)

        #expect(items.isEmpty)
    }

    @Test func decodesAnEmptyArray() throws {
        #expect(try decode("[]").isEmpty)
    }

    @Test func stillThrowsWhenTheValueIsNotAnArrayAtAll() {
        #expect(throws: (any Error).self) {
            try decode(#"{"id":1,"name":"A"}"#)
        }
    }
}
