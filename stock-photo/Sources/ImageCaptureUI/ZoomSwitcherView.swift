import SwiftUI

struct ZoomSwitcherView: View {
    public enum ZoomLevel: Int, CaseIterable {
        case base = 0
        case double
        case triple
    }

    @Binding var selectedZoomLevel: ZoomLevel

    let color = Color.black

    private func title(for zoomLevel: ZoomLevel) -> String {
        switch zoomLevel {
        case .base:
            return "1x"
        case .double:
            return "2x"
        case .triple:
            return "3x"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ZoomLevel.allCases, id: \.rawValue) { zoomLevel in
                Button(action: {
                    withAnimation(.interactiveSpring()) {
                        selectedZoomLevel = zoomLevel
                    }
                }) {
                    let scale = selectedZoomLevel == zoomLevel ? 1 : 0.75

                    Text(
                        title(for: zoomLevel)
                    )
                    .font(.system(size: selectedZoomLevel == zoomLevel ? 14 : 10, design: .rounded).bold())
                    .foregroundColor(Color(uiColor: selectedZoomLevel == zoomLevel ? UIColor.systemYellow : UIColor.white))
                    .padding(.vertical, 10 * scale)
                    .padding(.horizontal, 10 * scale)
                    .background(color.opacity(0.75))
                    .cornerRadius(10)
                    .clipShape(Circle())
                }
                .foregroundColor(.white)
                .buttonStyle(ZoomSwitcherButtonStyle())
            }
        }
        .padding(6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// Override the default button down state
struct ZoomSwitcherButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct ZoomSwitcherView_Previews: PreviewProvider {
    struct ContentView: View {
        @State private var selectedZoomLevel: ZoomSwitcherView.ZoomLevel = .base
        var body: some View {
            VStack {
                ZoomSwitcherView(
                    selectedZoomLevel: $selectedZoomLevel
                )
            }
        }
    }

    static var previews: some View {
        ContentView()
    }
}
