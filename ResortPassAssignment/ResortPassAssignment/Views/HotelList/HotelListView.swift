//
//  HotelListView.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/24/26.
//

import CoreLocation
import ResortPassKit
import ResortPassUI
import SwiftUI


struct HotelListView: View {
    private let placeName: String
    private let location: CLLocation?

    init(placeName: String, location: CLLocation?) {
        self.placeName = placeName
        self.location = location
    }

    var body: some View {
        Group {
            if let location {
                HotelListContentView(placeName: placeName, location: location)
            } else {
                InformationView(
                    icon: ResortPassIcon(systemName: "mappin.slash", size: .large),
                    title: "Location Unavailable",
                    description: "\(placeName) doesn't have location data available."
                )
            }
        }
        .navigationTitle("Hotels near \(placeName)")
        .navigationBarTitleDisplayMode(.inline)
    }
}


private struct HotelListContentView: View {
    @StateObject private var viewModel: HotelListViewModel
    private let placeName: String

    init(placeName: String, location: CLLocation) {
        self.placeName = placeName
        _viewModel = StateObject(wrappedValue: HotelListViewModel(location: location))
    }

    var body: some View {
        content
            .task {
                await viewModel.loadInitialPageIfNeeded()
            }
            .onDisappear {
                viewModel.cancelPendingWork()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.initialPageLoadingState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading")
        case .loaded where viewModel.hotels.isEmpty:
            InformationView(
                icon: ResortPassIcon(systemName: "building.2", size: .large),
                title: "No Hotels Found",
                description: "There are no hotels available near \(placeName)."
            )
        case .loaded:
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.hotels) { hotel in
                        HotelRowView(hotel: hotel, currencyCode: viewModel.currencyCode)
                            .onAppear {
                                viewModel.loadNextPageIfNeeded(currentItem: hotel)
                            }
                        Divider()
                    }

                    nextPageFooter
                }
            }
        case .failed:
            InformationView.error {
                ResortPassButton("Retry") { viewModel.retryInitialPage() }
            }
        }
    }

    @ViewBuilder
    private var nextPageFooter: some View {
        switch viewModel.nextPageLoadingState {
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                    .accessibilityLabel("Loading more hotels")
                Spacer()
            }
            .padding(.vertical, ResortPassDimension.Spacing.medium)
        case .failed:
            VStack(spacing: ResortPassDimension.Spacing.small) {
                Text("Couldn't load more hotels.")
                    .font(.subheadline)
                    .foregroundStyle(ResortPassColor.textSecondary)
                ResortPassButton("Retry") { viewModel.retryLoadingNextPage() }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ResortPassDimension.Spacing.medium)
        case .idle, .loaded:
            EmptyView()
        }
    }
}

#Preview("Loaded") {
    NavigationStack {
        HotelListView(placeName: "Newport Beach, California", location: CLLocation(latitude: 33.6189, longitude: -117.9298))
    }
}

#Preview("Location Unavailable") {
    NavigationStack {
        HotelListView(placeName: "Somewhere Unmapped", location: nil)
    }
}
