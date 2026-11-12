import SwiftUI

struct CourseImageFullscreenView: View {
    let image: UIImage
    let credit: String?
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(zoomGesture.simultaneously(with: dragGesture))
                .padding(.horizontal, 16)
                .padding(.vertical, 48)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.15), in: Circle())
                            .overlay { Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1) }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.pressable)
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                }

                Spacer()

                if let credit, !credit.isEmpty {
                    Text(credit)
                        .font(DS.sans(.caption))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
            }
        }
        .sophiaColorScheme()
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    withAnimation(DS.Motion.snappy) {
                        scale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                    lastScale = 1
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}
