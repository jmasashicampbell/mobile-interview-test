//
//  HotelListViewModelTests.swift
//  ResortPassAssignmentTests
//
//  Created by Jerome Campbell on 7/24/26.
//

import CoreLocation
import Foundation
@testable import ResortPassKit
import Testing
@testable import ResortPassAssignment

@MainActor
struct HotelListViewModelTests {
    private final class StubService: HotelSearchService {
        private let lock = NSLock()
        private var storedResponses: [Result<HotelSearchResponse, Error>] = []
        private var storedOffsets: [Int] = []
        private var storedDelay: Duration?

        var responses: [Result<HotelSearchResponse, Error>] {
            get { lock.withLock { storedResponses } }
            set { lock.withLock { storedResponses = newValue } }
        }

        var receivedOffsets: [Int] { lock.withLock { storedOffsets } }

        var delay: Duration? {
            get { lock.withLock { storedDelay } }
            set { lock.withLock { storedDelay = newValue } }
        }

        private var startedCount = 0
        private var pendingStartSignal: CheckedContinuation<Void, Never>?

        
        func waitForRequestToStart(count: Int = 1) async {
            await withCheckedContinuation { continuation in
                let alreadyStarted = lock.withLock {
                    guard startedCount < count else { return true }
                    pendingStartSignal = continuation
                    return false
                }
                if alreadyStarted {
                    continuation.resume()
                }
            }
        }

        override func searchHotels(near location: CLLocation, limit: Int, offset: Int) async throws -> HotelSearchResponse {
            let (delay, startSignal): (Duration?, CheckedContinuation<Void, Never>?) = lock.withLock {
                storedOffsets.append(offset)
                startedCount += 1
                defer { pendingStartSignal = nil }
                return (storedDelay, pendingStartSignal)
            }
            startSignal?.resume()

            if let delay {
                try await Task.sleep(for: delay)
            }
            // Deliberately traps if a test queued fewer responses than it triggers requests.
            return try lock.withLock { storedResponses.removeFirst() }.get()
        }
    }

    private struct StubError: Error {}

    private let sampleLocation = CLLocation(latitude: 40.757, longitude: -73.736)

    private func responseFixture(hotelCount: Int, total: Int, startingID: Int = 0) -> HotelSearchResponse {
        let hotels = (0..<hotelCount)
            .map { "{ \"objectID\": \"\(startingID + $0)\", \"name\": \"Hotel \(startingID + $0)\" }" }
            .joined(separator: ",")
        let json = """
        {
            "total": \(total), "pages": 1, "page": 0, "hits_per_page": 30,
            "currency": { "iso_code": "USD" },
            "hotels": [\(hotels)]
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(HotelSearchResponse.self, from: json)
    }

    @Test func startsIdleWithNoHotels() {
        let viewModel = HotelListViewModel(location: sampleLocation, service: StubService())

        guard case .idle = viewModel.initialPageLoadingState else {
            Issue.record("Expected .idle, got \(viewModel.initialPageLoadingState)")
            return
        }
        guard case .idle = viewModel.nextPageLoadingState else {
            Issue.record("Expected .idle, got \(viewModel.nextPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.isEmpty)
    }

    @Test func loadsTheInitialPageOfHotels() async {
        let service = StubService()
        service.responses = [.success(responseFixture(hotelCount: 2, total: 2))]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        guard case .loaded = viewModel.initialPageLoadingState else {
            Issue.record("Expected .loaded, got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.count == 2)
        #expect(viewModel.currencyCode == "USD")
        #expect(service.receivedOffsets == [0])
    }

    @Test func loadsAnEmptyHotelListWithoutThrowing() async {
        let service = StubService()
        service.responses = [.success(responseFixture(hotelCount: 0, total: 0))]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        guard case .loaded = viewModel.initialPageLoadingState else {
            Issue.record("Expected .loaded, got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.isEmpty)
    }

    @Test func showsFailedStateOnErrorAndRetryRecovers() async {
        let service = StubService()
        service.responses = [.failure(StubError())]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        guard case .failed(let error) = viewModel.initialPageLoadingState else {
            Issue.record("Expected .failed, got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(error is StubError)

        service.responses = [.success(responseFixture(hotelCount: 1, total: 1))]
        viewModel.retryInitialPage()
        await viewModel.loadTask?.value

        guard case .loaded = viewModel.initialPageLoadingState else {
            Issue.record("Expected .loaded after retry, got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.count == 1)
    }

    @Test func loadsTheNextPageWhenNearingTheEndOfTheList() async {
        let service = StubService()
        service.responses = [
            .success(responseFixture(hotelCount: 30, total: 40)),
            .success(responseFixture(hotelCount: 10, total: 40, startingID: 30)),
        ]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()
        #expect(viewModel.hotels.count == 30)

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        #expect(viewModel.hotels.count == 40)
        #expect(service.receivedOffsets == [0, 30])
        guard case .idle = viewModel.nextPageLoadingState else {
            Issue.record("Expected .idle after a successful load-more, got \(viewModel.nextPageLoadingState)")
            return
        }
    }

    @Test func doesNotLoadTheNextPageWhenNotYetNearTheEnd() async {
        let service = StubService()
        service.responses = [.success(responseFixture(hotelCount: 30, total: 40))]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.first!)
        await viewModel.loadTask?.value

        #expect(viewModel.hotels.count == 30)
        #expect(service.receivedOffsets == [0])
    }

    @Test func doesNotLoadANextPageWhenEverythingIsAlreadyLoaded() async {
        let service = StubService()
        service.responses = [.success(responseFixture(hotelCount: 5, total: 5))]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        #expect(viewModel.hotels.count == 5)
        #expect(service.receivedOffsets == [0])
    }

    @Test func aFailedLoadMoreLeavesTheExistingListVisibleAndSetsThePageErrorState() async {
        let service = StubService()
        service.responses = [
            .success(responseFixture(hotelCount: 30, total: 40)),
            .failure(StubError()),
        ]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        guard case .loaded = viewModel.initialPageLoadingState else {
            Issue.record("Expected .loaded (existing list preserved), got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.count == 30)
        guard case .failed(let error) = viewModel.nextPageLoadingState else {
            Issue.record("Expected .failed, got \(viewModel.nextPageLoadingState)")
            return
        }
        #expect(error is StubError)
    }

    @Test func doesNotAutoRetryAFailedLoadMoreOnScroll() async {
        let service = StubService()
        service.responses = [
            .success(responseFixture(hotelCount: 30, total: 40)),
            .failure(StubError()),
        ]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        // Scrolling near the bottom again should NOT silently retry — only retryLoadingNextPage() does.
        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        #expect(service.receivedOffsets == [0, 30])
    }

    @Test func cancellingTheInitialLoadRewindsToIdleSoTheScreenCanLoadAgain() async {
        let service = StubService()
        service.delay = .seconds(30)
        service.responses = [.success(responseFixture(hotelCount: 2, total: 2))]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        
        let task = Task { await viewModel.loadInitialPageIfNeeded() }
        await service.waitForRequestToStart()
        task.cancel()
        await task.value

        guard case .idle = viewModel.initialPageLoadingState else {
            Issue.record("Expected .idle after cancellation, got \(viewModel.initialPageLoadingState)")
            return
        }
        #expect(viewModel.hotels.isEmpty)

        
        service.delay = nil
        await viewModel.loadInitialPageIfNeeded()
        #expect(viewModel.hotels.count == 2)
    }

    
    @Test func cancelPendingWorkStopsAnInFlightNextPageLoad() async {
        let service = StubService()
        service.responses = [
            .success(responseFixture(hotelCount: 30, total: 40)),
            .success(responseFixture(hotelCount: 10, total: 40, startingID: 30)),
        ]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        service.delay = .seconds(30)
        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await service.waitForRequestToStart(count: 2)

        let pendingWork = viewModel.loadTask
        viewModel.cancelPendingWork()
        await pendingWork?.value

        #expect(viewModel.hotels.count == 30)
        guard case .idle = viewModel.nextPageLoadingState else {
            Issue.record("Expected .idle after cancellation, got \(viewModel.nextPageLoadingState)")
            return
        }
    }

    @Test func retryLoadingNextPageRecoversFromAFailure() async {
        let service = StubService()
        service.responses = [
            .success(responseFixture(hotelCount: 30, total: 40)),
            .failure(StubError()),
            .success(responseFixture(hotelCount: 10, total: 40, startingID: 30)),
        ]
        let viewModel = HotelListViewModel(location: sampleLocation, service: service)

        await viewModel.loadInitialPageIfNeeded()

        viewModel.loadNextPageIfNeeded(currentItem: viewModel.hotels.last!)
        await viewModel.loadTask?.value

        viewModel.retryLoadingNextPage()
        await viewModel.loadTask?.value

        #expect(viewModel.hotels.count == 40)
        #expect(service.receivedOffsets == [0, 30, 30])
        guard case .idle = viewModel.nextPageLoadingState else {
            Issue.record("Expected .idle after retry succeeds, got \(viewModel.nextPageLoadingState)")
            return
        }
    }
}
