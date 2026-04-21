import SwiftUI

struct SettingsView: View {
    let progressManager: ProgressManager
    let store: StoreViewModel
    var onShowPaywall: (() -> Void)? = nil
    @State private var showResetAlert: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var hapticTrigger: Int = 0

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SophiaTheme.emerald.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(SophiaTheme.emerald)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(progressManager.completedCount) cours terminés")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text("sur \(CourseData.allCourses.count) disponibles")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .listRowBackground(SophiaTheme.cardBackground)

                    if progressManager.streak > 0 {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(SophiaTheme.streakOrange.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Text("🔥")
                                    .font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(progressManager.streak) jours de suite")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Continue comme ça !")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .listRowBackground(SophiaTheme.cardBackground)
                    }
                } header: {
                    Text("Progression")
                        .foregroundStyle(.white.opacity(0.6))
                }

                if !store.isPremium {
                    Section {
                        Button {
                            hapticTrigger += 1
                            onShowPaywall?()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(SophiaTheme.accent.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(SophiaTheme.streakOrange)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Passer à Premium")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text("Cours et quiz illimités")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        .listRowBackground(SophiaTheme.cardBackground)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        hapticTrigger += 1
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Réinitialiser la progression")
                        }
                        .font(.system(.body, design: .rounded))
                    }
                    .listRowBackground(SophiaTheme.cardBackground)
                } header: {
                    Text("Données")
                        .foregroundStyle(.white.opacity(0.6))
                }

                Section {
                    Button {
                        hapticTrigger += 1
                        showTerms = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Conditions générales d'utilisation")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .listRowBackground(SophiaTheme.cardBackground)

                    Button {
                        hapticTrigger += 1
                        showPrivacy = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Politique de confidentialité")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .listRowBackground(SophiaTheme.cardBackground)

                    if !store.isPremium {
                        Button {
                            hapticTrigger += 1
                            Task { await store.restore() }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Restaurer les achats")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        .listRowBackground(SophiaTheme.cardBackground)
                    }
                } header: {
                    Text("Légal")
                        .foregroundStyle(.white.opacity(0.6))
                }

                Section {
                    HStack {
                        Text("Version")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(appVersionString)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(SophiaTheme.cardBackground)

                    HStack {
                        Text("Cours disponibles")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(CourseData.allCourses.count)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(SophiaTheme.cardBackground)
                } header: {
                    Text("À propos")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .scrollContentBackground(.hidden)
            .background(SophiaTheme.background)
            .navigationTitle("Réglages")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .alert("Réinitialiser ?", isPresented: $showResetAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Réinitialiser", role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text("Toute ta progression sera effacée. Cette action est irréversible.")
            }
            .sheet(isPresented: $showTerms) {
                TermsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }
}
