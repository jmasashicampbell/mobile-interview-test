# ResortPass iOS

## Run

Open `ResortPassAssignment/ResortPassAssignment.xcworkspace` and run. Opening by the workspace matters for some of the tests.

## Architecture

The app uses a MVVM architecture with separated views, view models, models, and services.

### Module Structure
The code is divided into three modules:
* ResortPassAssignment: Main app with views and assets
* ResortPassKit: Data models and services for interfacing with the ResortPass API
* ResortPassUI: UI constants and reusable components

Splitting out the targets helps enforce layer separation and speeds up building for module tests. 


## State Management

Each screen has an `ObservableObject` view model isolated to `@MainActor`, publishing its state and exposing methods for the things a user can do. Load phases are modelled by a single `LoadingState` enum with `idle`, `loading`, `loaded` and `failed` cases, and each screen switches over it to decide what to render. The hotel list carries two of these enums, one per page phase, which is what lets a failed second page coexist with a successfully loaded first one.

## Networking & API Layer

The services use `URLSession` and `async`/`await` directly. I implemented a `ResortPassService` parent class which handles the API URL and URLSession injection. Each endpoint gets a service that is a subclass of `ResortPassService`.

I added a `LossyArray` struct to ensure a malformed array item doesn't prevent the whole array from decoding. It decodes element by element and keeps whatever parses. To maintain visibility for malformed responses, dropped elements are logged.

## Image Caching
I implemented image caching with a NSCache-based solution. Third-party solutions would provide more features, such as disk caching and image downscaling. For this app, a 100MB cache in memory is large enough to fit more results-sized images than a user is likely to see in a session, so disk caching is not necessary. Since the API already provides a custom image size for search results, image downscaling is not needed either. However, if the app were to display the images at full resolution, these features may be useful.

## Design System

ResortPassUI holds the constants and the reusable components. 
* `ResortPassDimension` defines spacing and corner radii, which are consistent with each other on the same scale.
* `ResortPassColor` defines semantic colors that resolve through system colors so light and dark mode come for free, except for the accent colors which work well as-is in light and dark mode.
* Instead of typography tokens, I used SwiftUI's built-in text styles since they carry semantic meaning, scale correctly under Dynamic Type, and stay consistent with the rest of the platform. In a full app with a custom font, typography tokens would be a good solution.
* Reusable components:
    * `InformationView`: a large icon with a title, an optional message and optional actions, which covers the idle, empty and error states on both screens.
    * `ExpandableListBox`: a rounded, grouped list container that collapses everything past a given number of rows behind a show more control. The hotel rows use it for a hotel's products. (Please pay attention to the animations, I spent a bit too much time on them!)
    * `RatingView`: a star, a score and an optional review count. This would be good for a future hotel detail view.
    * `BadgeView`: a small pill for short status text. In the hotel list view, it's used to call out how few of a product are left.
    * `ResortPassButton`: the app's standard filled button, used for the retry actions on both screens. In a more full-featured app, I'd add more button sizes and styles.
    * `ResortPassImage`: a drop-in replacement for `AsyncImage` that reads through the image cache, and optionally manages its own sizing so a loaded image's aspect ratio can't feed back into the layout.
    * `ResortPassIcon`: an icon at one of three sizes, from either SF Symbols or the app's asset catalog. It handles recoloring and Dynamic Type scaling.

