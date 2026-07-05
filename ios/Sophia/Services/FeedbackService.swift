import Foundation
import UIKit

enum FeedbackService {
    enum Category: String, CaseIterable, Identifiable {
        case bug
        case idea
        case content
        case other

        var id: String { rawValue }

        func label(language: AppLanguage) -> String {
            AppLocalizable.string("feedback.category.\(rawValue)", language: language)
        }
    }

    enum SubmissionError: LocalizedError {
        case emptyMessage
        case network(Error)
        case server(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .emptyMessage:
                return "Message required"
            case .network(let error):
                return error.localizedDescription
            case .server(let statusCode):
                return "Server error (\(statusCode))"
            }
        }
    }

    static func submit(
        category: Category,
        message: String,
        email: String?,
        language: AppLanguage,
        isPremium: Bool
    ) async throws {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { throw SubmissionError.emptyMessage }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let iosVersion = UIDevice.current.systemVersion
        let device = UIDevice.current.model

        var payload: [String: Any] = [
            "message": trimmedMessage,
            "category": category.rawValue,
            "_subject": "Sophia — \(category.label(language: language))",
            "app_version": version,
            "build": build,
            "ios_version": iosVersion,
            "device": device,
            "language": language.rawValue,
            "is_premium": isPremium,
        ]

        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedEmail.isEmpty {
            payload["email"] = trimmedEmail
            payload["_replyto"] = trimmedEmail
        }

        guard let url = URL(string: AppConfig.FORMSPREE_ENDPOINT) else {
            throw SubmissionError.server(statusCode: 0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw SubmissionError.server(statusCode: 0)
            }
            guard (200...299).contains(http.statusCode) else {
                throw SubmissionError.server(statusCode: http.statusCode)
            }
        } catch let error as SubmissionError {
            throw error
        } catch {
            throw SubmissionError.network(error)
        }
    }
}
