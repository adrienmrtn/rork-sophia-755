import Foundation

/// La rangée de sept jours des cartes de série. Elle ne suit pas la semaine du calendrier :
/// elle part du premier jour de la série, qui occupe la première case, et se remplit vers la
/// droite. Au huitième jour, une nouvelle rangée commence (elle ne glisse pas d'un jour par jour).
enum StreakWeek {
    /// Le jour de la première case.
    /// - Parameters:
    ///   - streak: la série en cours, en jours.
    ///   - lastActive: le dernier jour actif, « yyyy-MM-dd ».
    static func firstDay(streak: Int, lastActive: String?, today: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: today)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard streak > 0, let lastActive, let parsed = formatter.date(from: lastActive) else { return today }
        let last = calendar.startOfDay(for: parsed)
        // Série rompue (dernier jour actif avant hier) ou date dans le futur : on repart d'aujourd'hui.
        let gap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        guard gap >= 0, gap <= 1 else { return today }
        guard let start = calendar.date(byAdding: .day, value: -(streak - 1), to: last) else { return today }
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return calendar.date(byAdding: .day, value: (elapsed / 7) * 7, to: start) ?? today
    }

    /// L'index d'un jour dans les lettres « lundi d'abord » (`mondayFirstWeekdayLetters`).
    static func letterIndex(of date: Date, calendar: Calendar = .current) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }
}
