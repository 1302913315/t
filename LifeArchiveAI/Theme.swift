import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.45, green: 0.57, blue: 0.55)
    static let mint = Color(red: 0.78, green: 0.90, blue: 0.83)
    static let blush = Color(red: 0.95, green: 0.80, blue: 0.84)
    static let lilac = Color(red: 0.83, green: 0.80, blue: 0.94)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let ink = Color(red: 0.18, green: 0.20, blue: 0.22)

    static var background: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var surface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

extension Date {
    var compactDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
