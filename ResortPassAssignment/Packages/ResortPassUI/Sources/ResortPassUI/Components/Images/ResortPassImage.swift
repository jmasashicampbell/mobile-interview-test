//
//  ResortPassImage.swift
//  ResortPassUI
//

import SwiftUI

/// A drop-in replacement for `AsyncImage` that caches decoded images in memory, so a row that
/// scrolls off/back onscreen (e.g. inside a `LazyVStack`) doesn't refetch or redecode a thumbnail
/// it already loaded this session.
///
/// Pass `aspectRatio` when the image needs to fill a fixed-ratio box (the common case in a list
/// row) — the view then manages its own sizing via `GeometryReader` so the loaded image's own
/// aspect ratio can never feed back into the container's size, and the content fills that box.
/// Omit it to get a plain resizable image with no other opinions baked in: size and shape it with
/// ordinary modifiers (`.frame`, `.aspectRatio`, `.clipShape`, …) at the call site, exactly as
/// you would a regular `Image` with `.resizable()` applied.
public struct ResortPassImage: View {
    private let url: URL?
    private let aspectRatio: CGFloat?

    public init(url: URL?, aspectRatio: CGFloat? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        if let aspectRatio {
            GeometryReader { proxy in
                AsyncCachedImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholder
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            AsyncCachedImage(url: url) { image in
                image
                    .resizable()
            } placeholder: {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(.quaternary)
    }
}


struct AsyncCachedImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let cache: ImageCache
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    init(
        url: URL?,
        cache: ImageCache = .shared,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.cache = cache
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            uiImage = nil
            guard let url else { return }
            uiImage = await cache.image(for: url)
        }
    }
}

#Preview("Placeholder") {
    ResortPassImage(url: nil, aspectRatio: 16 / 9)
        .frame(width: 300)
        .padding()
}

#Preview("Loaded (needs network)") {
    ResortPassImage(
        url: URL(string: "https://assets-staging.resortpass.dev/uploads/image/picture/35445/results_TWA_pool7.jpg"),
        aspectRatio: 16 / 9
    )
    .frame(width: 300)
    .padding()
}
