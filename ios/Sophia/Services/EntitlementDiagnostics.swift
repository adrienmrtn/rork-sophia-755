import Foundation
import Security

/// Diagnostic (temporaire) : vérifie si l'entitlement **Sign in with Apple**
/// (`com.apple.developer.applesignin`) est réellement présent dans le binaire **installé**.
///
/// Méthode principale : `SecTask` lit les entitlements réels du process en cours (fiable sur
/// TestFlight/App Store). Fallback : parsing du `embedded.mobileprovision` (souvent absent des
/// builds re-signés). Objectif : distinguer « l'App ID a la capability » (portail Apple) de
/// « le build installé porte vraiment l'entitlement » (profil de signature).
enum EntitlementDiagnostics {
    static func appleSignInSummary() -> String {
        if let viaTask = viaSecTask() { return viaTask }
        if let entitlements = embeddedEntitlements() { return format(entitlements) }
        return "entitlement: illisible (SecTask + profil indisponibles)"
    }

    // MARK: - SecTask (entitlements réels du process)

    private static func viaSecTask() -> String? {
        guard let task = SecTaskCreateFromSelf(nil) else { return nil }

        func value(_ key: String) -> Any? {
            SecTaskCopyValueForEntitlement(task, key as CFString, nil)
        }

        let apple = value("com.apple.developer.applesignin")
        let team = value("com.apple.developer.team-identifier") as? String
        let appId = value("application-identifier") as? String

        // Si rien n'est lisible, on laisse le fallback tenter le profil.
        if apple == nil, team == nil, appId == nil { return nil }

        let appleStr: String
        if let arr = apple as? [String] {
            appleStr = "OUI(\(arr.joined(separator: ",")))"
        } else if apple != nil {
            appleStr = "OUI"
        } else {
            appleStr = "❌ ABSENT"
        }

        return "AppleSignIn=\(appleStr) · team=\(team ?? "?") · appId=\(appId ?? "?")"
    }

    // MARK: - Fallback : embedded.mobileprovision

    private static func format(_ entitlements: [String: Any]) -> String {
        let appleStr: String
        if let value = entitlements["com.apple.developer.applesignin"] {
            appleStr = (value as? [String]).map { "OUI(\($0.joined(separator: ",")))" } ?? "OUI"
        } else {
            appleStr = "❌ ABSENT"
        }
        let team = (entitlements["com.apple.developer.team-identifier"] as? String) ?? "?"
        let appId = (entitlements["application-identifier"] as? String) ?? "?"
        return "AppleSignIn=\(appleStr) · team=\(team) · appId=\(appId) (profil)"
    }

    private static func embeddedEntitlements() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        guard let ascii = String(data: data, encoding: .isoLatin1),
              let start = ascii.range(of: "<?xml"),
              let end = ascii.range(of: "</plist>") else {
            return nil
        }
        let plistString = String(ascii[start.lowerBound..<end.upperBound])
        guard let plistData = plistString.data(using: .isoLatin1),
              let profile = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return profile["Entitlements"] as? [String: Any]
    }
}
