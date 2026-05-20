import SwiftUI
import RevenueCatUI

struct ProgressionView: View {
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    let onShowPaywall: () -> Void
    @State private var milestonePulse: Bool = false

    private let subjects: [Subject] = [
        .mythologie,
        .histoire,
        .sciences,
        .litterature,
        .art,
        .comprendreLeMonde,
    ]

    private var freemiumSubjects: Set<String> {
        if store.isPremium { return Set(Subject.allCases.map(\.rawValue)) }
        if let raw = UserDefaults.standard.array(forKey: "sophia_freemium_subjects") as? [String], raw.count == 3 {
            return Set(raw)
        }

        let best3 = bestFreemiumSubjectsFromThemeLevels()
        if best3.count == 3 {
            UserDefaults.standard.set(best3, forKey: "sophia_freemium_subjects")
            return Set(best3)
        }

        let fallback = Array(Subject.allCases.prefix(3)).map(\.rawValue)
        UserDefaults.standard.set(fallback, forKey: "sophia_freemium_subjects")
        return Set(fallback)
    }

    private var isInactiveSinceYesterday: Bool {
        guard let last = progressManager.lastActiveDateString else { return false }
        let today = dateString(Date())
        let yesterday = dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        return last != today && last != yesterday
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SophiaTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        if progressManager.streak > 0 {
                            streakSection
                                .padding(.top, 12)
                        }

                        themeProgressSection

                        quizSection

                        favoritesSection

                        readHistorySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Progression")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var streakSection: some View {
        let streak = progressManager.streak
        let badge: String? = streak >= 30 ? "🏆 Mois de culture" : (streak >= 7 ? "🏅 Semaine parfaite" : nil)

        return VStack(alignment: .leading, spacing: 12) {
            if progressManager.didBreakStreakToday {
                Text("Ta série est brisée. Recommence dès aujourd'hui.")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(SophiaTheme.errorRed.opacity(0.12), in: .rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(SophiaTheme.errorRed.opacity(0.35), lineWidth: 1)
                    )
            }

            HStack(alignment: .firstTextBaseline) {
                Text("\(streak)")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("jours de suite 🔥")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
                if store.isPremium && progressManager.shieldCount > 0 {
                    Text("🛡️")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.streakOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SophiaTheme.streakOrange.opacity(0.12), in: Capsule())
                        .scaleEffect(milestonePulse ? 1.06 : 1.0)
                }
            }

            Text("Reviens demain pour continuer")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            if store.isPremium && progressManager.didUseShieldToday, let value = progressManager.shieldProtectedStreakValue {
                Text("Ton bouclier a protégé ta série de \(value) jours")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(16)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            if streak == 7 || streak == 30 {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    milestonePulse = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private var themeProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progression thèmes")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if isInactiveSinceYesterday {
                Text("⚠️ Ta progression diminue si tu ne reviens pas demain")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }

            VStack(spacing: 10) {
                ForEach(subjects, id: \.self) { subject in
                    ThemeProgressRow(
                        subject: subject,
                        isLocked: !freemiumSubjects.contains(subject.rawValue),
                        points: progressManager.themePoints(for: subject),
                        completedCourses: completedCoursesCount(for: subject)
                    )
                }
            }

            if !store.isPremium {
                Text("Débloque avec l'essai gratuit")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            NavigationLink {
                MyQuizzesView(
                    progressManager: progressManager,
                    store: store,
                    selectedCourse: $selectedCourse,
                    onShowPaywall: onShowPaywall
                )
            } label: {
                HStack(spacing: 10) {
                    Text("📖 Voir les quiz des cours que j'ai lus →")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favoris")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if progressManager.favoriteCourses.isEmpty {
                Text("Appuie sur ❤️ sur un cours pour le retrouver ici")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(progressManager.favoriteCourses) { course in
                        Button {
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                            selectedCourse = course
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(course.subject.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: course.subject.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(course.subject.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.title)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text("\(course.subject.shortName) • 10 min")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "play.fill")
                                    .font(.system(.subheadline, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(SophiaTheme.emerald, in: Circle())
                            }
                            .padding(14)
                            .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var readHistorySection: some View {
        let completed = completedCoursesSorted()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Cours lus")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if completed.isEmpty {
                Text("Aucun cours lu pour l'instant.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(completed) { course in
                        Button {
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                            selectedCourse = course
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(course.subject.color.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: course.subject.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(course.subject.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.title)
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    let dateText = displayDate(progressManager.completionDateString(for: course.id))
                                    Text("\(course.subject.shortName) • \(dateText)")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(.title3, weight: .bold))
                                    .foregroundStyle(SophiaTheme.emerald)
                            }
                            .padding(14)
                            .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func completedCoursesCount(for subject: Subject) -> Int {
        CourseData.allCourses
            .filter { $0.subject == subject }
            .filter { progressManager.courseStatus(for: $0.id) == .completed }
            .count
    }

    private func completedCoursesSorted() -> [Course] {
        CourseData.allCourses
            .filter { progressManager.courseStatus(for: $0.id) == .completed }
            .sorted { (a, b) in
                let da = progressManager.completionDateString(for: a.id) ?? ""
                let db = progressManager.completionDateString(for: b.id) ?? ""
                if da != db { return da > db }
                return a.title < b.title
            }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func bestFreemiumSubjectsFromThemeLevels() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "sophia_theme_levels"),
              let decodedAny = (try? JSONDecoder().decode([String: Double].self, from: data)) ?? (try? JSONDecoder().decode([String: Int].self, from: data).mapValues { v in
                  switch max(0, min(2, v)) {
                  case 0: 0.15
                  case 1: 0.50
                  default: 0.85
                  }
              }) else { return [] }

        let order = Subject.allCases
        let ranked = order
            .map { subject in
                (subject: subject, value: decodedAny[subject.rawValue] ?? 0)
            }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return order.firstIndex(of: lhs.subject) ?? 0 < order.firstIndex(of: rhs.subject) ?? 0
            }

        return Array(ranked.prefix(3)).map(\.subject.rawValue)
    }

    private func displayDate(_ stored: String?) -> String {
        guard let stored, !stored.isEmpty else { return "—" }
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        guard let d = inF.date(from: stored) else { return stored }
        let outF = DateFormatter()
        outF.locale = Locale(identifier: "fr_FR")
        outF.dateFormat = "d MMM"
        return outF.string(from: d)
    }
}

private struct ThemeProgressRow: View {
    let subject: Subject
    let isLocked: Bool
    let points: Int
    let completedCourses: Int

    private var level: String {
        levelForPoints(points)
    }

    private var fraction: CGFloat {
        progressFraction(points: points)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(subject.color.opacity(0.22))
                        .frame(width: 28, height: 28)
                    Image(systemName: subject.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subject.color)
                }

                Text(subject.shortName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                } else {
                    Text(level)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(subject.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(subject.color.opacity(0.15), in: Capsule())
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: 8)
                    Capsule()
                        .fill(isLocked ? .white.opacity(0.10) : subject.color)
                        .frame(width: geo.size.width * (isLocked ? 0.25 : fraction), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(completedCourses) cours")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
        }
        .padding(12)
        .background(.white.opacity(isLocked ? 0.03 : 0.05), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(isLocked ? 0.55 : 1.0)
    }

    private func levelForPoints(_ points: Int) -> String {
        switch points {
        case 0...4: "Débutant"
        case 5...14: "Initié"
        case 15...29: "Érudit"
        case 30...49: "Expert"
        default: "Sage"
        }
    }

    private func progressFraction(points: Int) -> CGFloat {
        let (minP, maxP) = levelBounds(points)
        if maxP == minP { return 1 }
        let clamped = max(minP, min(points, maxP))
        return CGFloat(Double(clamped - minP) / Double(maxP - minP))
    }

    private func levelBounds(_ points: Int) -> (Int, Int) {
        switch points {
        case 0...4: (0, 4)
        case 5...14: (5, 14)
        case 15...29: (15, 29)
        case 30...49: (30, 49)
        default: (50, 60)
        }
    }
}

private struct MyQuizzesView: View {
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    let onShowPaywall: () -> Void
    @State private var selectedQuizCourse: Course? = nil

    private var completedCoursesWithQuiz: [Course] {
        CourseData.allCourses
            .filter { progressManager.courseStatus(for: $0.id) == .completed }
            .filter { $0.hasQuiz }
            .sorted { (a, b) in
                let da = progressManager.completionDateString(for: a.id) ?? ""
                let db = progressManager.completionDateString(for: b.id) ?? ""
                if da != db { return da > db }
                return a.title < b.title
            }
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mes quiz")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Teste ce que tu as retenu sur chaque cours")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 12)

                    if !store.isPremium {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🔒 Les quiz sont disponibles avec l'essai gratuit — 3 jours offerts")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))

                            Button {
                                let g = UIImpactFeedbackGenerator(style: .medium)
                                g.impactOccurred()
                                onShowPaywall()
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Débloquer mes quiz →")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                    Spacer()
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(SophiaTheme.emerald, in: .rect(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(.white.opacity(0.05), in: .rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                    }

                    VStack(spacing: 10) {
                        ForEach(completedCoursesWithQuiz) { course in
                            quizRow(course)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedQuizCourse) { course in
            QuizView(
                course: course,
                progressManager: progressManager,
                isPremium: store.isPremium,
                onReturnHome: {
                    selectedQuizCourse = nil
                }
            )
        }
    }

    private func quizRow(_ course: Course) -> some View {
        let dateText = displayDate(progressManager.completionDateString(for: course.id))
        let score = progressManager.bestScore(for: course.id) ?? 0

        return Button {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
            if store.isPremium {
                selectedQuizCourse = course
            } else {
                onShowPaywall()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(course.subject.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: course.subject.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(course.subject.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(course.subject.shortName) • \(dateText)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                if store.isPremium {
                    if score >= 1 {
                        Text("\(score)/\(course.quiz.count)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.emerald)
                    } else {
                        Text("Faire le quiz →")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(SophiaTheme.emerald, in: Capsule())
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(14)
            .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .opacity(store.isPremium ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    private func displayDate(_ stored: String?) -> String {
        guard let stored, !stored.isEmpty else { return "—" }
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        guard let d = inF.date(from: stored) else { return stored }
        let outF = DateFormatter()
        outF.locale = Locale(identifier: "fr_FR")
        outF.dateFormat = "d MMM"
        return outF.string(from: d)
    }
}
