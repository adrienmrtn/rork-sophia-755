import SwiftUI
import UIKit

/// Un onglet de `SophiaTabScaffold`.
struct SophiaTabItem: Identifiable {
    let value: Int
    let title: String
    let systemImage: String
    /// L'onglet reste en vie quand un autre est affiché : il garde son état et sa position de
    /// défilement. Les autres sont reconstruits à chaque visite, ce qui rejoue leur `onAppear`
    /// comme le fait la barre d'onglets du système.
    var keepsAlive: Bool = false

    var id: Int { value }
}

/// Une barre d'onglets à six entrées. Celle du système n'en montre que cinq sur iPhone (au-delà,
/// elle range les suivantes sous « Plus ») : avec l'onglet Duels, l'app dessine donc la sienne,
/// aux couleurs de `SophiaTabBarStyle`. Sans l'onglet Duels, les écrans gardent la `TabView`
/// du système.
struct SophiaTabScaffold<Content: View>: View {
    @Binding var selection: Int
    let items: [SophiaTabItem]
    /// L'onglet déjà affiché est touché de nouveau (retour à la racine de sa pile).
    let onReselect: (Int) -> Void
    let content: (Int) -> Content

    @State private var visited: Set<Int> = []
    @State private var keyboardVisible = false

    init(
        selection: Binding<Int>,
        items: [SophiaTabItem],
        onReselect: @escaping (Int) -> Void = { _ in },
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        _selection = selection
        self.items = items
        self.onReselect = onReselect
        self.content = content
    }

    var body: some View {
        ZStack {
            ForEach(items) { item in
                if item.value == selection || (item.keepsAlive && visited.contains(item.value)) {
                    content(item.value)
                        .opacity(item.value == selection ? 1 : 0)
                        .allowsHitTesting(item.value == selection)
                        .accessibilityHidden(item.value != selection)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Clavier ouvert : la barre s'efface, comme celle du système passe dessous.
            if !keyboardVisible {
                bar
            }
        }
        .onChange(of: selection, initial: true) { _, value in
            visited.insert(value)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }

    private var bar: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let selected = selection == item.value
                Button {
                    if selected {
                        onReselect(item.value)
                    } else {
                        selection = item.value
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.systemImage)
                            .symbolVariant(selected ? .fill : .none)
                            .font(.system(size: 20))
                            .frame(height: 26)
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selected ? DS.accent : DS.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 7)
                    .padding(.bottom, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 4)
        .background(DS.canvas.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(DS.hairline).frame(height: 0.5)
        }
    }
}
