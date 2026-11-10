import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI
import UIKit

// Ajouter un ami par QR code : « Mon QR code » (le lien `sophia://friend/<handle>` dessiné en
// QR), le scanner (caméra), et la feuille qui confirme un lien d'ami ouvert depuis l'extérieur.
// La demande part par `SocialService.sendFriendRequest`, comme la saisie du @.

// MARK: - Génération du QR code

enum FriendQRCode {
    /// Bleu marine sur crème : les couleurs des illustrations du site.
    static let ink = UIColor(red: 0.102, green: 0.227, blue: 0.420, alpha: 1)
    static let paper = UIColor(red: 0.984, green: 0.969, blue: 0.937, alpha: 1)

    /// Le QR code d'un texte, en pixels nets (à afficher avec `.interpolation(.none)`).
    static func image(for text: String, side: CGFloat = 720) -> UIImage? {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(text.utf8)
        generator.correctionLevel = "M"
        guard let modules = generator.outputImage, modules.extent.width > 0 else { return nil }

        let colors = CIFilter.falseColor()
        colors.inputImage = modules
        colors.color0 = CIColor(color: ink)
        colors.color1 = CIColor(color: paper)
        guard let tinted = colors.outputImage else { return nil }

        // Un facteur entier : chaque module garde des bords nets.
        let scale = max(1, floor(side / modules.extent.width))
        let scaled = tinted.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let rendered = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: rendered)
    }
}

// MARK: - Envoi de la demande

/// Le résultat d'une demande d'ami, déjà traduit pour l'écran.
struct FriendRequestFeedback: Equatable {
    let success: Bool
    let message: String
}

enum FriendRequestFlow {
    /// Envoie la demande au @ donné et rend le message à afficher (envoyée, déjà amis, erreur).
    static func send(handle: String, languageManager: LanguageManager) async -> FriendRequestFeedback {
        do {
            let outcome = try await SocialService.shared.sendFriendRequest(handle: handle)
            switch outcome {
            case .sent:
                return FriendRequestFeedback(success: true, message: languageManager.text("friends.request.sent"))
            case .accepted:
                return FriendRequestFeedback(success: true, message: languageManager.text("friends.request.autoAccepted"))
            }
        } catch let error as SocialError {
            return FriendRequestFeedback(success: false, message: error.localizedMessage(languageManager: languageManager))
        } catch {
            return FriendRequestFeedback(success: false, message: languageManager.text("friends.error.generic"))
        }
    }
}

// MARK: - Mon QR code

/// Mon QR code, sur une carte « papier » : avatar, @, le code, et l'accès au scanner.
struct MyFriendQRSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    var avatarId: String? = nil
    /// Appelé après une demande envoyée depuis le scanner ouvert d'ici.
    var onAdded: () -> Void = {}

    @State private var qrImage: UIImage?
    @State private var showScanner = false

    private var handle: String? {
        guard let handle = SocialService.shared.myHandle, !handle.isEmpty else { return nil }
        return handle
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(languageManager.text("profile.qr.mine"))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                    Spacer(minLength: 8)
                    RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                }

                paperCard
                    .padding(.top, 30)

                Text(languageManager.text("profile.qr.mine.hint"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showScanner = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                        Text(languageManager.text("profile.qr.scan.title"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .buttonStyle(DSSecondaryButtonStyle())
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .task(id: handle) {
            guard let handle, let url = SophiaDeepLink.friendURL(for: handle) else {
                qrImage = nil
                return
            }
            qrImage = FriendQRCode.image(for: url.absoluteString)
        }
        .sheet(isPresented: $showScanner) {
            FriendQRScannerSheet(onAdded: onAdded)
                .sophiaSheetChrome()
        }
    }

    /// La carte crème au liseré marine, posée sur un aplat safran décalé (papier découpé).
    private var paperCard: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let navy = Color(uiColor: FriendQRCode.ink)
        return VStack(spacing: 14) {
            Text(handle.map { "@\($0)" } ?? "@")
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(navy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 36)

            Group {
                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Text(languageManager.text("profile.qr.mine")))
                } else {
                    ProgressView()
                        .tint(navy)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: 230)
            .aspectRatio(1, contentMode: .fit)

            Text("Sophia")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(navy.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
        .background(shape.fill(Color(uiColor: FriendQRCode.paper)))
        .overlay(shape.strokeBorder(navy, lineWidth: 2))
        .background(
            shape
                .fill(DuelPalette.saffron)
                .offset(x: 7, y: 8)
        )
        .overlay(alignment: .top) {
            AvatarCircle(avatarId: avatarId, initial: String((handle ?? "S").prefix(1)).uppercased(), size: 64)
                .overlay(Circle().strokeBorder(navy, lineWidth: 2))
                .background(Circle().fill(DuelPalette.saffron).offset(x: 3, y: 4))
                .offset(y: -32)
        }
        .padding(.trailing, 7)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scanner

/// Le scanner : la caméra dans un cadre, puis la demande d'ami et sa confirmation. Caméra
/// refusée : un bouton vers les Réglages. Pas de caméra (simulateur) : un simple message.
struct FriendQRScannerSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// Appelé quand une demande est partie (ou acceptée), pour rafraîchir le classement.
    var onAdded: () -> Void = {}

    private enum CameraState { case checking, ready, denied, unavailable }

    private enum Phase: Equatable {
        case scanning
        case sending(handle: String)
        case finished(handle: String, feedback: FriendRequestFeedback)
    }

    @State private var camera: CameraState = .checking
    @State private var phase: Phase = .scanning
    @State private var showInvalid = false
    /// Le dernier code refusé et son heure : la caméra relit le même code plusieurs fois par seconde.
    @State private var lastRejected: String?
    @State private var lastRejectedAt = Date.distantPast

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(languageManager.text("profile.qr.scan.title"))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 8)
                    RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                }

                viewfinder

                footer
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .task { await prepareCamera() }
    }

    // MARK: Cadre

    private var viewfinder: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return ZStack {
            shape.fill(DuelPalette.night)
            switch phase {
            case .scanning:
                scanningContent
            case .sending(let handle):
                VStack(spacing: 14) {
                    ProgressView().tint(.white)
                    Text("@\(handle)")
                        .font(DS.title(.title3, .heavy))
                        .foregroundStyle(.white)
                }
            case .finished(let handle, let feedback):
                VStack(spacing: 12) {
                    Image(systemName: feedback.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(feedback.success ? DuelPalette.saffron : DuelPalette.coral)
                    Text("@\(handle)")
                        .font(DS.title(.title3, .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(feedback.message)
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: 360)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(shape)
        .overlay(shape.strokeBorder(DS.hairline, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var scanningContent: some View {
        switch camera {
        case .checking:
            ProgressView().tint(.white)
        case .ready:
            QRScannerPreview(onCode: handleCode)
            // Le viseur : un cadre safran au milieu de l'image.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(DuelPalette.saffron, lineWidth: 3)
                .padding(44)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            if showInvalid {
                VStack {
                    Spacer()
                    Text(languageManager.text("profile.qr.invalid"))
                        .font(DS.sans(.footnote, .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.black.opacity(0.7)))
                        .padding(14)
                }
                .transition(.opacity)
            }
        case .denied:
            cameraMessage(
                systemImage: "video.slash.fill",
                title: languageManager.text("profile.qr.camera.denied.title"),
                body: languageManager.text("profile.qr.camera.denied.body")
            )
        case .unavailable:
            cameraMessage(
                systemImage: "camera.fill",
                title: languageManager.text("profile.qr.camera.unavailable"),
                body: nil
            )
        }
    }

    private func cameraMessage(systemImage: String, title: String, body: String?) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(DuelPalette.saffron)
            Text(title)
                .font(DS.sans(.headline, .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let body {
                Text(body)
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
    }

    // MARK: Sous le cadre

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .scanning:
            if camera == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Text(languageManager.text("tiktokBlocker.notifications.open"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
            } else if camera != .unavailable {
                Text(languageManager.text("profile.qr.scan.hint"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
        case .sending:
            EmptyView()
        case .finished:
            VStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text(languageManager.text("common.close"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    lastRejected = nil
                    phase = .scanning
                } label: {
                    Text(languageManager.text("profile.qr.scanAgain"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .buttonStyle(DSSecondaryButtonStyle())
            }
        }
    }

    // MARK: Actions

    private func prepareCamera() async {
        guard AVCaptureDevice.default(for: .video) != nil else {
            camera = .unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            camera = .ready
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            camera = granted ? .ready : .denied
        default:
            camera = .denied
        }
    }

    private func handleCode(_ text: String) {
        guard phase == .scanning else { return }
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let handle = SophiaDeepLink.friendHandle(from: url) else {
            rejectCode(text)
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) {
            showInvalid = false
            phase = .sending(handle: handle)
        }
        Task {
            let feedback = await FriendRequestFlow.send(handle: handle, languageManager: languageManager)
            if feedback.success {
                onAdded()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .finished(handle: handle, feedback: feedback)
            }
        }
    }

    /// Un QR code qui n'est pas un code ami : un mot, puis le scan continue.
    private func rejectCode(_ text: String) {
        let now = Date()
        if lastRejected == text, now.timeIntervalSince(lastRejectedAt) < 2.5 { return }
        lastRejected = text
        lastRejectedAt = now
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        withAnimation(.easeInOut(duration: 0.2)) { showInvalid = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if Date().timeIntervalSince(lastRejectedAt) >= 2.4 {
                withAnimation(.easeInOut(duration: 0.2)) { showInvalid = false }
            }
        }
    }
}

// MARK: - Caméra (AVFoundation)

/// L'aperçu de la caméra, qui rend le texte de chaque QR code vu.
private struct QRScannerPreview: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ controller: QRScannerController, context: Context) {
        controller.onCode = onCode
    }
}

/// La session de capture réduite à la lecture des QR codes. Sans caméra utilisable (simulateur),
/// rien n'est configuré et la vue reste noire.
final class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?

    private let session = AVCaptureSession()
    /// `startRunning` bloque : la session démarre et s'arrête hors du fil principal.
    private let sessionQueue = DispatchQueue(label: "sophia.friend-qr.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setRunning(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setRunning(false)
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        let output = AVCaptureMetadataOutput()
        session.beginConfiguration()
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        // Les types ne se règlent qu'une fois la sortie reliée à la session.
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if output.availableMetadataObjectTypes.contains(.qr) {
            output.metadataObjectTypes = [.qr]
        }
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        isConfigured = true
    }

    private func setRunning(_ running: Bool) {
        guard isConfigured else { return }
        let session = self.session
        sessionQueue.async {
            if running {
                if !session.isRunning { session.startRunning() }
            } else if session.isRunning {
                session.stopRunning()
            }
        }
    }

    // Appelé sur le fil principal (file donnée à `setMetadataObjectsDelegate`).
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let code = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              code.type == .qr,
              let text = code.stringValue else { return }
        onCode?(text)
    }
}

// MARK: - Lien d'ami ouvert depuis l'extérieur

/// `sophia://friend/<handle>` ouvert hors de l'app (appareil photo, lien) : la demande n'est
/// envoyée qu'après un geste du lecteur, pour qu'un lien ne puisse pas en envoyer à sa place.
struct FriendLinkSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let handle: String
    var onAdded: () -> Void = {}

    @State private var isSending = false
    @State private var feedback: FriendRequestFeedback?

    var body: some View {
        VStack(spacing: 14) {
            AvatarCircle(avatarId: nil, initial: String(handle.prefix(1)).uppercased(), size: 72)
                .padding(.top, 30)
            Text(String(format: languageManager.text("profile.friendLink.title"), handle))
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let feedback {
                Text(feedback.message)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(feedback.success ? DS.success : DS.danger)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if feedback?.success == true {
                Button {
                    dismiss()
                } label: {
                    Text(languageManager.text("common.close"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
            } else {
                Button {
                    send()
                } label: {
                    HStack(spacing: 8) {
                        if isSending { ProgressView().tint(.white) }
                        Text(languageManager.text("friends.request.send"))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .disabled(isSending)
                Button {
                    dismiss()
                } label: {
                    Text(languageManager.text("settings.reset.alert.cancel"))
                }
                .buttonStyle(DSSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.canvas.ignoresSafeArea())
    }

    private func send() {
        guard !isSending else { return }
        isSending = true
        Task {
            let result = await FriendRequestFlow.send(handle: handle, languageManager: languageManager)
            if result.success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onAdded()
            }
            withAnimation(.easeInOut(duration: 0.2)) { feedback = result }
            isSending = false
        }
    }
}
