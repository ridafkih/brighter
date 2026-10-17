import BrighterCore
import SwiftUI

struct MenuView: View {
    @Bindable var controller: BoostController
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            brightness
                .padding(.bottom, 10)

            Divider()
                .padding(.vertical, 6)

            MenuRow {
                launchAtLogin = setLaunchAtLogin(!launchAtLogin)
            } label: {
                Text("Launch at Login")
                Spacer()
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .opacity(launchAtLogin ? 1 : 0)
            }

            MenuRow {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Brighter")
                Spacer()
                Text("⌘Q")
                    .foregroundStyle(.secondary)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 280)
        .task {
            while !Task.isCancelled {
                controller.refreshBrightness()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                controller.isEnabled.toggle()
            } label: {
                Image(systemName: controller.isEnabled ? "sun.max.fill" : "sun.max")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(controller.isEnabled ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(controller.isEnabled ? AnyShapeStyle(.orange) : AnyShapeStyle(.quaternary)))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("Brighter")
                    .font(.system(size: 13, weight: .semibold))
                Text(controller.status.label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("Brighter", isOn: $controller.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .fixedSize()
        }
        .frame(height: 32)
        .animation(.snappy, value: controller.isEnabled)
    }

    private var brightness: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Brightness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(controller.levelPercent)%")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(controller.level > 1 ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                    .contentTransition(.numericText())
            }
            LevelSlider(
                value: $controller.level,
                upperBound: SliderLevel.upperBound(boostEnabled: controller.isEnabled),
                notch: controller.isEnabled ? 1 : nil
            )
        }
        .animation(.snappy, value: controller.isEnabled)
    }

    private func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        try? LoginItem.setEnabled(enabled)
        return LoginItem.isEnabled
    }
}

struct LevelSlider: View {
    @Binding var value: Double
    let upperBound: Double
    let notch: Double?

    private let trackHeight: CGFloat = 20
    private let notchGap: CGFloat = 5
    private let notchHeight: CGFloat = 7

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fillWidth = position(of: value, in: width)
            let notchX = position(of: notch ?? upperBound, in: width)

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: trackHeight)

                Rectangle()
                    .fill(.orange.opacity(0.18))
                    .frame(width: max(width - notchX, 0), height: trackHeight)
                    .offset(x: notchX)
                    .opacity(notch == nil ? 0 : 1)

                Rectangle()
                    .fill(.white)
                    .frame(width: max(min(fillWidth, notchX), 0), height: trackHeight)

                Rectangle()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: notch == nil ? 0 : max(fillWidth - notchX, 0), height: trackHeight)
                    .offset(x: notchX)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.55))
                    .frame(width: trackHeight, height: trackHeight)
                    .offset(x: 2)

                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
                    .frame(width: trackHeight, height: trackHeight)
                    .offset(x: fillWidth - trackHeight / 2)

                Capsule()
                    .fill(.orange)
                    .frame(width: 3, height: notchHeight)
                    .offset(x: notchX - 1.5, y: trackHeight + notchGap)
                    .opacity(notch == nil ? 0 : 1)
            }
            .mask(alignment: .topLeading) {
                VStack(spacing: notchGap) {
                    Capsule().frame(height: trackHeight)
                    Rectangle().frame(height: notchHeight)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        value = level(at: drag.location.x, in: width)
                    }
            )
        }
        .frame(height: trackHeight + notchGap + notchHeight)
        .accessibilityElement()
        .accessibilityLabel("Brightness")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 0.05 : -0.05
            value = min(max(value + step, 0), upperBound)
        }
    }

    private func position(of level: Double, in width: CGFloat) -> CGFloat {
        let usable = max(width - trackHeight, 0)
        return trackHeight / 2 + usable * CGFloat(min(max(level / upperBound, 0), 1))
    }

    private func level(at x: CGFloat, in width: CGFloat) -> Double {
        let usable = max(width - trackHeight, 1)
        let fraction = min(max((x - trackHeight / 2) / usable, 0), 1)
        let level = Double(fraction) * upperBound
        if let notch, abs(level - notch) < upperBound * 0.02 { return notch }
        return level
    }
}

private struct MenuRow<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                label
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -8)
        .onHover { isHovered = $0 }
    }
}
