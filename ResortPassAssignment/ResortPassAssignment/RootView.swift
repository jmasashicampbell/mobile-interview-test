//
//  RootView.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/22/26.
//

import ResortPassKit
import SwiftUI


struct RootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AutocompleteSearchView { place in
                path.append(place)
            }
            .navigationDestination(for: AutocompletePlace.self) { place in
                HotelListView(placeName: place.name, location: place.location)
            }
        }
    }
}

#Preview {
    RootView()
}
