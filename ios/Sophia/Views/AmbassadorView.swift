import SwiftUI

struct AmbassadorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    private enum Stage {
        case program
        case form
        case success
    }

    @State private var stage: Stage = .program
    @State private var wantsSlideshow = false
    @State private var wantsUGC = false
    @State private var email = ""
    @State private var ageText = ""
    @State private var presentation = ""
    @State private var countryConfirmed = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case age
        case presentation
    }

    private let presentationLimit = 1_500
    private let presentationMin = 10

    private var parsedAge: Int? {
        Int(ageText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPresentation: String {
        presentation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var presentationCount: Int {
        trimmedPresentation.count
    }

    private var emailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }

    private var ageValid: Bool {
        guard let age = parsedAge else { return false }
        return age >= 16 && age <= 120
    }

    private var roleValid: Bool {
        wantsSlideshow || wantsUGC
    }

    private var canSubmit: Bool {
        !isSubmitting && emailValid && ageValid
            && presentationCount >= presentationMin && roleValid && countryConfirmed
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if stage != .success {
                    stepIndicator
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                }

                switch stage {
                case .program:
                    programStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .form:
                    formStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .success:
                    successView
                        .transition(.opacity)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sophiaSheetChrome()
    }

    // MARK: - Header

    private var header: some View {
        LegalHeader(
            title: languageManager.text("ambassador.title"),
            onClose: { dismiss() }
        )
    }

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            stepPill(
                index: 1,
                label: languageManager.text("ambassador.step.program"),
                active: true
            )
            stepPill(
                index: 2,
                label: languageManager.text("ambassador.step.apply"),
                active: stage == .form
            )
        }
    }

    private func stepPill(index: Int, label: String, active: Bool) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(active ? DS.accent : DS.surface)
                Circle().strokeBorder(active ? DS.accent : DS.hairline, lineWidth: 1)
                Text("\(index)")
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(active ? .white : DS.inkTertiary)
            }
            .frame(width: 24, height: 24)

            Text(label)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(active ? DS.ink : DS.inkTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(active ? DS.accentTint : DS.surfaceMuted, in: Capsule())
    }

    // MARK: - Step 1 — Program

    private var programStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(languageManager.text("ambassador.program.heading"))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(languageManager.text("ambassador.intro"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    highlightChips

                    howItWorksCard

                    sectionTitle(languageManager.text("ambassador.roles.title"))

                    roleCard(
                        icon: "rectangle.stack.fill",
                        title: languageManager.text("ambassador.role.slideshow.title"),
                        income: languageManager.text("ambassador.role.slideshow.income"),
                        time: languageManager.text("ambassador.role.slideshow.time"),
                        body: languageManager.text("ambassador.role.slideshow.body")
                    )

                    roleCard(
                        icon: "video.fill",
                        title: languageManager.text("ambassador.role.ugc.title"),
                        income: languageManager.text("ambassador.role.ugc.income"),
                        time: languageManager.text("ambassador.role.ugc.time"),
                        body: languageManager.text("ambassador.role.ugc.body")
                    )

                    sectionTitle(languageManager.text("ambassador.conditions.title"))
                    conditionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            bottomBar {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        stage = .form
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("ambassador.discover.cta"))
                        Image(systemName: "arrow.right")
                            .font(.jakarta(size: 15, weight: .semibold))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        }
    }

    private var highlightChips: some View {
        VStack(spacing: 10) {
            highlightRow(icon: "crown.fill", text: languageManager.text("ambassador.bonus"))
            highlightRow(icon: "bolt.fill", text: languageManager.text("ambassador.cta48h"))
        }
    }

    private func highlightRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.jakarta(size: 15, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 36, height: 36)
                .background(DS.surface, in: Circle())

            Text(text)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("ambassador.how.title"))
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)

            howStep(1, languageManager.text("ambassador.how.step1"))
            howStep(2, languageManager.text("ambassador.how.step2"))
            howStep(3, languageManager.text("ambassador.how.step3"))
        }
        .dsCard()
    }

    private func howStep(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(DS.accentTint)
                Text("\(index)")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.accentSoft)
            }
            .frame(width: 28, height: 28)

            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func roleCard(
        icon: String,
        title: String,
        income: String,
        time: String,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.jakarta(size: 16, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                    .frame(width: 40, height: 40)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

                Text(title)
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                statBlock(value: income, label: languageManager.text("ambassador.stat.income"))
                statBlock(value: time, label: languageManager.text("ambassador.stat.time"))
            }

            Text(body)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dsCard()
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
    }

    private var conditionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            conditionRow(languageManager.text("ambassador.conditions.countries"))
            conditionRow(languageManager.text("ambassador.conditions.age"))
        }
        .dsCard()
    }

    private func conditionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.jakarta(size: 16, weight: .medium))
                .foregroundStyle(DS.success)
            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Step 2 — Form

    private var formStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldGroup(
                        label: languageManager.text("ambassador.form.roles.label"),
                        valid: roleValid
                    ) {
                        roleCheckboxes
                    }

                    fieldGroup(
                        label: languageManager.text("ambassador.form.email.label"),
                        valid: emailValid
                    ) {
                        emailField
                    }

                    fieldGroup(
                        label: languageManager.text("ambassador.form.age.label"),
                        valid: ageValid
                    ) {
                        ageField
                    }

                    fieldGroup(
                        label: languageManager.text("ambassador.form.presentation.label"),
                        valid: presentationCount >= presentationMin
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            presentationField
                            presentationHint
                        }
                    }

                    countryConfirmToggle

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            bottomBar {
                VStack(spacing: 8) {
                    if !canSubmit && errorMessage == nil {
                        Text(languageManager.text("ambassador.form.hint"))
                            .font(DS.sans(.caption))
                            .foregroundStyle(DS.inkSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    HStack(spacing: 12) {
                        Button {
                            focusedField = nil
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                stage = .program
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.jakarta(size: 16, weight: .medium))
                                .foregroundStyle(DS.inkSecondary)
                                .frame(width: 54, height: 54)
                                .background(DS.surface, in: Circle())
                                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                        }
                        .buttonStyle(SoftPressButtonStyle())

                        Button(action: submit) {
                            HStack(spacing: 10) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                }
                                Text(languageManager.text("ambassador.form.submit"))
                            }
                        }
                        .buttonStyle(DSPrimaryButtonStyle())
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.55)
                    }
                }
            }
        }
    }

    private func fieldGroup<Content: View>(
        label: String,
        valid: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label.uppercased())
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.1)
                if valid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.jakarta(size: 12, weight: .medium))
                        .foregroundStyle(DS.success)
                }
            }
            content()
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
                    .font(.jakarta(size: 20, weight: .medium))
                    .foregroundStyle(isOn.wrappedValue ? DS.accent : DS.inkTertiary)
                Text(title)
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(isOn.wrappedValue ? DS.accentTint : DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isOn.wrappedValue ? DS.accentSoft.opacity(0.4) : DS.hairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var countryConfirmToggle: some View {
        Button {
            countryConfirmed.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: countryConfirmed ? "checkmark.square.fill" : "square")
                    .font(.jakarta(size: 20, weight: .medium))
                    .foregroundStyle(countryConfirmed ? DS.accent : DS.inkTertiary)
                Text(languageManager.text("ambassador.form.country.confirm"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(countryConfirmed ? DS.accentTint : DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(countryConfirmed ? DS.accentSoft.opacity(0.4) : DS.hairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var emailField: some View {
        TextField(
            "",
            text: $email,
            prompt: Text(languageManager.text("ambassador.form.email.placeholder"))
                .font(DS.sans(.body))
                .foregroundStyle(DS.inkTertiary)
        )
        .font(DS.sans(.body))
        .foregroundStyle(DS.ink)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .email)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private var ageField: some View {
        TextField(
            "",
            text: $ageText,
            prompt: Text(languageManager.text("ambassador.form.age.placeholder"))
                .font(DS.sans(.body))
                .foregroundStyle(DS.inkTertiary)
        )
        .font(DS.sans(.body))
        .foregroundStyle(DS.ink)
        .keyboardType(.numberPad)
        .focused($focusedField, equals: .age)
        .onChange(of: ageText) { _, newValue in
            let digits = newValue.filter(\.isNumber)
            if digits != newValue || digits.count > 3 {
                ageText = String(digits.prefix(3))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private var presentationField: some View {
        ZStack(alignment: .topLeading) {
            if presentation.isEmpty {
                Text(languageManager.text("ambassador.form.presentation.placeholder"))
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $presentation)
                .font(DS.sans(.body))
                .foregroundStyle(DS.ink)
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
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private var presentationHint: some View {
        Text(
            String(
                format: languageManager.text("ambassador.form.presentation.hint"),
                presentationCount,
                presentationMin
            )
        )
        .font(DS.sans(.caption))
        .foregroundStyle(presentationCount >= presentationMin ? DS.success : DS.inkTertiary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle().fill(DS.accentTint)
                Image(systemName: "checkmark")
                    .font(.jakarta(size: 38, weight: .medium))
                    .foregroundStyle(DS.accent)
            }
            .frame(width: 96, height: 96)
            .symbolEffect(.bounce, value: stage == .success)

            Text(languageManager.text("ambassador.success.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)

            Text(languageManager.text("ambassador.success.body"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                Text(languageManager.text("ambassador.cta48h"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DS.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            .padding(.horizontal, 20)

            Spacer()

            Button(action: { dismiss() }) {
                Text(languageManager.text("ambassador.success.close"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Shared

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DS.sans(.caption, .semibold))
            .foregroundStyle(DS.inkTertiary)
            .tracking(1.2)
    }

    private func bottomBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
            .background(
                DS.surface
                    .overlay(alignment: .top) {
                        Rectangle().fill(DS.hairline).frame(height: 1)
                    }
                    .ignoresSafeArea(edges: .bottom)
            )
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        stage = .success
                    }
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
