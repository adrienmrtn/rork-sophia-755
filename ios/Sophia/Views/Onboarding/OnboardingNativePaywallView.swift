import SwiftUI

struct OnboardingNativePaywallView: View {
    enum Plan: String, CaseIterable, Identifiable {
        case yearly
        case monthly
        var id: String { rawValue }
    }

    var store: StoreViewModel
    let onPurchase: (Plan) -> Void
    let onRestore: () -> Void
    let onClose: () -> Void

    @State private var selectedPlan: Plan = .yearly
    @State private var showReminderSheet: Bool = false
    @State private var subjectPaywallContext: SophiaPaywallContext?

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: false)
    }

    private var lockedSubjects: [Subject] {
        Subject.allCases.filter { !unlockedSubjects.contains($0) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                            .padding(.top, 8)

                        subjectsBlock
                            .padding(.horizontal, 24)

                        featureComparison
                            .padding(.horizontal, 24)

                        VStack(spacing: 14) {
                            planCard(.yearly)
                            planCard(.monthly)
                        }
                        .padding(.horizontal, 24)

                        socialProof
                            .padding(.horizontal, 24)

                        restoreRow
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 12)
                }

                VStack(spacing: 8) {
                    Text("Annule à tout moment, sans frais.")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.5))

                    OnboardingPrimaryButton(title: store.isPurchasing ? "Traitement…" : "Continuer") {
                        guard !store.isPurchasing else { return }
                        OnboardingHaptics.primaryCTA()
                        showReminderSheet = true
                    }
                    .disabled(store.isPurchasing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
        .sheet(isPresented: $showReminderSheet) {
            TrialTimelineSheet(
                onContinue: {
                    showReminderSheet = false
                    onPurchase(selectedPlan)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(item: $subjectPaywallContext) { context in
            SophiaPaywallView(
                context: context,
                onDismissed: { subjectPaywallContext = nil }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deviens la personne\nla plus intéressante\nde la pièce.")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            HStack {
                Spacer()
                Text("📚")
                    .font(.system(size: 64))
                    .rotationEffect(.degrees(12))
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Subjects

    private var subjectsBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tes 3 matières gratuites")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                FlowLayout(spacing: 8) {
                    ForEach(Array(unlockedSubjects).sorted(by: { $0.shortName < $1.shortName }), id: \.self) { subject in
                        subjectPill(subject, locked: false)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("3 matières à débloquer")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                FlowLayout(spacing: 8) {
                    ForEach(lockedSubjects, id: \.self) { subject in
                        subjectPill(subject, locked: true)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brutalOnboardingCard(depth: 4, corner: 20)
    }

    @ViewBuilder
    private func subjectPill(_ subject: Subject, locked: Bool) -> some View {
        if locked {
            Button {
                OnboardingHaptics.primaryCTA()
                subjectPaywallContext = .matiereBlock(for: subject)
            } label: {
                subjectPillContent(subject: subject, locked: true)
            }
            .buttonStyle(.plain)
        } else {
            subjectPillContent(subject: subject, locked: false)
        }
    }

    private func subjectPillContent(subject: Subject, locked: Bool) -> some View {
        HStack(spacing: 6) {
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .frame(width: 16)
            } else {
                Text(subject.emoji)
                    .font(.system(size: 16))
                    .frame(width: 16)
            }
            Text(subject.shortName)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .lineLimit(1)
        }
        .foregroundStyle(locked ? BrutalPalette.ink.opacity(0.45) : BrutalPalette.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 36)
        .background(locked ? Color(white: 0.94) : BrutalPalette.pastel(for: subject), in: Capsule())
        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
    }

    // MARK: - Feature comparison

    private var featureComparison: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Fonctionnalité")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                Spacer()
                Text("Gratuit")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                    .frame(width: 56)
                Text("Premium")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(width: 72)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(BrutalPalette.ink.opacity(0.15))

            featureRow("3 matières", free: true, premium: true)
            featureRow("Toutes les matières", free: false, premium: true)
            featureRow("Cours illimités", free: false, premium: true)
            featureRow("Mini Quiz", free: false, premium: true)
            featureRow("Bibliothèque complète", free: false, premium: true)
        }
        .brutalOnboardingCard(depth: 3, corner: 18)
    }

    private func featureRow(_ title: String, free: Bool, premium: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink)
            Spacer()
            featureCheck(free).frame(width: 56)
            featureCheck(premium).frame(width: 72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func featureCheck(_ on: Bool) -> some View {
        Group {
            if on {
                ZStack {
                    Circle().fill(BrutalPalette.yellow).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }
            } else {
                Text("—")
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.25))
            }
        }
    }

    // MARK: - Plan card

    @ViewBuilder
    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let tint: Color = isYearly ? OnboardingPastels.at(3) : OnboardingPastels.at(1)

        Button {
            OnboardingHaptics.planSelected()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: 0) {
                if isYearly {
                    Text("Essai gratuit 3 jours")
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(BrutalPalette.yellow)
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                            .frame(width: 26, height: 26)
                        if isSelected {
                            Circle()
                                .fill(BrutalPalette.yellow)
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(BrutalPalette.ink)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isYearly ? "Annuel" : "Mensuel")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                        Text(isYearly ? "3,33 € / mois" : "Sans engagement")
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(isYearly ? "39,99 €" : "9,99 €")
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                        Text(isYearly ? "/ an" : "/ mois")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                    }

                    if isYearly {
                        Text("-58%")
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(BrutalPalette.ink, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .buttonStyle(BrutalRowButtonStyle(isSelected: isSelected, accentColor: tint))
    }

    // MARK: - Social proof

    private var socialProof: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(BrutalPalette.yellow)
                }
            }
            Text("\"Parfait dans les transports. J'apprends chaque jour sans effort.\"")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .brutalOnboardingCard(depth: 3, corner: 18)
    }

    private var restoreRow: some View {
        Button {
            OnboardingHaptics.selection()
            onRestore()
        } label: {
            Text("Restaurer · Conditions · Confidentialité")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.55))
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            OnboardingHaptics.selection()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(BrutalPalette.ink)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
        }
        .accessibilityLabel("Fermer")
    }
}

// MARK: - Trial timeline sheet (GenK-inspired)

private struct TrialTimelineSheet: View {
    let onContinue: () -> Void

    private let steps: [(icon: String, title: String, subtitle: String, detail: String)] = [
        ("lock.open.fill", "Aujourd'hui", "Aucun paiement", "Accès à toutes les fonctionnalités Premium."),
        ("bell.fill", "Dans 2 jours", "On te prévient", "Notification 1 jour avant la fin de l'essai."),
        ("star.fill", "Dans 3 jours", "Ton abonnement démarre", "Annule avant si tu ne veux pas continuer."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Commence ton essai\ngratuit de 3 jours")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    TrialTimelineStepRow(
                        icon: step.icon,
                        title: step.title,
                        subtitle: step.subtitle,
                        detail: step.detail,
                        isFirst: index == 0,
                        isLast: index == steps.count - 1
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer(minLength: 0)

            Text("Annule à tout moment, sans frais.")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

            OnboardingPrimaryButton(title: "Commencer l'essai gratuit", action: {
                OnboardingHaptics.primaryCTA()
                onContinue()
            })
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrutalPalette.cream.ignoresSafeArea())
    }
}

private struct TrialTimelineStepRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let detail: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(BrutalPalette.ink.opacity(0.18))
                        .frame(width: 3, height: 10)
                } else {
                    Color.clear.frame(width: 3, height: 10)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BrutalPalette.pink)
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                        }
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                }

                if !isLast {
                    Rectangle()
                        .fill(BrutalPalette.ink.opacity(0.18))
                        .frame(width: 3)
                        .frame(minHeight: 36)
                }
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)

                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))

                Text(detail)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 8)
        }
    }
}

// Simple flow layout for subject pills
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
