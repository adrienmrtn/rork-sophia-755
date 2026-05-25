import SwiftUI

/// Shared neo-brutalist building blocks for the Onboarding flow.
/// Reuses `BrutalPalette` (defined in LibraryView) for cream / ink / pink.

// MARK: - Card modifier (white bg, black border, solid offset shadow)

struct BrutalOnboardingCard: ViewModifier {
    var depth: CGFloat = 4
    var corner: CGFloat = 18
    var borderWidth: CGFloat = 2.5

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(BrutalPalette.ink)
                .offset(y: depth)

            content
                .background(Color.white)
                .clipShape(.rect(cornerRadius: corner))
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: borderWidth)
                }
        }
        .padding(.bottom, depth)
    }
}

extension View {
    func brutalOnboardingCard(depth: CGFloat = 4, corner: CGFloat = 18, borderWidth: CGFloat = 2.5) -> some View {
        modifier(BrutalOnboardingCard(depth: depth, corner: corner, borderWidth: borderWidth))
    }
}

// MARK: - Duolingo-style 3D pink capsule button

struct BrutalPinkButtonStyle: ButtonStyle {
    var depth: CGFloat = 6
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(BrutalPalette.ink)
                        .offset(y: depth)
                    Capsule()
                        .fill(isEnabled ? BrutalPalette.pink : Color(red: 0.92, green: 0.88, blue: 0.85))
                        .overlay {
                            Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                        .offset(y: pressed ? depth : 0)
                }
            )
            .padding(.bottom, depth)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    @State private var tapCount: Int = 0

    var body: some View {
        Button {
            tapCount += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.heavy))
            }
            .foregroundStyle(isEnabled ? BrutalPalette.ink : BrutalPalette.ink.opacity(0.4))
        }
        .buttonStyle(BrutalPinkButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
    }
}

// MARK: - Selectable option row (used by phone time, age, objectives)

struct BrutalSelectableRow: View {
    let icon: String?
    let label: String
    let isSelected: Bool
    var accentColor: Color = BrutalPalette.pink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? accentColor : Color(red: 0.96, green: 0.93, blue: 0.88))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                            }
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                    }
                    .frame(width: 38, height: 38)
                }
                Text(label)
                    .font(.system(.body, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle()
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(BrutalPalette.ink)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .buttonStyle(BrutalRowButtonStyle(isSelected: isSelected, accentColor: accentColor))
    }
}

/// Row button style: white card by default, pastel-tinted when selected, with solid offset shadow that compresses on press.
struct BrutalRowButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var accentColor: Color = BrutalPalette.pink
    var depth: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background(
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BrutalPalette.ink)
                        .offset(y: depth)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? accentColor.opacity(0.35) : Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                        .offset(y: pressed ? depth : 0)
                }
            )
            .padding(.bottom, depth)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}

// MARK: - Pill tag (black uppercase tag)

struct BrutalPill: View {
    let text: String
    var icon: String? = nil
    var background: Color = BrutalPalette.ink
    var foreground: Color = .white

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .heavy))
            }
            Text(text.uppercased())
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(0.8)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background, in: .capsule)
        .overlay {
            Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2)
        }
    }
}

// MARK: - Section header (title + subtitle)

struct OnboardingHeader: View {
    let title: String
    var subtitle: String? = nil
    var appeared: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Convenience pastels per index

enum OnboardingPastels {
    static let all: [Color] = [
        Color(red: 1.0, green: 0.86, blue: 0.62),  // peach (histoire)
        Color(red: 0.70, green: 0.95, blue: 0.80), // mint (sciences)
        Color(red: 1.0, green: 0.78, blue: 0.78),  // soft red (litt)
        Color(red: 0.66, green: 0.92, blue: 0.96), // cyan (art)
        Color(red: 0.82, green: 0.78, blue: 1.0),  // lavande (mytho)
        Color(red: 0.74, green: 0.90, blue: 1.0),  // sky (monde)
    ]

    static func at(_ index: Int) -> Color {
        all[abs(index) % all.count]
    }
}
