import SwiftUI
import UIKit

// MARK: - Palette

/// Les couleurs des illustrations (direction affiche du site) : les duels sont le seul endroit
/// de l'app qui les porte en aplats, sur les fonds de ligue.
enum DuelPalette {
    static let saffron = Color(red: 0.949, green: 0.694, blue: 0.204)
    static let coral = Color(red: 0.878, green: 0.353, blue: 0.227)
    static let navy = Color(red: 0.102, green: 0.227, blue: 0.420)
    static let cream = Color(red: 0.984, green: 0.969, blue: 0.937)
    static let night = Color(red: 0.055, green: 0.098, blue: 0.180)

    static let confetti: [Color] = [saffron, coral, navy, cream, Color(red: 0.36, green: 0.62, blue: 0.86)]
}

extension Color {
    /// « #1A3A6B » ; une valeur illisible donne le bleu marine de l'app.
    init(duelHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        if cleaned.count != 6 || !Scanner(string: cleaned).scanHexInt64(&value) {
            value = 0x1A3A6B
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

// MARK: - Haptiques

/// Les vibrations des duels, réunies ici pour qu'un même moment sonne partout pareil.
enum DuelHaptics {
    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, _ intensity: CGFloat = 1) {
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    private static func after(_ delay: Double, _ work: @escaping () -> Void) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            work()
        }
    }

    /// Un bouton secondaire, une ligne de liste.
    static func tap() { impact(.light, 0.7) }

    /// Le défilement des adversaires pendant la recherche, un cran du curseur.
    static func tick() { impact(.soft, 0.45) }

    /// Le joueur verrouille sa réponse.
    static func lock() {
        impact(.rigid, 0.9)
    }

    /// L'adversaire vient de répondre.
    static func opponentAnswered() { impact(.soft, 0.8) }

    static func correct() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func wrong() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Les dernières secondes du chrono.
    static func clock() { impact(.light, 0.9) }

    /// 3, 2, 1 ; puis le départ, plus appuyé.
    static func countdown(final: Bool) {
        if final {
            impact(.heavy, 1)
            after(0.07) { impact(.rigid, 1) }
        } else {
            impact(.medium, 0.85)
        }
    }

    static func opponentFound() {
        impact(.heavy, 1)
        after(0.09) { impact(.rigid, 0.9) }
        after(0.2) { impact(.soft, 0.7) }
    }

    static func suddenDeath() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        after(0.18) { impact(.heavy, 1) }
    }

    static func victory() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        after(0.14) { impact(.heavy, 1) }
        after(0.28) { impact(.rigid, 0.9) }
        after(0.42) { impact(.medium, 0.8) }
    }

    static func defeat() {
        impact(.heavy, 0.8)
        after(0.2) { impact(.soft, 0.6) }
    }

    /// Le compteur de trophées qui défile : de plus en plus net à l'approche du total.
    static func trophyTick(progress: Double) {
        impact(.light, 0.35 + 0.5 * min(max(progress, 0), 1))
    }

    static func trophyLanded() {
        impact(.rigid, 1)
    }

    /// Montée de ligue : une salve, puis le coup de la nouvelle ligue qui se pose.
    static func promotion() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        for step in 1...4 {
            after(0.09 * Double(step)) { impact(.rigid, 0.55 + 0.1 * Double(step)) }
        }
        after(0.6) { impact(.heavy, 1) }
    }
}

// MARK: - Trophées

/// Le pictogramme du trophée, en safran, pour les compteurs.
struct DuelTrophyIcon: View {
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(DuelPalette.saffron)
            .accessibilityHidden(true)
    }
}

/// « 🏆 1 240 » : le pictogramme et un nombre de trophées, groupé dans la langue de l'app.
struct DuelTrophyCount: View {
    @Environment(LanguageManager.self) private var languageManager
    let value: Int
    var size: CGFloat = 15
    var color: Color = DS.ink

    var body: some View {
        HStack(spacing: size * 0.3) {
            DuelTrophyIcon(size: size * 0.92)
            Text(value.formatted(language: languageManager.current))
                .font(.jakarta(size: size, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(format: languageManager.text("duel.trophies.count"), value)))
    }
}

// MARK: - Avatars

/// L'avatar d'un joueur, cerclé d'un liseré (la couleur du camp).
struct DuelAvatar: View {
    let avatarId: String?
    let initial: String
    var size: CGFloat = 56
    var ring: Color = .white
    var ringWidth: CGFloat = 3

    var body: some View {
        AvatarCircle(avatarId: avatarId, initial: initial, size: size)
            .overlay(Circle().strokeBorder(ring, lineWidth: ringWidth))
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Ligues

/// Le fond d'une ligue : sa couleur d'accent tout de suite, puis l'illustration dès qu'elle est là.
struct DuelLeagueBackdrop: View {
    let league: DuelLeague?
    var thumb: Bool = false

    var body: some View {
        // L'image est posée en surimpression : elle remplit la place donnée à la couleur sans
        // jamais agrandir la vue (une image « à remplir » sans cadre prendrait sa propre taille).
        //
        // Elle ne reçoit pas les touches : rogner une image ne rogne que son dessin. Une image
        // en hauteur dans un bandeau bas déborde, invisible, de plusieurs centaines de points
        // au-dessus et en dessous, et avalait les touches des boutons voisins (« Défier en
        // duel », juste au-dessus de la carte de ligue du profil d'un ami).
        Color(duelHex: league?.accentHex ?? "")
            .overlay { RemoteImage(url: thumb ? league?.thumbURL : league?.backgroundURL).allowsHitTesting(false) }
            .clipped()
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

/// Jauge vers la ligue suivante.
struct DuelProgressBar: View {
    let progress: Double
    var tint: Color = DuelPalette.saffron
    var track: Color = Color.white.opacity(0.28)
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Le nom d'une ligue dans la langue de l'app : « Ligue Vermeer », « Vermeer League ».
enum DuelFormat {
    static func leagueName(_ league: DuelLeague?, language: AppLanguage) -> String {
        guard let league else { return "" }
        return String(format: AppLocalizable.string("duel.league.name", language: language), league.name)
    }

    /// La valeur d'un curseur avec son unité : « 1492 », « 71 % », « 206 bones ».
    static func sliderValue(_ value: Double, unit: String?) -> String {
        let number = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        switch unit {
        case nil, "", "year": return number
        case "%": return "\(number) %"
        case let other?: return "\(number) \(other)"
        }
    }
}

// MARK: - Images de question

/// Les drapeaux hébergés sont des fichiers 640 × 800 où le drapeau est posé sur une marge beige
/// (« papier », cuite dans l'image par scripts/duels_images.py) : affichés tels quels, ils
/// gardent ce fond beige derrière eux, en clair comme en sombre. On ne peut pas réécrire les
/// fichiers ; l'app rogne donc la marge et ne garde que le drapeau, posé à même la page.
/// Une image sans cette marge (portrait, tableau, monument) ressort inchangée.
enum DuelImageTrimmer {
    private static let cache = NSCache<NSString, UIImage>()
    /// Les adresses des images laissées telles quelles (rien à rogner).
    private static let untouched = NSCache<NSString, NSNumber>()

    /// L'image sans sa marge, et si elle a été rognée (un drapeau, à montrer avec un filet).
    static func trimmed(_ image: UIImage, key: String) -> (image: UIImage, flat: Bool) {
        let cacheKey = key as NSString
        if let cached = cache.object(forKey: cacheKey) { return (cached, true) }
        if untouched.object(forKey: cacheKey) != nil { return (image, false) }
        guard let result = trim(image) else {
            untouched.setObject(NSNumber(value: true), forKey: cacheKey)
            return (image, false)
        }
        cache.setObject(result, forKey: cacheKey)
        return (result, true)
    }

    /// La couleur de la marge (232, 228, 218), ou la même assombrie par l'ombre portée du drapeau.
    private static func isPaper(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Bool {
        let level = Double(red) / 232
        guard level >= 0.55, level <= 1.06 else { return false }
        return abs(Double(green) / 228 - level) < 0.035 && abs(Double(blue) / 218 - level) < 0.045
    }

    private static func trim(_ image: UIImage) -> UIImage? {
        guard let source = image.cgImage, source.width >= 64, source.height >= 64 else { return nil }
        // Une copie réduite suffit à trouver les bords, à deux points près.
        let width = 320
        let height = max(Int((Double(source.height) / Double(source.width) * Double(width)).rounded()), 1)
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        let pixels = buffer

        // Le pourtour doit être de la marge : sinon l'image occupe tout son cadre, rien à rogner.
        var ring = 0
        var ringPaper = 0
        var rows = [Int](repeating: 0, count: height)
        var columns = [Int](repeating: 0, count: width)
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let paper = isPaper(pixels[index], pixels[index + 1], pixels[index + 2])
                if y < 2 || y >= height - 2 || x < 2 || x >= width - 2 {
                    ring += 1
                    if paper { ringPaper += 1 }
                }
                if !paper {
                    rows[y] += 1
                    columns[x] += 1
                }
            }
        }
        guard ring > 0, Double(ringPaper) / Double(ring) >= 0.97 else { return nil }

        // Le drapeau : les lignes et les colonnes nettement hors marge (l'ombre n'en fait pas partie).
        let rowFloor = Double(rows.max() ?? 0) * 0.4
        let columnFloor = Double(columns.max() ?? 0) * 0.4
        guard rowFloor > 0, columnFloor > 0,
              let top = rows.firstIndex(where: { Double($0) >= rowFloor }),
              let bottom = rows.lastIndex(where: { Double($0) >= rowFloor }),
              let left = columns.firstIndex(where: { Double($0) >= columnFloor }),
              let right = columns.lastIndex(where: { Double($0) >= columnFloor }),
              bottom > top, right > left else { return nil }

        // Retour aux points du fichier, trois de moins de chaque côté : le filet noir du bord part avec.
        let scaleX = Double(source.width) / Double(width)
        let scaleY = Double(source.height) / Double(height)
        let inset = 3.0
        let rect = CGRect(
            x: Double(left) * scaleX + inset,
            y: Double(top) * scaleY + inset,
            width: Double(right + 1 - left) * scaleX - inset * 2,
            height: Double(bottom + 1 - top) * scaleY - inset * 2
        ).integral
        guard rect.width >= Double(source.width) * 0.3, rect.height >= Double(source.height) * 0.12,
              let cropped = source.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Boutons

/// Le grand bouton des duels : un aplat safran posé sur une tranche plus sombre, qui s'enfonce
/// sous le doigt.
struct DuelPlayButtonStyle: ButtonStyle {
    var fill: Color = DuelPalette.saffron
    var edge: Color = Color(red: 0.74, green: 0.50, blue: 0.08)
    var foreground: Color = DuelPalette.night

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.jakarta(size: 19, weight: .heavy))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(fill)
            )
            .offset(y: pressed ? 5 : 0)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(edge)
                    .offset(y: 6)
            )
            .padding(.bottom, 6)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: pressed)
    }
}
