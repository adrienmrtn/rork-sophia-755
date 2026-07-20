import Foundation
import CryptoKit

/// Génère les nonces requis par Sign in with Apple.
///
/// Apple reçoit le SHA-256 (hex) du nonce ; Supabase reçoit le nonce brut et le re-hache
/// pour vérifier qu'il correspond à celui présent dans l'idToken. Cela protège contre le rejeu.
enum AuthNonce {
    /// Nonce aléatoire cryptographiquement sûr.
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                // Fallback improbable : SecRandom a échoué.
                randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            }
            for random in randoms where remaining > 0 {
                if Int(random) < charset.count {
                    result.append(charset[Int(random) % charset.count])
                    remaining -= 1
                }
            }
        }
        return result
    }

    /// SHA-256 du nonce, encodé en hexadécimal (format attendu par Apple).
    static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
