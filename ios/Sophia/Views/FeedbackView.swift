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

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream
    private let messageLimit = 2_000

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        trimmedMessage.count >= 10 && !isSubmitting
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(languageManager.text("feedback.subtitle"))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                fieldLabel(languageManager.text("feedback.category.label"))
                categoryPicker

                fieldLabel(languageManager.text("feedback.message.label"))
                messageField

                fieldLabel(languageManager.text("feedback.email.label"))
                emailField

                Text(languageManager.text("feedback.technicalNote"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: submit) {
                    HStack(spacing: 10) {
                        if isSubmitting {
                            ProgressView()
                                .tint(ink)
                        }
                        Text(languageManager.text("feedback.submit"))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(BrutalCardButtonStyle(depth: 3))
                .brutalCard()
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.55)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(BrutalPalette.pastel(for: .sciences))
                .symbolEffect(.bounce, value: didSucceed)

            Text(languageManager.text("feedback.success.title"))
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)

            Text(languageManager.text("feedback.success.body"))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: { dismiss() }) {
                Text(languageManager.text("feedback.success.close"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(BrutalCardButtonStyle(depth: 3))
            .brutalCard()
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
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(category == item ? cream : ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(category == item ? ink : Color.white)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule().strokeBorder(ink, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var messageField: some View {
        ZStack(alignment: .topLeading) {
            if message.isEmpty {
                Text(languageManager.text("feedback.message.placeholder"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.35))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $message)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
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
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var emailField: some View {
        TextField(
            "",
            text: $email,
            prompt: Text(languageManager.text("feedback.email.placeholder"))
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

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.55))
            .tracking(1.1)
    }

    private func submit() {
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
