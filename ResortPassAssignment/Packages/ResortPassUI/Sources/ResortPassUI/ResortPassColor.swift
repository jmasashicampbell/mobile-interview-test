//
//  ResortPassColor.swift
//  ResortPassUI
//

import SwiftUI

/// Every color in use across the app — brand accents, backgrounds, and text — named for where
/// or why it's used rather than left as an unexplained literal at the call site.
public enum ResortPassColor {
    public static let primaryAccent = Color(hue: 0.62,
                                            saturation: 0.85,
                                            brightness: 0.4)
    public static let secondaryAccent = Color(hue: 0.62,
                                              saturation: 0.2,
                                              brightness: 0.95)

    public static let rating = Color.yellow

    public static let surfacePrimary = Color(.systemGray6)
    public static let surfaceSecondary = Color(.systemGray5)
    
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textAlwaysWhite = Color.white
    public static let textAlwaysBlack = Color.black
}
