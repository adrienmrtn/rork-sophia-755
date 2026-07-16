import SwiftUI

struct AmbassadorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    @State private var wantsSlideshow = false
    @State private var wantsUGC = false
    @State private var email = ""
    @State private var ageText = ""
    @State private var presentation = ""
    @State private var countryConfirmed = false
    @State private var isSubmitting = false
    @State private var didSucceed = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case age
        case presentation
    }

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream
    private let presentationLimit = 1_500

    private var parsedAge: Int? {
        Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPresentation: String {
        presentation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        guard !isSubmitting else { return false }
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else { return false }
        guard let age = parsedAge, age >= 16, age <= 120 else { return false }
        guard trimmedPresentation.count >= 10 else { return false }
        guard wantsSlideshow || wantsUGC else { return false }
        guard countryConfirmed else { return false }
        return true
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                LegalHeader(
                    title: languageManager.text("ambassador.title"),
                    onClose: { dismiss() }
                )

                if didSucceed {
                    successView
                } else {
                    formScroll
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var formScroll: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(languageManager.text("ambassador.intro"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    premiumBonusBadge

                    roleCard(
                        title: languageManager.text("ambassador.role.slideshow.title"),
                        income: languageManager.text("ambassador.role.slideshow.income"),
                        time: languageManager.text("ambassador.role.slideshow.time"),
                        body: languageManager.text("ambassador.role.slideshow.body"),
                        accent: BrutalPalette.yellow
                    )

                    roleCard(
                        title: languageManager.text("ambassador.role.ugc.title"),
                        income: languageManager.text("ambassador.role.ugc.income"),
                        time: languageManager.text("ambassador.role.ugc.time"),
                        body: languageManager.text("ambassador.role.ugc.body"),
                        accent: BrutalPalette.pink
                    )

                    conditionsBlock

                    Text(languageManager.text("ambassador.form.title"))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .padding(.top, 4)

                    fieldLabel(languageManager.text("ambassador.form.roles.label"))
                    roleCheckboxes

                    fieldLabel(languageManager.text("ambassador.form.email.label"))
                    emailField

                    fieldLabel(languageManager.text("ambassador.form.age.label"))
                    ageField

                    fieldLabel(languageManager.text("ambassador.form.presentation.label"))
                    presentationField

                    countryConfirmToggle

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.2))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            Button(action: submit) {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(ink)
                    }
                    Text(languageManager.text("ambassador.form.submit"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                }
            }
            .buttonStyle(BrutalAmbassadorButtonStyle(isEnabled: canSubmit))
            .disabled(!canSubmit)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var premiumBonusBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(ink)
            Text(languageManager.text("ambassador.bonus"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.45),
                    Color(red: 1.0, green: 0.78, blue: 0.55),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func roleCard(title: String, income: String, time: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            HStack(spacing: 8) {
                metaChip(income, bg: accent)
                metaChip(time, bg: Color.white)
            }

            Text(body)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func metaChip(_ text: String, bg: Color) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded, weight: .heavy))
            .foregroundStyle(ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg)
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
    }

    private var conditionsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.text("ambassador.conditions.title"))
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            conditionRow(languageManager.text("ambassador.conditions.countries"))
            conditionRow(languageManager.text("ambassador.conditions.age"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func conditionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(BrutalPalette.pastel(for: .sciences))
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.75))
        }
    }

    private var roleCheckboxes: some View {
        VStack(spacing: 10) {
            checkboxRow(
                title: languageManager.text("ambassador.form.role.slideshow"),
                isOn: $wantsSlideshow
            )
            checkboxRow(
                title: languageManager.text("ambassador.form.role.ugc"),
                isOn: $wantsUGC
            )
        }
    }

    private func checkboxRow(title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(ink)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var countryConfirmToggle: some View {
        Button {
            countryConfirmed.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: countryConfirmed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(ink)
                Text(languageManager.text("ambassador.form.country.confirm"))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(countryConfirmed ? BrutalPalette.pastel(for: .sciences).opacity(0.45) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emailField: some View {
        TextField(
            "",
            text: $email,
            prompt: Text(languageManager.text("ambassador.form.email.placeholder"))
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.35))
        )
        .font(.system(.body, design: .rounded, weight: .semibold))
        .foregroundStyle(ink)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .email)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var ageField: some View {
        TextField(
            "",
            text: $ageText,
            prompt: Text(languageManager.text("ambassador.form.age.placeholder"))
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.35))
        )
        .font(.system(.body, design: .rounded, weight: .semibold))
        .foregroundStyle(ink)
        .keyboardType(.numberPad)
        .focused($focusedField, equals: .age)
        .onChange(of: ageText) { _, newValue in
            let digits = newValue.filter(\.isNumber)
            if digits != newValue {
                ageText = String(digits.prefix(3))
            } else if digits.count > 3 {
                ageText = String(digits.prefix(3))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var presentationField: some View {
        ZStack(alignment: .topLeading) {
            if presentation.isEmpty {
                Text(languageManager.text("ambassador.form.presentation.placeholder"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.35))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $presentation)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .focused($focusedField, equals: .presentation)
                .frame(minHeight: 120)
                .onChange(of: presentation) { _, newValue in
                    if newValue.count > presentationLimit {
                        presentation = String(newValue.prefix(presentationLimit))
                    }
                }
        }
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(BrutalPalette.yellow)
                .symbolEffect(.bounce, value: didSucceed)

            Text(languageManager.text("ambassador.success.title"))
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)

            Text(languageManager.text("ambassador.success.body"))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: { dismiss() }) {
                Text(languageManager.text("ambassador.success.close"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .buttonStyle(BrutalAmbassadorButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.55))
            .tracking(1.1)
    }

    private func submit() {
        guard canSubmit, let age = parsedAge else { return }

        focusedField = nil
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                try await AmbassadorService.submit(
                    email: email,
                    age: age,
                    presentation: presentation,
                    wantsSlideshow: wantsSlideshow,
                    wantsUGC: wantsUGC,
                    countryConfirmed: countryConfirmed,
                    language: languageManager.current
                )
                await MainActor.run {
                    isSubmitting = false
                    didSucceed = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch let error as AmbassadorService.SubmissionError {
                await MainActor.run {
                    isSubmitting = false
                    switch error {
                    case .invalidAge:
                        errorMessage = languageManager.text("ambassador.form.error.age")
                    default:
                        errorMessage = languageManager.text("ambassador.form.error.generic")
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = languageManager.text("ambassador.form.error.generic")
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

private struct BrutalAmbassadorButtonStyle: ButtonStyle {
    var depth: CGFloat = 3
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled

        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BrutalPalette.ink)
                        .offset(y: depth)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                        .offset(y: pressed ? depth : 0)
                }
            )
            .padding(.bottom, depth)
            .opacity(isEnabled ? 1 : 0.55)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}
