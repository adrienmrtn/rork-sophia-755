import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    let isPremium: Bool

    @State private var category: FeedbackService.Category = .idea
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var didSucceed = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case message
        case email
    }

    private let messageLimit = 2_000

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        trimmedMessage.count >= 3 && !isSubmitting
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                LegalHeader(
                    title: languageManager.text("feedback.title"),
                    onClose: { dismiss() }
                )

                if didSucceed {
                    successView
                } else {
                    formView
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.trackFeedbackOpened()
        }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(languageManager.text("feedback.subtitle"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    fieldLabel(languageManager.text("feedback.category.label"))
                    categoryPicker

                    fieldLabel(languageManager.text("feedback.message.label"))
                    messageField

                    fieldLabel(languageManager.text("feedback.email.label"))
                    emailField

                    Text(languageManager.text("feedback.technicalNote"))
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            Button(action: submit) {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    }
                    Text(languageManager.text("feedback.submit"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.55)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle().fill(DS.accentTint)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(DS.accent)
            }
            .frame(width: 88, height: 88)
            .symbolEffect(.bounce, value: didSucceed)

            Text(languageManager.text("feedback.success.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)

            Text(languageManager.text("feedback.success.body"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: { dismiss() }) {
                Text(languageManager.text("feedback.success.close"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedbackService.Category.allCases) { item in
                    Button {
                        category = item
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(item.label(language: languageManager.current))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(category == item ? .white : DS.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(category == item ? DS.accent : DS.surface, in: Capsule())
                            .overlay {
                                if category != item {
                                    Capsule().strokeBorder(DS.hairline, lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
            }
        }
    }

    private var messageField: some View {
        ZStack(alignment: .topLeading) {
            if message.isEmpty {
                Text(languageManager.text("feedback.message.placeholder"))
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $message)
                .font(DS.sans(.body))
                .foregroundStyle(DS.ink)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .focused($focusedField, equals: .message)
                .frame(minHeight: 140)
                .onChange(of: message) { _, newValue in
                    if newValue.count > messageLimit {
                        message = String(newValue.prefix(messageLimit))
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

    private var emailField: some View {
        TextField(
            "",
            text: $email,
            prompt: Text(languageManager.text("feedback.email.placeholder"))
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DS.sans(.caption, .semibold))
            .foregroundStyle(DS.inkTertiary)
            .tracking(1.1)
    }

    private func submit() {
        guard canSubmit else { return }

        focusedField = nil
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                try await FeedbackService.submit(
                    category: category,
                    message: message,
                    email: email.isEmpty ? nil : email,
                    language: languageManager.current,
                    isPremium: isPremium
                )
                await MainActor.run {
                    isSubmitting = false
                    didSucceed = true
                    AnalyticsService.trackFeedbackSubmitted(category: category.rawValue)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = languageManager.text("feedback.error.generic")
                    AnalyticsService.trackFeedbackFailed(category: category.rawValue)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}
