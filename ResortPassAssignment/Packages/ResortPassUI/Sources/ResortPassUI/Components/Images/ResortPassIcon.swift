//
//  ResortPassIcon.swift
//  ResortPassUI
//

import SwiftUI

public struct ResortPassIcon: View {
    public enum Size {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: 14
            case .medium: 20
            case .large: 48
            }
        }

        /// The text style each size is expected to sit beside, so the icon grows at the same rate
        /// as its neighbouring copy under Dynamic Type
        var textStyle: Font.TextStyle {
            switch self {
            case .small: .subheadline
            case .medium: .body
            case .large: .body
            }
        }
    }

    private let image: Image

    @ScaledMetric private var dimension: CGFloat

    public init(_ name: String, size: Size = .medium) {
        self.image = Image(name)
        self._dimension = ScaledMetric(wrappedValue: size.dimension,
                                       relativeTo: size.textStyle)
    }

    public init(systemName: String, size: Size = .medium) {
        self.image = Image(systemName: systemName)
        self._dimension = ScaledMetric(wrappedValue: size.dimension,
                                       relativeTo: size.textStyle)
    }

    public var body: some View {
        image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: dimension, height: dimension)
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: ResortPassDimension.Spacing.medium) {
        ResortPassIcon(systemName: "star.fill", size: .small)
        ResortPassIcon(systemName: "star.fill", size: .medium)
        ResortPassIcon(systemName: "star.fill", size: .large)
    }
    .padding()
}
