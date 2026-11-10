import SwiftUI
import UIKit

/// Sélecteur du mode de lecture des cours (pas à pas / par pages) dans Réglages, sur le modèle
/// du sélecteur d'apparence. Le choix vaut pour tous les cours ; un lecteur déjà ouvert propose
/// le même choix dans son en-tête.
struct ReadingModePickerControl: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var mode: CourseReadingMode = CourseReadingMode.current

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(CourseReadingMode.allCases) { option in
                    let selected = mode == option
                    Button {
                        guard option != mode else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        CourseReadingMode.current = option
                        withAnimation(.easeInOut(duration: 0.2)) { mode = option }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.systemImage)
                                .font(.jakarta(size: 16, weight: .semibold))
                            Text(languageManager.text(option.titleKey))
                                .font(DS.sans(.caption, .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(selected ? DS.ink : DS.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? DS.surface : Color.clear)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? DS.hairline : Color.clear, lineWidth: 1)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                    .accessibilityLabel(languageManager.text(option.titleKey))
                }
            }
            .padding(4)
            .background(DS.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(languageManager.text("course.readingMode"))

            Text(languageManager.text(mode.hintKey))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}
