import SwiftUI

struct MenuView: View {
    @Bindable var controller: BoostController
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $controller.isEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brighter")
                        .font(.headline)
                    Text(controller.status.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 4) {
                Text("Boost")
                    .font(.subheadline)
                Slider(value: $controller.strength, in: 0...1) {
                    Text("Boost")
                } minimumValueLabel: {
                    Image(systemName: "sun.min")
                } maximumValueLabel: {
                    Image(systemName: "sun.max")
                }
                .labelsHidden()
            }

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    try? LoginItem.setEnabled(newValue)
                    launchAtLogin = LoginItem.isEnabled
                }
            ))
            .toggleStyle(.checkbox)

            Button("Quit Brighter") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 260)
    }
}
