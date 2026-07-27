//
//  ResortPassButton.swift
//  ResortPassUI
//

import SwiftUI

/// The app's standard filled button — rounded rectangle, not a pill, matching the rest of the
/// design system's corner language.
public struct ResortPassButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(FillStyle())
    }

    private struct FillStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(ResortPassColor.textAlwaysWhite)
                .padding(.vertical, ResortPassDimension.Spacing.medium)
                .padding(.horizontal, ResortPassDimension.Spacing.large)
                .background(ResortPassColor.primaryAccent,
                            in: RoundedRectangle(cornerRadius: ResortPassDimension.CornerRadius.medium,
                                                 style: .continuous))
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

#Preview {
    ResortPassButton("Retry") {}
        .padding()
}
