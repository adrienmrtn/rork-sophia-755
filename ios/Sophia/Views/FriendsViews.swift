import SwiftUI

// MARK: - Edit handle

struct EditHandleSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let currentHandle: String
    var onSaved: (String) -> Void

    @State private var draft: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Text(languageManager.text("friends.handle.edit.subtitle"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text("@")
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(DS.inkTertiary)
                        TextField(languageManager.text("friends.handle.placeholder"), text: $draft)
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(DS.ink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                    }
                    .padding(16)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                            .strokeBorder(DS.hairline, lineWidth: 1)
                    }

                    Text(languageManager.text("friends.handle.rules"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkTertiary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.footnote, .medium))
                            .foregroundStyle(DS.danger)
                    }

                    Spacer()

                    Button {
                        save()
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.white) }
                            Text(languageManager.text("friends.handle.save"))
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(isSaving || sanitizedDraft.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle(languageManager.text("friends.handle.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.text("settings.reset.alert.cancel")) { dismiss() }
                }
            }
            .onAppear {
                draft = currentHandle
            }
        }
        .sophiaSheetChrome()
    }

    private var sanitizedDraft: String {
        draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let updated = try await SocialService.shared.updateHandle(sanitizedDraft)
                onSaved(updated)
                dismiss()
            } catch let error as SocialError {
                errorMessage = error.localizedMessage(languageManager: languageManager)
            } catch {
                errorMessage = languageManager.text("friends.error.generic")
            }
            isSaving = false
        }
    }
}

// MARK: - Add friend

struct AddFriendSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    /// L'avatar du lecteur, pour sa carte « Mon QR code ».
    var myAvatarId: String? = nil
    var onAdded: () -> Void

    @State private var draft: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showMyQR = false
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    Text(languageManager.text("friends.add.requestSubtitle"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text("@")
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(DS.inkTertiary)
                        TextField(languageManager.text("friends.handle.placeholder"), text: $draft)
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(DS.ink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .onSubmit { add() }
                    }
                    .padding(16)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                            .strokeBorder(DS.hairline, lineWidth: 1)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.footnote, .medium))
                            .foregroundStyle(DS.danger)
                    }
                    if let successMessage {
                        Text(successMessage)
                            .font(DS.sans(.footnote, .medium))
                            .foregroundStyle(DS.success)
                    }

                    // Sans taper de @ : montrer son QR code, ou scanner celui de l'ami.
                    HStack(spacing: 10) {
                        FriendQRActionButton(systemImage: "qrcode", title: languageManager.text("profile.qr.mine")) {
                            showMyQR = true
                        }
                        FriendQRActionButton(systemImage: "qrcode.viewfinder", title: languageManager.text("profile.qr.scan")) {
                            showScanner = true
                        }
                    }

                    Spacer(minLength: 0)

                    Button { add() } label: {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.white) }
                            Text(languageManager.text("friends.request.send"))
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(isSaving || sanitized.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle(languageManager.text("friends.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.text("settings.reset.alert.cancel")) { dismiss() }
                }
            }
            .sheet(isPresented: $showMyQR) {
                MyFriendQRSheet(avatarId: myAvatarId, onAdded: onAdded)
                    .sophiaSheetChrome()
            }
            .sheet(isPresented: $showScanner) {
                FriendQRScannerSheet(onAdded: onAdded)
                    .sophiaSheetChrome()
            }
        }
        .sophiaSheetChrome()
    }

    private var sanitized: String {
        draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    private func add() {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                let outcome = try await SocialService.shared.sendFriendRequest(handle: sanitized)
                switch outcome {
                case .sent:
                    successMessage = languageManager.text("friends.request.sent")
                case .accepted:
                    successMessage = languageManager.text("friends.request.autoAccepted")
                }
                onAdded()
                try? await Task.sleep(nanoseconds: 900_000_000)
                dismiss()
            } catch let error as SocialError {
                errorMessage = error.localizedMessage(languageManager: languageManager)
            } catch {
                errorMessage = languageManager.text("friends.error.generic")
            }
            isSaving = false
        }
    }
}

// MARK: - Friend profile

struct FriendProfileView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let userId: UUID
    let fallbackHandle: String

    @State private var profile: FriendProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showRemoveConfirm = false
    @State private var isRemoving = false

    /// Trophées, ligue et défi n'ont de sens que là où les duels existent.
    private var duelsVisible: Bool { FeatureFlags.duelsVisible(language: languageManager.current) }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .font(.jakarta(size: 15, weight: .semibold))
                                .foregroundStyle(DS.inkSecondary)
                                .frame(width: 40, height: 40)
                                .background(DS.surface, in: Circle())
                                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                        }
                        Spacer()
                        Text("@\(profile?.handle ?? fallbackHandle)")
                            .font(DS.sans(.headline, .semibold))
                            .foregroundStyle(DS.ink)
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let profile {
                        identityCard(profile)
                        if duelsVisible {
                            if profile.canChallenge {
                                challengeButton(profile)
                            }
                            duelCard(profile)
                        }
                        statsGrid(profile)
                        badgesSection(profile)
                        followingSection(profile)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.subheadline, .medium))
                            .foregroundStyle(DS.danger)
                            .padding(.horizontal, 20)
                    }

                    if profile != nil {
                        Button(role: .destructive) {
                            showRemoveConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                if isRemoving { ProgressView() }
                                Text(languageManager.text("friends.remove"))
                            }
                        }
                        .buttonStyle(DSSecondaryButtonStyle())
                        .padding(.horizontal, 20)
                        .disabled(isRemoving)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .alert(languageManager.text("friends.remove.title"), isPresented: $showRemoveConfirm) {
            Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) {}
            Button(languageManager.text("friends.remove.confirm"), role: .destructive) {
                removeFriend()
            }
        } message: {
            Text(languageManager.text("friends.remove.message"))
        }
        .task { await load() }
    }

    private func identityCard(_ profile: FriendProfile) -> some View {
        let progress = ProgressManager.globalLevelProgress(for: profile.globalXP)
        return VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                Group {
                    if Avatars.isValid(profile.avatarId) {
                        AvatarCircle(avatarId: profile.avatarId, initial: String(profile.handle.prefix(1)).uppercased(), size: 88)
                    } else {
                        GlobalRankRing(progress: progress, size: 88)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if profile.online {
                        DuelOnlineDot(size: 18)
                            .offset(x: -3, y: -3)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(progress.rank.localizedName(language: languageManager.current).uppercasedInApp())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.2)

                    Text("@\(profile.handle)")
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)

                    Text(String(format: languageManager.text("common.levelShort"), progress.level))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)

                    if let presence = presenceText(profile) {
                        Text(presence)
                            .font(DS.sans(.footnote, .medium))
                            .foregroundStyle(profile.online ? DS.success : DS.inkTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                CalmProgressBar(fraction: progress.progressToNextRank)
                HStack {
                    Text("\(profile.globalXP) XP")
                        .font(DS.sans(.caption2, .medium))
                        .foregroundStyle(DS.inkTertiary)
                    Spacer()
                    Text("\(Int(progress.progressToNextRank * 100))%")
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                        .monospacedDigit()
                }
            }
        }
        .dsCard()
        .padding(.horizontal, 20)
    }

    /// Les badges que l'ami a choisi d'afficher (trois au plus). Rien s'il n'en affiche aucun.
    @ViewBuilder
    private func badgesSection(_ profile: FriendProfile) -> some View {
        let badges = (profile.featuredBadges ?? []).prefix(3).compactMap { BadgeCatalog.badge(id: $0) }
        if !badges.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(languageManager.text("profile.badges"))
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(DS.ink)
                BadgeRow(badges: Array(badges))
            }
            .padding(.horizontal, 20)
        }
    }

    /// « En ligne », ou « Vu il y a 5 minutes » : la durée est écrite par le système dans la
    /// langue de l'app. Rien quand le serveur ne sait pas (ami jamais vu, ancienne base).
    private func presenceText(_ profile: FriendProfile) -> String? {
        if profile.online { return languageManager.text("duel.friend.online") }
        guard let seconds = profile.lastSeenSeconds else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = languageManager.locale
        formatter.unitsStyle = .full
        // Sous la minute, « il y a 1 minute » plutôt qu'un compte de secondes.
        let ago = formatter.localizedString(fromTimeInterval: -Double(max(seconds, 60)))
        return String(format: languageManager.text("friends.lastSeen"), ago)
    }

    /// « Défier en duel » : un duel amical, sans trophées en jeu. L'ami a 15 secondes pour
    /// rejoindre ; la ligne du dessous dit s'il a l'app ouverte en ce moment.
    private func challengeButton(_ profile: FriendProfile) -> some View {
        VStack(spacing: 8) {
            Button {
                DuelHaptics.countdown(final: true)
                DuelFriendPresenter.present(.challenge(userId: profile.userId, handle: profile.handle, avatarId: profile.avatarId))
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .heavy))
                    Text(languageManager.text("duel.friend.challenge"))
                }
            }
            .buttonStyle(DuelPlayButtonStyle())

            HStack(spacing: 6) {
                if profile.online {
                    DuelOnlineDot(size: 10)
                }
                Text(languageManager.text(profile.online ? "duel.friend.online" : "duel.friend.offline"))
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(DS.inkSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
    }

    /// Sa ligue et ses trophées, ses duels, et le bilan de nos duels amicaux.
    private func duelCard(_ profile: FriendProfile) -> some View {
        let league = DuelService.shared.home?.league(position: profile.leaguePosition)
        let leagueTitle = league.map { DuelFormat.leagueName($0, language: languageManager.current) }
            ?? String(format: languageManager.text("duel.league.position"), profile.leaguePosition)
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                DuelLeagueBackdrop(league: league, thumb: true)
                LinearGradient(
                    colors: [DuelPalette.night.opacity(0.1), DuelPalette.night.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                HStack(alignment: .bottom) {
                    Text(leagueTitle)
                        .font(.jakarta(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 8)
                    DuelTrophyCount(value: profile.trophies, size: 18, color: .white)
                }
                .padding(14)
            }
            .frame(height: 116)
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                duelRow(label: "duel.stats.games", value: "\(profile.duelGames)")
                duelRow(label: "duel.stats.wins", value: "\(profile.duelWins)")
                duelRow(label: "duel.stats.best", value: profile.bestTrophies.formatted(language: languageManager.current))
                if profile.friendlyPlayed > 0 {
                    Rectangle().fill(DS.hairline).frame(height: 1)
                    duelRow(
                        label: "duel.friend.headToHead",
                        value: "\(profile.friendlyWon) – \(profile.friendlyLost)"
                    )
                }
            }
            .padding(16)
        }
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        )
        .dsSoftShadow()
        .padding(.horizontal, 20)
    }

    private func duelRow(label: String, value: String) -> some View {
        HStack {
            Text(languageManager.text(label))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(DS.sans(.subheadline, .bold))
                .monospacedDigit()
                .foregroundStyle(DS.ink)
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func statsGrid(_ profile: FriendProfile) -> some View {
        HStack(spacing: 14) {
            friendStatTile(
                icon: "flame.fill",
                value: "\(profile.streak)",
                label: languageManager.text("friends.stats.streak")
            )
            friendStatTile(
                icon: "checkmark.circle",
                value: "\(profile.coursesCompleted)",
                label: languageManager.text("profile.stats.coursesDone")
            )
            friendStatTile(
                icon: "target",
                value: "\(profile.quizzesCompleted)",
                label: languageManager.text("friends.stats.quizzes")
            )
        }
        .padding(.horizontal, 20)
    }

    private func friendStatTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.jakarta(size: 15, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 34, height: 34)
                .background(DS.accentTint, in: Circle())
            Text(value)
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
            Text(label)
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .dsCard(padding: 14)
    }

    /// Les créateurs qu'il suit ; toucher un créateur ouvre sa page.
    @ViewBuilder
    private func followingSection(_ profile: FriendProfile) -> some View {
        let authors = profile.follows.compactMap { AuthorStore.author(slug: $0) }
        if !authors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(languageManager.text("home.segment.following")) · \(authors.count)")
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.1)
                    .padding(.horizontal, 20)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(authors) { author in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                DeepLinkRouter.shared.requestCreator(author.slug)
                            } label: {
                                VStack(spacing: 8) {
                                    AuthorAvatarView(author: author, size: 64)
                                    Text(author.name)
                                        .font(DS.sans(.caption, .semibold))
                                        .foregroundStyle(DS.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 76)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await DuelLiveService.shared.friendProfile(userId: userId)
        } catch let error as SocialError {
            errorMessage = error.localizedMessage(languageManager: languageManager)
        } catch {
            errorMessage = languageManager.text("friends.error.generic")
        }
        isLoading = false
    }

    private func removeFriend() {
        isRemoving = true
        Task {
            do {
                try await SocialService.shared.removeFriend(userId: userId)
                dismiss()
            } catch {
                errorMessage = languageManager.text("friends.error.generic")
            }
            isRemoving = false
        }
    }
}

// MARK: - Friends leaderboard section (embedded in Profile)

/// Le classement des amis, à même le profil : un podium pour les trois premiers (avec leurs
/// avatars), les rangs suivants en lignes, la ligne du lecteur mise en avant, puis les actions
/// pour ajouter un ami (par @, par QR code, en scannant).
struct FriendsLeaderboardSection: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Bindable var social: SocialService
    /// L'avatar du lecteur, lu sur l'appareil (plus frais que celui du serveur).
    var myAvatarId: String? = nil

    @State private var showAddFriend = false
    @State private var showEditHandle = false
    @State private var showMyQR = false
    @State private var showScanner = false
    @State private var selectedFriend: FriendLeaderboardEntry?
    @State private var hapticTrigger = 0
    @State private var respondingIds: Set<UUID> = []

    /// Avatars et présence des amis : le classement des trophées (`duel_friends_leaderboard`)
    /// les porte déjà pour le même groupe (moi et mes amis) ; celui des XP n'a que les @.
    private var duelRows: [UUID: DuelLeaderboardEntry] {
        DuelService.shared.leaderboard.reduce(into: [:]) { $0[$1.userId] = $1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NewGenSectionTitle(text: languageManager.text("profile.friends.title"))

            if !auth.isSignedIn {
                signedOutCard
            } else {
                if !social.pendingRequests.isEmpty {
                    requestsCard
                }
                periodPicker
                leaderboardCard
                addActions
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn {
                await social.refreshPendingRequests()
            }
        }
        // Les avatars : relus à l'arrivée et quand le nombre d'amis change.
        .task(id: avatarRefreshKey) {
            if auth.isSignedIn {
                await DuelService.shared.refreshLeaderboard()
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet(myAvatarId: myAvatarId) {
                refreshAfterAdd()
            }
            .presentationDetents([.medium, .large])
            .sophiaSheetChrome()
        }
        .sheet(isPresented: $showEditHandle) {
            if let handle = social.myHandle {
                EditHandleSheet(currentHandle: handle) { _ in
                    Task { await social.refreshAll() }
                }
                .presentationDetents([.medium])
                .sophiaSheetChrome()
            }
        }
        .sheet(isPresented: $showMyQR) {
            MyFriendQRSheet(avatarId: resolvedMyAvatarId) {
                refreshAfterAdd()
            }
            .sophiaSheetChrome()
        }
        .sheet(isPresented: $showScanner) {
            FriendQRScannerSheet {
                refreshAfterAdd()
            }
            .sophiaSheetChrome()
        }
        .navigationDestination(item: $selectedFriend) { entry in
            FriendProfileView(userId: entry.userId, fallbackHandle: entry.handle)
        }
    }

    private var avatarRefreshKey: String {
        "\(auth.isSignedIn)-\(social.leaderboard.count)"
    }

    private var resolvedMyAvatarId: String? {
        if let myAvatarId { return myAvatarId }
        return DuelService.shared.leaderboard.first(where: { $0.isMe })?.avatarId
    }

    private func refreshAfterAdd() {
        Task {
            await social.refreshLeaderboard()
            await social.refreshPendingRequests()
        }
    }

    private func avatarId(for entry: FriendLeaderboardEntry) -> String? {
        if entry.isMe, let myAvatarId { return myAvatarId }
        return duelRows[entry.userId]?.avatarId
    }

    private func isOnline(_ entry: FriendLeaderboardEntry) -> Bool {
        !entry.isMe && (duelRows[entry.userId]?.online ?? false)
    }

    private func open(_ entry: FriendLeaderboardEntry) {
        hapticTrigger += 1
        if entry.isMe {
            showEditHandle = true
        } else {
            selectedFriend = entry
        }
    }

    // MARK: Ajouter un ami

    /// « Ajouter un ami » en bouton principal, puis « Mon QR code » et « Scanner ».
    private var addActions: some View {
        VStack(spacing: 10) {
            Button {
                hapticTrigger += 1
                showAddFriend = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 17, weight: .bold))
                    Text(languageManager.text("friends.add.title"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())

            HStack(spacing: 10) {
                FriendQRActionButton(systemImage: "qrcode", title: languageManager.text("profile.qr.mine")) {
                    hapticTrigger += 1
                    showMyQR = true
                }
                FriendQRActionButton(systemImage: "qrcode.viewfinder", title: languageManager.text("profile.qr.scan")) {
                    hapticTrigger += 1
                    showScanner = true
                }
            }
        }
    }

    private var signedOutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.text("friends.signedOut.title"))
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)
            Text(languageManager.text("friends.signedOut.body"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    // MARK: Demandes reçues

    private var requestsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(languageManager.text("friends.requests.title"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.0)
                Spacer()
                Text("\(social.pendingRequests.count)")
                    .font(DS.sans(.caption2, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(DS.accent, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ForEach(Array(social.pendingRequests.enumerated()), id: \.element.id) { index, request in
                if index > 0 {
                    Rectangle().fill(DS.hairline).frame(height: 1)
                }
                requestRow(request)
            }
            .padding(.bottom, 6)
        }
        .dsCard(padding: 0)
    }

    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            AvatarCircle(avatarId: nil, initial: String(request.handle.prefix(1)).uppercased(), size: 38)

            Text("@\(request.handle)")
                .font(DS.sans(.body, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                respond(request, accept: false)
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 14, weight: .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 38, height: 38)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .disabled(respondingIds.contains(request.requestId))
            .accessibilityLabel(Text(languageManager.text("friends.requests.decline")))

            Button {
                respond(request, accept: true)
            } label: {
                Image(systemName: "checkmark")
                    .font(.jakarta(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(DS.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(respondingIds.contains(request.requestId))
            .accessibilityLabel(Text(languageManager.text("friends.requests.accept")))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func respond(_ request: FriendRequest, accept: Bool) {
        guard !respondingIds.contains(request.requestId) else { return }
        hapticTrigger += 1
        respondingIds.insert(request.requestId)
        Task {
            try? await social.respondToRequest(requestId: request.requestId, accept: accept)
            respondingIds.remove(request.requestId)
        }
    }

    // MARK: Période

    private var periodPicker: some View {
        HStack(spacing: 8) {
            periodChip(.week, label: languageManager.text("friends.period.week"))
            periodChip(.all, label: languageManager.text("friends.period.all"))
            Spacer()
        }
    }

    private func periodChip(_ period: FriendsLeaderboardPeriod, label: String) -> some View {
        let selected = social.period == period
        return Button {
            hapticTrigger += 1
            Task { await social.setPeriod(period) }
        } label: {
            Text(label)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(selected ? .white : DS.inkSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? DS.accent : DS.surface, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(selected ? Color.clear : DS.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Classement

    private var leaderboardCard: some View {
        let entries = social.leaderboard
        let hasFriends = entries.contains { !$0.isMe }
        // Un podium demande trois personnes ; à deux, de simples lignes médaillées.
        let podiumEntries = entries.count >= 3 ? Array(entries.prefix(3)) : []
        let rowEntries = Array(entries.enumerated().dropFirst(podiumEntries.count))
        return VStack(spacing: 0) {
            if social.isLoadingLeaderboard && entries.isEmpty {
                ProgressView()
                    .padding(24)
                    .frame(maxWidth: .infinity)
            } else if !hasFriends {
                emptyState
            } else {
                if !podiumEntries.isEmpty {
                    podium(podiumEntries)
                }
                ForEach(rowEntries, id: \.element.id) { index, entry in
                    if index > 0 {
                        Rectangle().fill(DS.hairline).frame(height: 1)
                    }
                    leaderboardRow(rank: index + 1, entry: entry)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsCard(padding: 0)
    }

    private var emptyState: some View {
        HStack(alignment: .center, spacing: 14) {
            AvatarCircle(
                avatarId: resolvedMyAvatarId,
                initial: String((social.myHandle ?? "S").prefix(1)).uppercased(),
                size: 52
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("friends.empty.title"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("friends.empty.body"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    /// Or, argent, bronze : les couleurs des médailles des trois premiers rangs.
    private func medalColor(rank: Int) -> Color {
        switch rank {
        case 1: DuelPalette.saffron
        case 2: Color(red: 0.62, green: 0.67, blue: 0.74)
        default: Color(red: 0.80, green: 0.50, blue: 0.31)
        }
    }

    /// Le podium : le premier au centre, plus haut ; le deuxième à gauche, le troisième à droite.
    private func podium(_ top: [FriendLeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            podiumColumn(rank: 2, entry: top[1])
            podiumColumn(rank: 1, entry: top[0])
            podiumColumn(rank: 3, entry: top[2])
        }
        .padding(.horizontal, 12)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func podiumColumn(rank: Int, entry: FriendLeaderboardEntry) -> some View {
        let medal = medalColor(rank: rank)
        let avatarSize: CGFloat = rank == 1 ? 72 : 56
        let stepHeight: CGFloat = rank == 1 ? 62 : (rank == 2 ? 44 : 32)
        return Button {
            open(entry)
        } label: {
            VStack(spacing: 6) {
                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(medal)
                        .accessibilityHidden(true)
                }
                friendAvatar(entry, size: avatarSize, ring: medal)
                Text("@\(entry.handle)")
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(entry.isMe ? DS.accentSoft : DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, entry.isMe ? 8 : 0)
                    .padding(.vertical, entry.isMe ? 2 : 0)
                    .background {
                        if entry.isMe { Capsule().fill(DS.accentTint) }
                    }
                Text("\(entry.xp.formatted(language: languageManager.current)) XP")
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                // La marche du podium, à la couleur de la médaille.
                Text("\(rank)")
                    .font(DS.title(rank == 1 ? .title2 : .title3, .heavy))
                    .foregroundStyle(medal)
                    .frame(maxWidth: .infinity)
                    .frame(height: stepHeight)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 4,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 14,
                            style: .continuous
                        )
                        .fill(medal.opacity(0.2))
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(FriendRowPress())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("\(rank). @\(entry.handle), \(entry.xp) XP"))
    }

    /// L'avatar d'un ami (ses initiales s'il n'en a pas choisi), avec la pastille « en ligne ».
    private func friendAvatar(_ entry: FriendLeaderboardEntry, size: CGFloat, ring: Color? = nil) -> some View {
        AvatarCircle(avatarId: avatarId(for: entry), initial: String(entry.handle.prefix(1)).uppercased(), size: size)
            .overlay {
                if let ring {
                    Circle().strokeBorder(ring, lineWidth: max(2.5, size * 0.05))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isOnline(entry) {
                    DuelOnlineDot(size: max(11, size * 0.22))
                }
            }
    }

    private func leaderboardRow(rank: Int, entry: FriendLeaderboardEntry) -> some View {
        Button {
            open(entry)
        } label: {
            HStack(spacing: 12) {
                rankBadge(rank)

                friendAvatar(entry, size: 42)

                Text("@\(entry.handle)")
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if entry.isMe {
                    Text(languageManager.text("friends.you"))
                        .font(DS.sans(.caption2, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(DS.accent, in: Capsule())
                        .fixedSize()
                }

                Spacer(minLength: 6)

                Text("\(entry.xp.formatted(language: languageManager.current)) XP")
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(entry.isMe ? DS.ink : DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize()

                Image(systemName: "chevron.forward")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .opacity(entry.isMe ? 0 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            // La ligne du lecteur ressort sur un fond teinté.
            .background(entry.isMe ? DS.accentTint : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(FriendRowPress())
    }

    /// Le rang : une médaille pleine pour les trois premiers, un simple nombre ensuite.
    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(DS.sans(.footnote, .bold))
            .monospacedDigit()
            .foregroundStyle(rank <= 3 ? .white : DS.inkTertiary)
            .frame(width: 26, height: 26)
            .background {
                if rank <= 3 { Circle().fill(medalColor(rank: rank)) }
            }
    }
}

/// « Mon QR code », « Scanner » : un bouton secondaire avec son pictogramme.
struct FriendQRActionButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(DS.accent)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule(style: .continuous).fill(DS.surface))
            .overlay(Capsule(style: .continuous).strokeBorder(DS.accent.opacity(0.35), lineWidth: 1.5))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(FriendRowPress())
    }
}

/// Le retour au toucher des lignes et des boutons de la section des amis.
struct FriendRowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Errors

extension SocialError {
    @MainActor
    func localizedMessage(languageManager: LanguageManager) -> String {
        switch self {
        case .notSignedIn:
            return languageManager.text("friends.error.notSignedIn")
        case .invalidHandle:
            return languageManager.text("friends.error.invalidHandle")
        case .handleTaken:
            return languageManager.text("friends.error.handleTaken")
        case .handleNotAllowed:
            return languageManager.text("friends.error.handleNotAllowed")
        case .userNotFound:
            return languageManager.text("friends.error.userNotFound")
        case .cannotAddSelf:
            return languageManager.text("friends.error.cannotAddSelf")
        case .notFriends:
            return languageManager.text("friends.error.notFriends")
        case .alreadyFriends:
            return languageManager.text("friends.error.alreadyFriends")
        case .requestAlreadySent:
            return languageManager.text("friends.error.requestAlreadySent")
        case .requestNotFound:
            return languageManager.text("friends.error.requestNotFound")
        case .underlying:
            return languageManager.text("friends.error.generic")
        }
    }
}

extension FriendLeaderboardEntry: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
