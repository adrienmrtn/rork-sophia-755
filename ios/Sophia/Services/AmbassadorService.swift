import Foundation
import UIKit

enum AmbassadorService {
    enum SubmissionError: LocalizedError {
        case invalidEmail
        case invalidAge
        case emptyPresentation
        case noRoleSelected
        case countryNotConfirmed
        case network(Error)
        case server(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "Email required"
            case .invalidAge:
                return "Age must be 16+"
            case .emptyPresentation:
                return "Presentation required"
            case .noRoleSelected:
                return "Select at least one role"
            case .countryNotConfirmed:
                return "Country confirmation required"
            case .network(let error):
                return error.localizedDescription
            case .server(let statusCode):
                return "Server error (\(statusCode))"
            }
        }
    }

    static func submit(
        email: String,
        age: Int,
        presentation: String,
        wantsSlideshow: Bool,
        wantsUGC: Bool,
        countryConfirmed: Bool,
        language: AppLanguage
    ) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            throw SubmissionError.invalidEmail
        }
        guard age >= 16, age <= 120 else {
            throw SubmissionError.invalidAge
        }

        let trimmedPresentation = presentation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPresentation.count >= 10 else {
            throw SubmissionError.emptyPresentation
        }
        guard wantsSlideshow || wantsUGC else {
            throw SubmissionError.noRoleSelected
        }
        guard countryConfirmed else {
            throw SubmissionError.countryNotConfirmed
        }

        let roles: String
        if wantsSlideshow && wantsUGC {
            roles = "slideshow+ugc"
        } else if wantsSlideshow {
            roles = "slideshow"
        } else {
            roles = "ugc"
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let iosVersion = UIDevice.current.systemVersion
        let device = UIDevice.current.model

        let payload: [String: Any] = [
            "email": trimmedEmail,
            "_replyto": trimmedEmail,
            "age": age,
            "presentation": trimmedPresentation,
            "roles": roles,
            "wants_slideshow": wantsSlideshow,
            "wants_ugc": wantsUGC,
            "country_confirmed": countryConfirmed,
            "eligible_countries": "FR,CA,BE,CH",
            "_subject": "Sophia — Candidature ambassadeur (\(roles))",
            "app_version": version,
            "build": build,
            "ios_version": iosVersion,
            "device": device,
            "language": language.rawValue,
        ]

        guard let url = URL(string: AppConfig.FORMSPREE_AMBASSADOR_ENDPOINT) else {
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
