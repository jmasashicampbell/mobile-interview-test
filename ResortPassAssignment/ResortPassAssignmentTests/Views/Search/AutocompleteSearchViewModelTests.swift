//
//  AutocompleteSearchViewModelTests.swift
//  ResortPassAssignmentTests
//
//  Created by Jerome Campbell on 7/23/26.
//

import Foundation
@testable import ResortPassKit
import Testing
@testable import ResortPassAssignment

@MainActor
struct AutocompleteSearchViewModelTests {
    private final class StubService: AutocompleteService {
        private let lock = NSLock()
        private var storedResult: Result<[AutocompletePlace], Error> = .success([])
        private var storedTerms: [String] = []

        var result: Result<[AutocompletePlace], Error> {
            get { lock.withLock { storedResult } }
            set { lock.withLock { storedResult = newValue } }
        }

        var receivedTerms: [String] { lock.withLock { storedTerms } }

        override func autocompletePlaces(terms: String, limit: Int, offset: Int) async throws -> [AutocompletePlace] {
            lock.withLock { storedTerms.append(terms) }
            return try result.get()
        }
    }

    private struct StubError: Error {}

    
    private static let testDebounce: Duration = .milliseconds(20)
    private static let pastDebounce: Duration = .milliseconds(200)

    private func makeViewModel(service: AutocompleteService) -> AutocompleteSearchViewModel {
        AutocompleteSearchViewModel(service: service, debounceInterval: Self.testDebounce)
    }

    @Test func defaultsToTheFiveHundredMillisecondDebounceRequiredByTheBrief() {
        #expect(AutocompleteSearchViewModel.defaultDebounceInterval == .milliseconds(500))
    }

    private func placeFixture() -> AutocompletePlace {
        let json = """
        { "id": 1, "name": "Newport Beach, California", "type": "city", "latitude": 33.6189, "longitude": -117.9298 }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(AutocompletePlace.self, from: json)
    }

    @Test func startsIdle() {
        let viewModel = makeViewModel(service: StubService())

        guard case .idle = viewModel.loadingState else {
            Issue.record("Expected .idle, got \(viewModel.loadingState)")
            return
        }
        #expect(viewModel.places.isEmpty)
    }

    @Test func debouncesBeforeSearchingAndOnlySearchesForTheLatestTerm() async {
        let service = StubService()
        service.result = .success([placeFixture()])
        let viewModel = makeViewModel(service: service)

        viewModel.searchTerm = "n"
        viewModel.searchTerm = "ne"
        viewModel.searchTerm = "new"

        #expect(service.receivedTerms.isEmpty)

        try? await Task.sleep(for: Self.pastDebounce)

        #expect(service.receivedTerms == ["new"])
        guard case .loaded = viewModel.loadingState else {
            Issue.record("Expected .loaded, got \(viewModel.loadingState)")
            return
        }
        #expect(viewModel.places.count == 1)
    }

    @Test func showsEmptyPlacesForNoResults() async {
        let service = StubService()
        service.result = .success([])
        let viewModel = makeViewModel(service: service)

        viewModel.searchTerm = "zzznonexistent"
        try? await Task.sleep(for: Self.pastDebounce)

        guard case .loaded = viewModel.loadingState else {
            Issue.record("Expected .loaded, got \(viewModel.loadingState)")
            return
        }
        #expect(viewModel.places.isEmpty)
    }

    @Test func showsFailedStateOnErrorAndRetryRecovers() async {
        let service = StubService()
        service.result = .failure(StubError())
        let viewModel = makeViewModel(service: service)

        viewModel.searchTerm = "new"
        try? await Task.sleep(for: Self.pastDebounce)

        guard case .failed(let error) = viewModel.loadingState else {
            Issue.record("Expected .failed, got \(viewModel.loadingState)")
            return
        }
        #expect(error is StubError)

        service.result = .success([placeFixture()])
        viewModel.retry()
        try? await Task.sleep(for: .milliseconds(50))

        guard case .loaded = viewModel.loadingState else {
            Issue.record("Expected .loaded after retry, got \(viewModel.loadingState)")
            return
        }
        #expect(viewModel.places.count == 1)
    }

    @Test func clearingTheSearchTermReturnsToIdleWithoutSearching() async {
        let service = StubService()
        service.result = .success([placeFixture()])
        let viewModel = makeViewModel(service: service)

        viewModel.searchTerm = "new"
        try? await Task.sleep(for: Self.pastDebounce)
        guard case .loaded = viewModel.loadingState else {
            Issue.record("Expected .loaded, got \(viewModel.loadingState)")
            return
        }

        viewModel.searchTerm = ""

        guard case .idle = viewModel.loadingState else {
            Issue.record("Expected .idle, got \(viewModel.loadingState)")
            return
        }
        #expect(viewModel.places.isEmpty)
    }
}
