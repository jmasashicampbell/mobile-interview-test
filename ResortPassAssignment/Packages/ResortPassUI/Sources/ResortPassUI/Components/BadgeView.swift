//
//  BadgeView.swift
//  ResortPassUI
//

import SwiftUI


public struct BadgeView: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ResortPassColor.textAlwaysBlack)
            .padding(.horizontal, ResortPassDimension.Spacing.small)
            .padding(.vertical, ResortPassDimension.Spacing.xSmall)
            .background(ResortPassColor.secondaryAccent,
                        in: RoundedRectangle(cornerRadius: ResortPassDimension.CornerRadius.small,
                                             style: .continuous))
    }
}

#Preview {
    VStack(spacing: ResortPassDimension.Spacing.medium) {
        BadgeView("Only 2 Left")
    }
}
