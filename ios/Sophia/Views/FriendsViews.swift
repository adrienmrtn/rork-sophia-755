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

    var onAdded: () -> Void

    @State private var draft: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

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

                    Spacer()

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

    @State private var stats: FriendPublicStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showRemoveConfirm = false
    @State private var isRemoving = false

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.jakarta(size: 15, weight: .semibold))
                                .foregroundStyle(DS.inkSecondary)
                                .frame(width: 40, height: 40)
                                .background(DS.surface, in: Circle())
                                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                        }
                        Spacer()
                        Text("@\(stats?.handle ?? fallbackHandle)")
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
                    } else if let stats {
                        identityCard(stats)
                        statsGrid(stats)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(DS.sans(.subheadline, .medium))
                            .foregroundStyle(DS.danger)
                            .padding(.horizontal, 20)
                    }

                    if stats != nil {
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

    private func identityCard(_ stats: FriendPublicStats) -> some View {
        let progress = ProgressManager.globalLevelProgress(for: stats.globalXP)
        return VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                GlobalRankRing(progress: progress, size: 88)

                VStack(alignment: .leading, spacing: 6) {
                    Text(progress.rank.localizedName(language: languageManager.current).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.2)

                    Text("@\(stats.handle)")
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)

                    Text(String(format: languageManager.text("common.levelShort"), progress.level))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                CalmProgressBar(fraction: progress.progressToNextRank)
                HStack {
                    Text("\(stats.globalXP) XP")
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

    private func statsGrid(_ stats: FriendPublicStats) -> some View {
        HStack(spacing: 14) {
            friendStatTile(
                icon: "flame.fill",
                value: "\(stats.streak)",
                label: languageManager.text("friends.stats.streak")
            )
            friendStatTile(
                icon: "checkmark.circle",
                value: "\(stats.coursesCompleted)",
                label: languageManager.text("profile.stats.coursesDone")
            )
            friendStatTile(
                icon: "target",
                value: "\(stats.quizzesCompleted)",
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

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            stats = try await SocialService.shared.friendStats(userId: userId)
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

struct FriendsLeaderboardSection: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Bindable var social: SocialService

    @State private var showAddFriend = false
    @State private var showEditHandle = false
    @State private var selectedFriend: FriendLeaderboardEntry?
    @State private var hapticTrigger = 0
    @State private var respondingIds: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(languageManager.text("friends.title"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.1)
                Spacer()
                if auth.isSignedIn {
                    Button {
                        hapticTrigger += 1
                        showAddFriend = true
                    } label: {
                        Label(languageManager.text("friends.add.short"), systemImage: "person.badge.plus")
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.accentSoft)
                    }
                }
            }

            if !auth.isSignedIn {
                signedOutCard
            } else {
                if !social.pendingRequests.isEmpty {
                    requestsCard
                }
                periodPicker
                leaderboardCard
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn {
                await social.refreshPendingRequests()
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet {
                Task {
                    await social.refreshLeaderboard()
                    await social.refreshPendingRequests()
                }
            }
            .presentationDetents([.medium])
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
        .navigationDestination(item: $selectedFriend) { entry in
            FriendProfileView(userId: entry.userId, fallbackHandle: entry.handle)
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
            Image(systemName: "person.crop.circle")
                .font(.jakarta(size: 26, weight: .regular))
                .foregroundStyle(DS.inkTertiary)

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

    private var leaderboardCard: some View {
        VStack(spacing: 0) {
            if social.isLoadingLeaderboard && social.leaderboard.isEmpty {
                ProgressView()
                    .padding(24)
                    .frame(maxWidth: .infinity)
            } else if social.leaderboard.filter({ !$0.isMe }).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.text("friends.empty.title"))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("friends.empty.body"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            } else {
                ForEach(Array(social.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Rectangle().fill(DS.hairline).frame(height: 1)
                    }
                    leaderboardRow(rank: index + 1, entry: entry)
                }
            }
        }
        .dsCard(padding: 0)
    }

    private func leaderboardRow(rank: Int, entry: FriendLeaderboardEntry) -> some View {
        Button {
            guard !entry.isMe else {
                showEditHandle = true
                return
            }
            hapticTrigger += 1
            selectedFriend = entry
        } label: {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .frame(width: 22, alignment: .leading)
                    .monospacedDigit()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("@\(entry.handle)")
                            .font(DS.sans(.body, .semibold))
                            .foregroundStyle(DS.ink)
                        if entry.isMe {
                            Text(languageManager.text("friends.you"))
                                .font(DS.sans(.caption2, .semibold))
                                .foregroundStyle(DS.accentSoft)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DS.accentTint, in: Capsule())
                        }
                    }
                }

                Spacer()

                Text("\(entry.xp) XP")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()

                if !entry.isMe {
                    Image(systemName: "chevron.right")
                        .font(.jakarta(size: 12, weight: .semibold))
                        .foregroundStyle(DS.inkTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(ProfileCardPress())
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
