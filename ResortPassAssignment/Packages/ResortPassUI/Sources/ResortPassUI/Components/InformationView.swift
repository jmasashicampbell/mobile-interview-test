//
//  InformationView.swift
//  ResortPassUI
//

import SwiftUI

/// A large icon with a title and an optional message underneath, plus optional action buttons —
/// used for both empty and error states across the app.
public struct InformationView<Actions: View>: View {
    private let icon: ResortPassIcon
    private let title: String
    private let description: String?
    private let actions: Actions

    public init(
        icon: ResortPassIcon,
        title: String,
        description: String? = nil,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: ResortPassDimension.Spacing.large) {
            icon
                .foregroundStyle(ResortPassColor.textSecondary)
                .accessibilityHidden(true)
            VStack(spacing: ResortPassDimension.Spacing.xSmall) {
                Text(title)
                    .font(.title3.weight(.semibold))
                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(ResortPassColor.textSecondary)
                }
            }
            actions
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

extension InformationView where Actions == EmptyView {
    /// A "no results" state for a search screen.
    public static func emptySearch(text: String) -> InformationView {
        InformationView(
            icon: ResortPassIcon(systemName: "magnifyingglass", size: .large),
            title: "No Results",
            description: "No results found for \u{201C}\(text)\u{201D}"
        )
    }
}

extension InformationView {
    /// A generic "something went wrong" error state; the caller only supplies the retry action.
    public static func error(
        description: String = "Check your connection and try again.",
        @ViewBuilder actions: () -> Actions
    ) -> InformationView {
        InformationView(
            icon: ResortPassIcon(systemName: "exclamationmark.triangle", size: .large),
            title: "Something Went Wrong",
            description: description,
            actions: actions
        )
    }
}

#Preview("Plain") {
    InformationView(
        icon: ResortPassIcon(systemName: "building.2", size: .large),
        title: "No Hotels Found",
        description: "There are no hotels available near this location."
    )
}

#Preview("Empty Search") {
    InformationView.emptySearch(text: "zzznonexistent")
}

#Preview("Error") {
    InformationView.error {
        ResortPassButton("Retry") {}
    }
}
