//
//  HotelListViewModel.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/24/26.
//

import Combine
import CoreLocation
import ResortPassKit


@MainActor
final class HotelListViewModel: ObservableObject {
    @Published private(set) var initialPageLoadingState: LoadingState = .idle
    @Published private(set) var nextPageLoadingState: LoadingState = .idle
    @Published private(set) var hotels: [Hotel] = []
    @Published private(set) var currencyCode = "USD"

    private let service: HotelSearchService
    private let location: CLLocation
    private(set) var loadTask: Task<Void, Never>?
    private var totalHotelsAvailable = 0

    private static let pageSize = 30
    private static let nextPageLoadThreshold = 3

    private var hasMorePages: Bool {
        hotels.count < totalHotelsAvailable
    }

    init(location: CLLocation, service: HotelSearchService? = nil) {
        self.location = location
        self.service = service ?? HotelSearchService()
    }

    func loadInitialPageIfNeeded() async {
        guard case .idle = initialPageLoadingState else { return }
        initialPageLoadingState = .loading
        await load(offset: 0, appending: false)
    }

    func retryInitialPage() {
        initialPageLoadingState = .idle
        hotels = []
        loadTask?.cancel()
        loadTask = Task {
            await loadInitialPageIfNeeded()
        }
    }

    func cancelPendingWork() {
        loadTask?.cancel()
        loadTask = nil
    }

    /// Called as each row appears; triggers loading the next page once the user scrolls near the bottom of what's currently loaded.
    func loadNextPageIfNeeded(currentItem hotel: Hotel) {
        guard hasMorePages, case .loaded = initialPageLoadingState else { return }
        guard case .idle = nextPageLoadingState else { return }
        guard let index = hotels.firstIndex(where: { $0.id == hotel.id }) else { return }
        guard index >= hotels.count - Self.nextPageLoadThreshold else { return }

        loadNextPage()
    }

    func retryLoadingNextPage() {
        guard case .failed = nextPageLoadingState else { return }
        loadNextPage()
    }

    private func loadNextPage() {
        nextPageLoadingState = .loading
        loadTask?.cancel()
        loadTask = Task {
            await load(offset: hotels.count, appending: true)
        }
    }

    private func load(offset: Int, appending: Bool) async {
        do {
            let response = try await service.searchHotels(near: location, limit: Self.pageSize, offset: offset)
            guard !Task.isCancelled else { return resetLoadingState(appending: appending) }

            currencyCode = response.currencyCode
            totalHotelsAvailable = response.total
            hotels = appending ? hotels + response.hotels : response.hotels

            if appending {
                nextPageLoadingState = .idle
            } else {
                initialPageLoadingState = .loaded
            }
        } catch {
            guard !Task.isCancelled else { return resetLoadingState(appending: appending) }

            if appending {
                nextPageLoadingState = .failed(error)
            } else {
                initialPageLoadingState = .failed(error)
            }
        }
    }

    private func resetLoadingState(appending: Bool) {
        if appending {
            nextPageLoadingState = .idle
        } else {
            initialPageLoadingState = .idle
        }
    }
}
