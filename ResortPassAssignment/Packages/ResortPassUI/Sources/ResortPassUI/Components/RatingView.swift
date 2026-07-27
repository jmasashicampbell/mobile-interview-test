//
//  RatingView.swift
//  ResortPassUI
//

import SwiftUI

/// A star rating with an optional review count, e.g. "★ 4.1 (164)".
public struct RatingView: View {
    private let rating: Double
    private let reviewCount: Int?

    public init(rating: Double, reviewCount: Int? = nil) {
        self.rating = rating
        self.reviewCount = reviewCount
    }

    public var body: some View {
        // Score and review count stay side by side while they fit. When they don't — large
        // Dynamic Type sizes, where the neighbouring hotel name is already competing for the
        // row — the count drops beneath the score instead of being squeezed. Both parts hold
        // their intrinsic width throughout, because "4.1" and "(164)" are single tokens: left
        // to compress, the count wraps mid-number and renders "(164)" as "(16" above "4)".
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ResortPassDimension.Spacing.xSmall) {
                score
                reviewCountLabel
            }

            VStack(alignment: .trailing, spacing: 0) {
                score
                reviewCountLabel
            }
        }
        .font(.subheadline)
        // Presented as one opaque element with its own label rather than three separate
        // VoiceOver stops (a decorative star icon, then the number, then the review count) —
        // reads naturally both on its own and when absorbed into a combined parent element.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var score: some View {
        HStack(spacing: ResortPassDimension.Spacing.xSmall) {
            ResortPassIcon(systemName: "star.fill", size: .small)
                .foregroundStyle(ResortPassColor.rating)
            Text(rating.formatted(.number.precision(.fractionLength(1))))
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var reviewCountLabel: some View {
        if let reviewCount {
            Text("(\(reviewCount))")
                .foregroundStyle(ResortPassColor.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var accessibilityLabel: String {
        let ratingText = rating.formatted(.number.precision(.fractionLength(1)))
        guard let reviewCount else {
            return "\(ratingText) out of 5 stars"
        }
        return "\(ratingText) out of 5 stars, \(reviewCount) reviews"
    }
}

#Preview {
    VStack(spacing: ResortPassDimension.Spacing.medium) {
        RatingView(rating: 4.1, reviewCount: 164)
        RatingView(rating: 3.0)
    }
    .padding()
}
