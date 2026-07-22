import SwiftUI

struct GlossaryTermSheet: View {
    let entry: GlossaryEntry
    @Environment(\.dismiss) private var dismiss

    @State private var contentHeight: CGFloat = 280

    private let ink = DS.ink
    private let cream = DS.canvas

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DS.hairline)
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(entry.classification.localizedShortLabel(language: AppLanguage.currentPersisted()).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.accentTint, in: Capsule())

                    Spacer()
                }

                Text(entry.displayTerm)
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.explanation)
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background {
            cream
                .ignoresSafeArea()
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: GlossarySheetHeightKey.self, value: geo.size.height)
                    }
                )
        }
        .onPreferenceChange(GlossarySheetHeightKey.self) { height in
            guard height > 0 else { return }
            contentHeight = min(max(height, 180), UIScreen.main.bounds.height * 0.82)
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(cream)
    }
}

private struct GlossarySheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// In-app glossary explanation rendered as an **overlay inside the course** rather than a
/// system `.sheet`. A system sheet presented over the full-screen course makes the whole
/// course scale/inset back (the card-stacking effect) — which visually "moves the text".
/// Drawing the explanation in the course's own `ZStack` keeps the course text perfectly
/// still: tapping a term just shows the explanation, nothing shifts, no course-text animation.
struct GlossaryTermOverlay: View {
    let entry: GlossaryEntry
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0
    /// Pilote l'animation d'entrée/sortie (fond en fondu, carte qui monte du bas comme un
    /// sheet). L'overlay anime lui-même sa présentation : la vue appelante n'a rien à faire.
    @State private var presented = false
    @State private var leaving = false

    private let ink = DS.ink
    private let cream = DS.canvas

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(presented ? 0.28 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            GeometryReader { geo in
                VStack {
                    Spacer(minLength: 0)
                    card
                        .offset(y: presented ? max(0, dragOffset) : geo.size.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in dragOffset = value.translation.height }
                                .onEnded { value in
                                    if value.translation.height > 90 {
                                        dismiss()
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) { presented = true }
        }
    }

    /// Anime la fermeture (carte qui redescend + fond qui s'efface) avant de retirer l'overlay.
    private func dismiss() {
        guard !leaving else { return }
        leaving = true
        withAnimation(.easeIn(duration: 0.22)) { presented = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { onDismiss() }
    }

    private var card: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DS.hairline)
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(entry.classification.localizedShortLabel(language: AppLanguage.currentPersisted()).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.accentTint, in: Capsule())
                    Spacer()
                }

                Text(entry.displayTerm)
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.explanation)
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            )
            .fill(cream)
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            )
            .strokeBorder(DS.hairline, lineWidth: 1)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
