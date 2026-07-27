//
//  AutocompleteSearchView.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/23/26.
//

import ResortPassKit
import ResortPassUI
import SwiftUI


struct AutocompleteSearchView: View {
    @StateObject private var viewModel: AutocompleteSearchViewModel
    let onSelectPlace: (AutocompletePlace) -> Void

    init(
        viewModel: AutocompleteSearchViewModel? = nil,
        onSelectPlace: @escaping (AutocompletePlace) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AutocompleteSearchViewModel())
        self.onSelectPlace = onSelectPlace
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle:
            InformationView(
                icon: ResortPassIcon(systemName: "magnifyingglass", size: .large),
                title: "Search for a location or hotel"
            )
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading")
        case .loaded where viewModel.places.isEmpty:
            InformationView.emptySearch(text: viewModel.searchTerm)
        case .loaded:
            List(viewModel.places) { place in
                Button {
                    onSelectPlace(place)
                } label: {
                    row(for: place)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        case .failed:
            InformationView.error {
                ResortPassButton("Retry") { viewModel.retry() }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: ResortPassDimension.Spacing.small) {
            if case .loading = viewModel.loadingState {
                ProgressView()
                    .accessibilityHidden(true)
            } else {
                ResortPassIcon(systemName: "magnifyingglass")
                    .foregroundStyle(ResortPassColor.textSecondary)
                    .accessibilityHidden(true)
            }

            TextField("Search places", text: $viewModel.searchTerm)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Search places")

            if !viewModel.searchTerm.isEmpty {
                Button {
                    viewModel.searchTerm = ""
                } label: {
                    ResortPassIcon(systemName: "xmark.circle.fill")
                        .foregroundStyle(ResortPassColor.textSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(ResortPassDimension.Spacing.small)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: ResortPassDimension.CornerRadius.medium))
        .padding(ResortPassDimension.Spacing.large)
    }

    private func row(for place: AutocompletePlace) -> some View {
        HStack(spacing: ResortPassDimension.Spacing.medium) {
            icon(for: place.type)
                .foregroundStyle(ResortPassColor.textSecondary)
                .accessibilityLabel(accessibilityLabel(for: place.type))
            Text(place.name)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func icon(for type: PlaceType) -> ResortPassIcon {
        switch type {
        case .hotel:
            ResortPassIcon("search-hotel")
        case .state:
            ResortPassIcon("search-state")
        default:
            ResortPassIcon("search-location")
        }
    }

    private func accessibilityLabel(for type: PlaceType) -> String {
        switch type {
        case .hotel:
            "Hotel"
        case .state:
            "State"
        default:
            "Location"
        }
    }
}

#Preview {
    NavigationStack {
        AutocompleteSearchView { _ in }
    }
}
