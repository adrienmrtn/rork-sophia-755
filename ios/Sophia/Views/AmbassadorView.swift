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

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream
    private let green = Color(red: 0.12, green: 0.55, blue: 0.32)
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
            cream.ignoresSafeArea()

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
                Circle()
                    .fill(active ? ink : Color.white)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                Text("\(index)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(active ? cream : ink.opacity(0.55))
            }
            .frame(width: 26, height: 26)

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(active ? ink : ink.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(active ? BrutalPalette.yellow.opacity(0.35) : Color.white.opacity(0.6))
        .clipShape(Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
    }

    // MARK: - Step 1 — Program

    private var programStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(languageManager.text("ambassador.program.heading"))
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(languageManager.text("ambassador.intro"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    highlightChips

                    howItWorksCard

                    sectionTitle(languageManager.text("ambassador.roles.title"))

                    roleCard(
                        icon: "rectangle.stack.fill",
                        title: languageManager.text("ambassador.role.slideshow.title"),
                        income: languageManager.text("ambassador.role.slideshow.income"),
                        time: languageManager.text("ambassador.role.slideshow.time"),
                        body: languageManager.text("ambassador.role.slideshow.body"),
                        accent: BrutalPalette.yellow
                    )

                    roleCard(
                        icon: "video.fill",
                        title: languageManager.text("ambassador.role.ugc.title"),
                        income: languageManager.text("ambassador.role.ugc.income"),
                        time: languageManager.text("ambassador.role.ugc.time"),
                        body: languageManager.text("ambassador.role.ugc.body"),
                        accent: BrutalPalette.pink
                    )

                    sectionTitle(languageManager.text("ambassador.conditions.title"))
                    conditionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            bottomBar {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        stage = .form
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("ambassador.discover.cta"))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(ink)
                    }
                }
                .buttonStyle(BrutalAmbassadorButtonStyle(isEnabled: true))
            }
        }
    }

    private var highlightChips: some View {
        VStack(spacing: 10) {
            highlightRow(
                icon: "crown.fill",
                text: languageManager.text("ambassador.bonus"),
                gradient: [
                    Color(red: 1.0, green: 0.92, blue: 0.45),
                    Color(red: 1.0, green: 0.78, blue: 0.55),
                ]
            )
            highlightRow(
                icon: "bolt.fill",
                text: languageManager.text("ambassador.cta48h"),
                gradient: [
                    BrutalPalette.pastel(for: .sciences),
                    BrutalPalette.pastel(for: .sciences),
                ]
            )
        }
    }

    private func highlightRow(icon: String, text: String, gradient: [Color]) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .frame(width: 36, height: 36)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("ambassador.how.title"))
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            howStep(1, languageManager.text("ambassador.how.step1"))
            howStep(2, languageManager.text("ambassador.how.step2"))
            howStep(3, languageManager.text("ambassador.how.step3"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func howStep(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BrutalPalette.yellow)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(ink, lineWidth: 2)
                    }
                Text("\(index)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
            }
            .frame(width: 28, height: 28)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func roleCard(
        icon: String,
        title: String,
        income: String,
        time: String,
        body: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accent)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(ink, lineWidth: 2)
                        }
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .frame(width: 40, height: 40)

                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                statBlock(
                    value: income,
                    label: languageManager.text("ambassador.stat.income"),
                    bg: accent.opacity(0.35)
                )
                statBlock(
                    value: time,
                    label: languageManager.text("ambassador.stat.time"),
                    bg: Color.white
                )
            }

            Text(body)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func statBlock(value: String, label: String, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(ink.opacity(0.5))
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ink, lineWidth: 2)
        }
    }

    private var conditionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            conditionRow(languageManager.text("ambassador.conditions.countries"))
            conditionRow(languageManager.text("ambassador.conditions.age"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private func conditionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(green)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.8))
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
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.2))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            bottomBar {
                VStack(spacing: 8) {
                    if !canSubmit && errorMessage == nil {
                        Text(languageManager.text("ambassador.form.hint"))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.55))
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
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(ink)
                                .frame(width: 54, height: 54)
                        }
                        .buttonStyle(BrutalRaisedIconButtonStyle())

                        Button(action: submit) {
                            HStack(spacing: 10) {
                                if isSubmitting {
                                    ProgressView().tint(ink)
                                }
                                Text(languageManager.text("ambassador.form.submit"))
                                    .font(.system(.headline, design: .rounded, weight: .heavy))
                                    .foregroundStyle(ink)
                            }
                        }
                        .buttonStyle(BrutalAmbassadorButtonStyle(isEnabled: canSubmit))
                        .disabled(!canSubmit)
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
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.1)
                if valid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(green)
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
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(ink)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(isOn.wrappedValue ? BrutalPalette.yellow.opacity(0.35) : Color.white)
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
            .padding(.vertical, 14)
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
            if digits != newValue || digits.count > 3 {
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

    private var presentationHint: some View {
        Text(
            String(
                format: languageManager.text("ambassador.form.presentation.hint"),
                presentationCount,
                presentationMin
            )
        )
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(presentationCount >= presentationMin ? green : ink.opacity(0.5))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(BrutalPalette.yellow)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .frame(width: 96, height: 96)
            .symbolEffect(.bounce, value: stage == .success)

            Text(languageManager.text("ambassador.success.title"))
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)

            Text(languageManager.text("ambassador.success.body"))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(ink)
                Text(languageManager.text("ambassador.cta48h"))
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(BrutalPalette.pastel(for: .sciences))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
            .padding(.horizontal, 20)

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

    // MARK: - Shared

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.5))
            .tracking(1.2)
    }

    private func bottomBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
            .background(
                cream
                    .overlay(alignment: .top) {
                        Rectangle().fill(ink.opacity(0.12)).frame(height: 2)
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

private struct BrutalRaisedIconButtonStyle: ButtonStyle {
    var depth: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
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
            .contentShape(Rectangle())
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}
