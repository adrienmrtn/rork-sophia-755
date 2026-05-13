import SwiftUI

struct OnboardingCuriosityQuestionsScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var selectedIndex: Int = 0

    private let questions = [
        "Sais-tu pourquoi la Joconde est vraiment connue ?",
        "Saurais-tu expliquer pourquoi l'Empire Romain a chuté ?",
        "Savais-tu que le micro-ondes a été découvert car une barre chocolatée avait fondu devant un radar militaire ?",
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    SophiaTheme.accent.opacity(0.14),
                    .clear,
                    SophiaTheme.emerald.opacity(0.14),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image("logo_white")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 22)
                            .opacity(appeared ? 0.9 : 0)
                            .offset(y: appeared ? 0 : 10)

                        Text("Ta curiosité va exploser")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Chaque jour, Sophia te donne une réponse claire,\navec une histoire qui se retient.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    TabView(selection: $selectedIndex) {
                        questionCard(icon: "sparkles", title: "Question du jour", text: questions[0], tint: SophiaTheme.emerald)
                            .tag(0)
                        questionCard(icon: "book.closed.fill", title: "Culture générale", text: questions[1], tint: SophiaTheme.accent)
                            .tag(1)
                        questionCard(icon: "bolt.fill", title: "Anecdote", text: questions[2], tint: SophiaTheme.streakOrange)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 210)
                    .padding(.horizontal, 18)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .overlay(alignment: .bottomTrailing) {
                        pageDots(current: selectedIndex, total: 3)
                            .padding(.trailing, 18)
                            .padding(.bottom, 14)
                            .opacity(appeared ? 1 : 0)
                    }
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 26)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }

    private func pageDots(current: Int, total: Int) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? .white.opacity(0.85) : .white.opacity(0.28))
                    .frame(width: i == current ? 16 : 7, height: 7)
                    .animation(.spring(response: 0.25), value: current)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.20), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func questionCard(icon: String, title: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }

            Text(text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text("2 minutes pour comprendre")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(0.20),
                    .white.opacity(0.06),
                    .black.opacity(0.02),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .padding(.vertical, 6)
    }
}
