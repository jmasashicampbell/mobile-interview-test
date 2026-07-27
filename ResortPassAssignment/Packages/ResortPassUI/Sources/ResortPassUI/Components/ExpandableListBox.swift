//
//  ExpandableListBox.swift
//  ResortPassUI
//

import SwiftUI

/// A rounded, grouped list container with built-in "show N more / show less" collapsing. Pass
/// `nil` for `collapsedLimit` to show every row with no expand/collapse control at all.
public struct ExpandableListBox<Data: RandomAccessCollection, RowContent: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let collapsedLimit: Int?
    private let rowContent: (Data.Element) -> RowContent

    @State private var isExpanded = false

    private let dividerWidth: CGFloat = 1

    public init(
        _ data: Data,
        collapsedLimit: Int? = 3,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.collapsedLimit = collapsedLimit
        self.rowContent = rowContent
    }

    private var visibleItems: [Data.Element] {
        guard let collapsedLimit else { return Array(data) }
        return isExpanded ? Array(data) : Array(data.prefix(collapsedLimit))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: dividerWidth) {
            ForEach(visibleItems) { item in
                rowContent(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ResortPassDimension.Spacing.medium)
                    .background(ResortPassColor.surfacePrimary)
            }

            if let collapsedLimit, data.count > collapsedLimit {
                expandButton(collapsedLimit: collapsedLimit)
            }
        }
        .background(ResortPassColor.surfaceSecondary)
        .cornerRadius(ResortPassDimension.CornerRadius.medium)
    }

    private func expandButton(collapsedLimit: Int) -> some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: ResortPassDimension.Spacing.xSmall) {
                ResortPassIcon(systemName: "chevron.down", size: .small)
                    .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                    .accessibilityHidden(true)

                Text(isExpanded ? "Show Less" : "Show \(data.count - collapsedLimit) More")
            }
            .font(.subheadline.weight(.regular))
            .foregroundStyle(ResortPassColor.textSecondary)
            .drawingGroup()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ResortPassDimension.Spacing.medium)
            .background(ResortPassColor.surfacePrimary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ExpandableListBoxPreviewItem: Identifiable {
    let id: Int
    let name: String
}

#Preview {
    let items = (1...5).map { ExpandableListBoxPreviewItem(id: $0, name: "Item \($0)") }

    return ExpandableListBox(items, collapsedLimit: 3) { item in
        Text(item.name)
    }
    .padding()
}

#Preview("No collapsing") {
    let items = (1...5).map { ExpandableListBoxPreviewItem(id: $0, name: "Item \($0)") }

    return ExpandableListBox(items, collapsedLimit: nil) { item in
        Text(item.name)
    }
    .padding()
}
