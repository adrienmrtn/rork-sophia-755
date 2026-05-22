import SwiftUI

struct SettingsView: View {
    let progressManager: ProgressManager
    let store: StoreViewModel
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil
    @State private var showResetAlert: Bool = false
    @State private var showResetOnboardingAlert: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var hapticTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Options")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        // Progression
                        sectionHeader("Progression")
                        VStack(spacing: 0) {
                            statRow(
                                icon: "trophy.fill",
                                iconBg: BrutalPalette.pastel(for: .histoire),
                                title: "\(progressManager.completedCount) cours terminés",
                                subtitle: "sur \(CourseData.allCourses.count) disponibles"
                            )
                            if progressManager.streak > 0 {
                                divider
                                statRow(
                                    icon: "flame.fill",
                                    iconBg: BrutalPalette.pink,
                                    title: "\(progressManager.streak) jours de suite",
                                    subtitle: "Continue comme ça !"
                                )
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // Premium
                        if !store.isPremium {
                            sectionHeader("Premium")
                            Button {
                                hapticTrigger += 1
                                onShowPaywall?()
                            } label: {
                                HStack(spacing: 14) {
                                    iconBadge(name: "crown.fill", bg: Color(red: 1.0, green: 0.86, blue: 0.4))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Passer à Premium")
                                            .font(.system(.headline, design: .rounded, weight: .heavy))
                                            .foregroundStyle(ink)
                                        Text("Cours et quiz illimités")
                                            .font(.system(.caption, design: .rounded, weight: .semibold))
                                            .foregroundStyle(ink.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(ink)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(BrutalCardButtonStyle(depth: 2))
                            .brutalCard()
                            .padding(.horizontal, 20)
                        }

                        // Data
                        sectionHeader("Données")
                        VStack(spacing: 0) {
                            actionRow(
                                icon: "arrow.counterclockwise",
                                iconBg: Color(red: 1.0, green: 0.78, blue: 0.78),
                                title: "Réinitialiser la progression",
                                destructive: true
                            ) {
                                hapticTrigger += 1
                                showResetAlert = true
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // Legal
                        sectionHeader("Légal")
                        VStack(spacing: 0) {
                            actionRow(
                                icon: "doc.text.fill",
                                iconBg: BrutalPalette.pastel(for: .art),
                                title: "Conditions générales"
                            ) {
                                hapticTrigger += 1
                                showTerms = true
                            }
                            divider
                            actionRow(
                                icon: "hand.raised.fill",
                                iconBg: BrutalPalette.pastel(for: .mythologie),
                                title: "Politique de confidentialité"
                            ) {
                                hapticTrigger += 1
                                showPrivacy = true
                            }
                            if !store.isPremium {
                                divider
                                actionRow(
                                    icon: "arrow.clockwise",
                                    iconBg: BrutalPalette.pastel(for: .sciences),
                                    title: "Restaurer les achats"
                                ) {
                                    hapticTrigger += 1
                                    Task { await store.restore() }
                                }
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // About
                        sectionHeader("À propos")
                        VStack(spacing: 0) {
                            infoRow(label: "Version", value: appVersionString)
                            divider
                            infoRow(label: "Cours disponibles", value: "\(CourseData.allCourses.count)")
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        #if DEBUG
                        if onResetOnboarding != nil {
                            sectionHeader("Développeur")
                            VStack(spacing: 0) {
                                actionRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    iconBg: Color(red: 1.0, green: 0.78, blue: 0.78),
                                    title: "Refaire l'onboarding"
                                ) {
                                    hapticTrigger += 1
                                    showResetOnboardingAlert = true
                                }
                            }
                            .brutalCard()
                            .padding(.horizontal, 20)
                        }
                        #endif

                        Text("Made with ♥ — Sophia")
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .alert("Réinitialiser ?", isPresented: $showResetAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Réinitialiser", role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text("Toute ta progression sera effacée. Cette action est irréversible.")
            }
            .alert("Refaire l'onboarding ?", isPresented: $showResetOnboardingAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Relancer", role: .destructive) {
                    onResetOnboarding?()
                }
            } message: {
                Text("L'onboarding sera relancé depuis le début (DEBUG uniquement).")
            }
            .sheet(isPresented: $showTerms) {
                TermsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.55))
            .tracking(1.2)
            .padding(.horizontal, 28)
    }

    private var divider: some View {
        Rectangle()
            .fill(ink)
            .frame(height: 2)
    }

    private func iconBadge(name: String, bg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bg)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2)
                }
            Image(systemName: name)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(ink)
        }
        .frame(width: 40, height: 40)
    }

    private func statRow(icon: String, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(name: icon, bg: iconBg)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func actionRow(
        icon: String,
        iconBg: Color,
        title: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(name: icon, bg: iconBg)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(destructive ? Color(red: 0.85, green: 0.1, blue: 0.2) : ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

/// Brutalist card modifier: white background, black border, solid black offset shadow.
private struct BrutalCardModifier: ViewModifier {
    let ink = BrutalPalette.ink
    let depth: CGFloat = 4

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            content
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2.5)
                }
        }
        .padding(.bottom, depth)
    }
}

private extension View {
    func brutalCard() -> some View {
        modifier(BrutalCardModifier())
    }
}
