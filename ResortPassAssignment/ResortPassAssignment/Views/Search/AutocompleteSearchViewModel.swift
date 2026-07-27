//
//  AutocompleteSearchViewModel.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/23/26.
//

import Combine
import Foundation
import ResortPassKit


@MainActor
final class AutocompleteSearchViewModel: ObservableObject {
    @Published var searchTerm: String = "" {
        didSet {
            scheduleSearch(for: searchTerm, debounced: true)
        }
    }

    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var places: [AutocompletePlace] = []

    private let service: AutocompleteService
    private var searchTask: Task<Void, Never>?

    private let debounceInterval: Duration

    nonisolated static let defaultDebounceInterval: Duration = .milliseconds(500)

    init(service: AutocompleteService? = nil, debounceInterval: Duration = defaultDebounceInterval) {
        self.service = service ?? AutocompleteService()
        self.debounceInterval = debounceInterval
    }

    func retry() {
        scheduleSearch(for: searchTerm, debounced: false)
    }

    private func scheduleSearch(for term: String, debounced: Bool) {
        searchTask?.cancel()

        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            loadingState = .idle
            places = []
            return
        }

        searchTask = Task {
            if debounced {
                do {
                    try await Task.sleep(for: debounceInterval)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled else { return }

            loadingState = .loading
            do {
                let results = try await service.autocompletePlaces(terms: trimmedTerm)
                guard !Task.isCancelled else { return }
                places = results
                loadingState = .loaded
            } catch {
                guard !Task.isCancelled else { return }
                loadingState = .failed(error)
            }
        }
    }
}
