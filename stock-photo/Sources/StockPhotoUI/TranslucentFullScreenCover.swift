import SwiftUI
import UIKit

public struct TranslucentFullScreenCover<ContentView: View>: View {
    var effect: UIBlurEffect
    var contentView: () -> ContentView

    public init(
        effect: UIBlurEffect = UIBlurEffect(style: .systemThinMaterial),
        @ViewBuilder contentView: @escaping () -> ContentView
    ) {
        self.effect = effect
        self.contentView = contentView
    }

    public var body: some View {
        contentView(
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundBlurView(effect: effect))
        .edgesIgnoringSafeArea(.all)
    }
}

struct BackgroundBlurView: UIViewRepresentable {
    let effect: UIBlurEffect

    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: effect)
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
