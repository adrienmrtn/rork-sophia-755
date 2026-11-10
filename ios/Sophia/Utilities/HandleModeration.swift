import Foundation

/// Les @ interdits : insultes, propos haineux, figures et organisations liées à la haine ou au
/// terrorisme, contenu sexuel, et noms qui feraient passer un compte pour l'équipe Sophia.
///
/// Copie de la table `banned_handle_terms` (migration `20261110020000_banned_handles.sql`), pour
/// répondre dès « Continuer » sans attendre le serveur. C'est le serveur qui fait foi
/// (`update_my_handle` lève `handle_not_allowed`) : sa liste peut s'allonger sans nouvelle
/// version de l'app.
nonisolated enum HandleModeration {
    /// Refusé dès que le @ contient le terme (termes sans ambiguïté).
    private static let contains: [String] = [
        "hitler", "heilhitler", "siegheil", "neonazi", "nazism", "nazisme",
        "thirdreich", "mussolini", "goebbels", "himmler", "binladen", "benladen",
        "alqaeda", "alqaida", "daesh", "taliban", "terrorist", "whitepower",
        "whitepride", "supremacist", "antisemit", "kkk", "nigger", "nigga",
        "faggot", "tarlouze", "bougnoule", "youpin", "tranny", "retarded",
        "fuck", "motherfucker", "bitch", "pussy", "penis", "vagina",
        "porn", "hentai", "blowjob", "handjob", "pedophil", "killyourself",
        "salope", "connard", "connasse", "encule", "niquetamere", "niquetarace",
        "filsdepute", "suceuse", "hurensohn", "fotze", "schwuchtel", "wichser",
        "arschloch", "hijodeputa", "putamadre", "maricon", "pendejo", "mierda",
        "vaffanculo", "stronzo", "frocio", "cazzo", "caralho", "buceta",
        "kurwa", "blyat", "pidor", "pidar", "siktir", "orospu",
    ]

    /// Refusé seulement si le @ est exactement ce terme, chiffres mis à part : mots courts ou
    /// présents dans des prénoms et des mots innocents (Nazir, Essex, Violette, SophiaMartin).
    private static let exact: Set<String> = [
        "sophia", "sophiaapp", "sophiaofficial", "sophiaofficiel", "sophiateam", "sophiasupport",
        "admin", "administrator", "administrateur", "support", "moderator", "moderateur",
        "staff", "official", "officiel", "system", "root", "null",
        "nazi", "nazis", "isis", "stalin", "staline", "petain",
        "polpot", "pedo", "pede", "negro", "negre", "kike",
        "chink", "spic", "fag", "cunt", "slut", "whore",
        "rape", "rapist", "viol", "violeur", "sex", "sexe",
        "sexy", "xxx", "nude", "nudes", "shit", "pute",
        "putes", "puta", "puto", "bite", "chatte", "couille",
        "couilles", "ntm", "fdp", "tapette", "bicot", "cabron",
        "joder", "foda", "viado", "suka", "amk", "kys",
        "suicide",
    ]

    private static let leet: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
    ]

    /// `handle` : le @ déjà nettoyé (minuscules, lettres et chiffres).
    static func isAllowed(_ handle: String) -> Bool {
        let cleaned = handle.lowercased()
        // Le @ « déguisé » remis à plat (h1tl3r → hitler), et le @ sans ses chiffres.
        let unleeted = String(cleaned.map { leet[$0] ?? $0 }.filter { !$0.isNumber })
        let letters = cleaned.filter { !$0.isNumber }
        if exact.contains(unleeted) || exact.contains(letters) { return false }
        return !contains.contains { unleeted.contains($0) || letters.contains($0) }
    }
}
