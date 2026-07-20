import Foundation

/// Diagnostic (temporaire) : lit le profil de provisioning embarqué dans le build installé
/// (`embedded.mobileprovision`) pour vérifier si l'entitlement **Sign in with Apple**
/// (`com.apple.developer.applesignin`) est réellement présent, ainsi que le Team ID et
/// l'application-identifier utilisés à la signature.
///
/// Objectif : distinguer « l'App ID a la capability » (côté portail Apple) de « le build
/// installé porte vraiment l'entitlement » (côté profil de signature). API 100 % publique.
enum EntitlementDiagnostics {
    /// Résumé court, affichable à l'écran.
    static func appleSignInSummary() -> String {
        guard let entitlements = embeddedEntitlements() else {
            return "profil: introuvable (build App Store re-signé ?)"
        }

        let hasAppleSignIn: String
        if let value = entitlements["com.apple.developer.applesignin"] {
            if let arr = value as? [String] {
                hasAppleSignIn = "OUI (\(arr.joined(separator: ",")))"
            } else {
                hasAppleSignIn = "OUI"
            }
        } else {
            hasAppleSignIn = "❌ ABSENT"
        }

        let team = (entitlements["com.apple.developer.team-identifier"] as? String) ?? "?"
        let appId = (entitlements["application-identifier"] as? String) ?? "?"

        return "AppleSignIn=\(hasAppleSignIn) · team=\(team) · appId=\(appId)"
    }

    /// Extrait le dictionnaire `Entitlements` du `embedded.mobileprovision`.
    private static func embeddedEntitlements() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        // Le fichier est un CMS/PKCS7 ; le plist XML est encapsulé en clair à l'intérieur.
        guard let ascii = String(data: data, encoding: .ascii)
                ?? String(data: data, encoding: .isoLatin1),
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
