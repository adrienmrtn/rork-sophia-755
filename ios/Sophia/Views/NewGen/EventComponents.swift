import SwiftUI

// Briques communes aux événements : la carte du fil (`EventFeedCard`), les cartes de l'onglet
// Explorer et la page de l'événement (`EventPageView`). L'illustration (image de l'équipe ou
// éventail de couvertures), les barres du défi et de l'objectif commun, le badge à gagner.

/// Les couleurs « papier » du site (marine, safran, crème). Fixes : elles ne suivent pas le
/// mode nuit, un bloc d'événement garde la même affiche de jour comme de nuit.
enum EventPalette {
    static let navy = Color(red: 26.0 / 255.0, green: 58.0 / 255.0, blue: 107.0 / 255.0)
    static let night = Color(red: 0.043, green: 0.07, blue: 0.125)
    static let saffron = Color(red: 242.0 / 255.0, green: 177.0 / 255.0, blue: 52.0 / 255.0)
    static let cream = Color(red: 251.0 / 255.0, green: 247.0 / 255.0, blue: 239.0 / 255.0)
}

/// L'illustration d'un événement, qui remplit la place qu'on lui donne : l'image posée par
/// l'équipe quand il y en a une, sinon un éventail des couvertures de la collection sur fond
/// marine. À poser dans un cadre de taille connue (`Color.clear.frame(…).overlay { … }`).
struct EventArtwork: View {
    let campaign: Campaign
    let courses: [Course]
    /// Remonte l'éventail (fraction de la hauteur) quand un titre recouvre le bas du cadre ;
    /// une valeur négative le descend.
    var collageLift: CGFloat = 0

    var body: some View {
        ZStack {
            EventPalette.navy
            if campaign.imageUrl == nil {
                EventCoverCollage(courses: Array(courses.prefix(3)), symbol: campaign.symbol ?? "sparkles", lift: collageLift)
            } else {
                // Le temps que l'image arrive (ou si elle n'arrive pas) : le symbole, discret.
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(EventPalette.saffron.opacity(0.35))
            }
        }
        .overlay {
            if let imageUrl = campaign.imageUrl {
                RemoteImage(url: imageUrl)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Jusqu'à trois couvertures en éventail devant un halo safran ; le symbole de l'événement
/// quand aucun cours de la collection n'est encore connu de l'app.
struct EventCoverCollage: View {
    let courses: [Course]
    let symbol: String
    var lift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.height * 0.42, geo.size.width * 0.28)
            let count = courses.count
            ZStack {
                Circle()
                    .fill(EventPalette.saffron.opacity(0.16))
                    .frame(width: side * 2.6, height: side * 2.6)
                Circle()
                    .strokeBorder(EventPalette.saffron.opacity(0.3), lineWidth: 1)
                    .frame(width: side * 3.5, height: side * 3.5)
                if courses.isEmpty {
                    Image(systemName: symbol)
                        .font(.system(size: max(20, side * 0.8), weight: .semibold))
                        .foregroundStyle(EventPalette.saffron)
                } else {
                    ForEach(Array(courses.enumerated()), id: \.offset) { index, course in
                        // -1, 0, 1 pour trois couvertures ; -0,5 et 0,5 pour deux ; 0 pour une.
                        let position = CGFloat(index) - CGFloat(count - 1) / 2
                        Color.clear
                            .frame(width: side, height: side * 1.25)
                            .overlay { CourseCover(course: course, cornerRadius: 0) }
                            .clipShape(RoundedRectangle(cornerRadius: side * 0.14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 6)
                            .rotationEffect(.degrees(Double(position) * 9))
                            .offset(x: position * side * 0.72, y: abs(position) * side * 0.1)
                            .zIndex(-Double(abs(position)))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .offset(y: -geo.size.height * lift)
        }
    }
}

/// Une barre d'avancement en capsule (objectif commun, défi long).
struct EventProgressBar: View {
    let fraction: Double
    var tint: Color = EventPalette.saffron
    var track: Color = DS.surfaceMuted
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, fraction))))
            }
        }
        .frame(height: height)
    }
}

/// L'avancement du défi : un segment par cours à lire tant qu'il y en a peu (huit au plus),
/// une barre continue au-delà.
struct EventChallengeMeter: View {
    let done: Int
    let target: Int
    var tint: Color = EventPalette.saffron
    var track: Color = DS.surfaceMuted
    var height: CGFloat = 8

    var body: some View {
        let total = max(1, target)
        if total <= 8 {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule().fill(index < done ? tint : track)
                }
            }
            .frame(height: height)
        } else {
            EventProgressBar(fraction: Double(done) / Double(total), tint: tint, track: track, height: height)
        }
    }
}

/// Le badge de l'événement dans un anneau qui se remplit avec le défi : son illustration quand
/// l'équipe en a choisi une, sinon le symbole de l'événement. Une coche quand il est gagné.
struct EventBadgeRing: View {
    let campaign: Campaign
    let done: Int
    var size: CGFloat = 96
    /// La couleur de l'anneau vide, selon le fond sur lequel le badge est posé.
    var track: Color = DS.hairline

    var body: some View {
        let target = max(1, campaign.challengeTarget)
        let fraction = min(1, Double(done) / Double(target))
        let earned = done >= target
        let line = max(3, size * 0.055)
        let inner = size - line * 3.2
        ZStack {
            Circle().stroke(track, lineWidth: line)
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(EventPalette.saffron, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            ZStack {
                Circle().fill(EventPalette.navy)
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: inner * 0.42, weight: .semibold))
                    .foregroundStyle(EventPalette.saffron)
            }
            .frame(width: inner, height: inner)
            .overlay {
                if let url = campaign.badgeImageUrl {
                    RemoteImage(url: url)
                }
            }
            .clipShape(Circle())
        }
        .padding(line / 2)
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if earned {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: max(14, size * 0.26), weight: .bold))
                    .foregroundStyle(EventPalette.saffron)
                    .background(Circle().fill(Color.white).padding(size * 0.05))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Pastille d'un événement posée sur son illustration : safran pour la date, sombre pour « Terminé ».
struct EventPill: View {
    enum Style { case saffron, dark }
    let text: String
    var style: Style = .saffron

    var body: some View {
        Text(text)
            .font(DS.sans(.caption, .bold))
            .foregroundStyle(style == .saffron ? EventPalette.navy : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(style == .saffron ? EventPalette.saffron : EventPalette.night.opacity(0.78)))
    }
}
