import SwiftUI

enum WidgetSubjectStyle {
    static func pastel(for subjectKey: String) -> Color {
        switch subjectKey {
        case "histoire":
            return Color(red: 1.0, green: 0.86, blue: 0.62)
        case "sciences":
            return Color(red: 0.70, green: 0.95, blue: 0.80)
        case "litterature":
            return Color(red: 1.0, green: 0.78, blue: 0.78)
        case "art":
            return Color(red: 0.66, green: 0.92, blue: 0.96)
        case "mythologie":
            return Color(red: 0.82, green: 0.78, blue: 1.0)
        case "comprendreLeMonde":
            return Color(red: 0.74, green: 0.90, blue: 1.0)
        default:
            return Color(red: 0.98, green: 0.96, blue: 0.92)
        }
    }

    static let ink = Color.black
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let pink = Color(red: 0.996, green: 0.588, blue: 0.737)
}
