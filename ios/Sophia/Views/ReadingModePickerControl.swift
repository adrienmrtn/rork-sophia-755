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
                        Haptics.select()
                        CourseReadingMode.current = option
                        withAnimation(DS.Motion.snappy) { mode = option }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                            Text(languageManager.text(option.titleKey))
                                .font(DS.sans(.caption, selected ? .bold : .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(selected ? DS.accent : DS.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selected ? DS.accentTint : Color.clear)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(selected ? DS.accent : Color.clear, lineWidth: 1.5)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PressableStyle(haptic: false))
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                    .accessibilityLabel(languageManager.text(option.titleKey))
                }
            }
            .padding(4)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1.5)
            }
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
