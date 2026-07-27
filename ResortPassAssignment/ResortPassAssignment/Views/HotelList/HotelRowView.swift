//
//  HotelRowView.swift
//  ResortPassAssignment
//
//  Created by Jerome Campbell on 7/24/26.
//

import ResortPassKit
import ResortPassUI
import SwiftUI


struct HotelRowView: View {
    let hotel: Hotel
    let currencyCode: String


    /// Pushes unavailable products to the bottom
    private var sortedProducts: [HotelProduct] {
        (hotel.products ?? []).sorted { lhs, rhs in
            lhs.quantity != 0 && rhs.quantity == 0
        }
    }

    private let collapsedProductLimit = 3
    private let thumbnailAspectRatio: CGFloat = 16 / 9
    private let wideLayoutThumbnailWidth: CGFloat = 220
    private let wideLayoutThumbnailAspectRatio: CGFloat = 4 / 3
    private let wideLayoutNameColumnMaxWidth: CGFloat = 280

    var body: some View {
        ViewThatFits(in: .horizontal) {
            wideLayout
            narrowLayout
        }
        .padding(ResortPassDimension.Spacing.large)
    }

    private var narrowLayout: some View {
        VStack(alignment: .leading, spacing: ResortPassDimension.Spacing.medium) {
            thumbnail(aspectRatio: thumbnailAspectRatio)
            details()
            if !sortedProducts.isEmpty {
                productList
            }
        }
    }

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: ResortPassDimension.Spacing.medium) {
            thumbnail(aspectRatio: wideLayoutThumbnailAspectRatio)
                .frame(width: wideLayoutThumbnailWidth)
            VStack(alignment: .leading, spacing: ResortPassDimension.Spacing.medium) {
                details(nameColumnMaxWidth: wideLayoutNameColumnMaxWidth)
                if !sortedProducts.isEmpty {
                    productList
                }
            }
        }
    }

    private func thumbnail(aspectRatio: CGFloat) -> some View {
        ResortPassImage(url: hotel.pictureURL, aspectRatio: aspectRatio)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: ResortPassDimension.CornerRadius.small))
            .accessibilityHidden(true)
    }

    private func details(nameColumnMaxWidth: CGFloat? = nil) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: ResortPassDimension.Spacing.xSmall) {
                Text(hotel.name)
                    .font(.headline)

                if let locationSubtitle {
                    Text(locationSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(ResortPassColor.textSecondary)
                }
            }
            .frame(maxWidth: nameColumnMaxWidth, alignment: .leading)
            Spacer()

            if let rating = hotel.rating {
                RatingView(rating: rating, reviewCount: hotel.reviews)
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private var productList: some View {
        ExpandableListBox(sortedProducts, collapsedLimit: collapsedProductLimit) { product in
            productRow(for: product)
        }
    }

    private func productRow(for product: HotelProduct) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ResortPassDimension.Spacing.small) {
                productName(for: product)
                Spacer()
                availabilityBadge(for: product)
                productPrice(for: product)
            }

            VStack(alignment: .leading, spacing: ResortPassDimension.Spacing.xSmall) {
                productName(for: product)
                HStack(spacing: ResortPassDimension.Spacing.small) {
                    availabilityBadge(for: product)
                    Spacer()
                    productPrice(for: product)
                }
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func productName(for product: HotelProduct) -> some View {
        Text(product.name)
            .foregroundStyle(productForegroundStyle(for: product))
            .fontWeight(.medium)
    }

    private func productPrice(for product: HotelProduct) -> some View {
        Text(formattedPrice(product.price))
            .foregroundStyle(productForegroundStyle(for: product))
            // A price is a single token; wrapping "$200" across lines would misread badly.
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func productForegroundStyle(for product: HotelProduct) -> Color {
        product.quantity == 0 ? ResortPassColor.textSecondary : ResortPassColor.textPrimary
    }

    @ViewBuilder
    private func availabilityBadge(for product: HotelProduct) -> some View {
        if product.quantity == 0 {
            Text("Unavailable")
                .font(.caption)
                .foregroundStyle(ResortPassColor.textSecondary)
        } else if product.quantity <= 3 {
            BadgeView("Only \(product.quantity) Left")
        }
    }

    private var locationSubtitle: String? {
        switch (hotel.cityName, hotel.stateCode ?? hotel.state) {
        case let (city?, region?):
            return "\(city), \(region)"
        case let (city?, nil):
            return city
        case let (nil, region?):
            return region
        default:
            return nil
        }
    }

    private func formattedPrice(_ price: Double) -> String {
        let hasCents = price.truncatingRemainder(dividingBy: 1) != 0
        return price.formatted(.currency(code: currencyCode).precision(.fractionLength(hasCents ? 2 : 0)))
    }
}

#Preview {
    let json = """
    {
        "objectID": "1990:3227034",
        "name": "TWA Hotel",
        "city_name": "New York",
        "state_code": "NY",
        "rating": 4.1,
        "reviews": 164,
        "products": [
            { "id": 1, "name": "Day Pass", "price": 50.0, "availability": "available", "quantity": 30 },
            { "id": 2, "name": "Cabana", "price": 250.0, "availability": "available", "quantity": 1 },
            { "id": 3, "name": "Pool Chair", "price": 75.0, "availability": "available", "quantity": 0 },
            { "id": 4, "name": "Daybed", "price": 150.0, "availability": "available", "quantity": 3 }
        ]
    }
    """.data(using: .utf8)!
    let hotel = try! JSONDecoder().decode(Hotel.self, from: json)

    return HotelRowView(hotel: hotel, currencyCode: "USD")
}
