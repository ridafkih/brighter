import SwiftUI

@main
struct BrighterApp: App {
    @State private var controller = BoostController()

    var body: some Scene {
        MenuBarExtra("Brighter", systemImage: controller.isEnabled ? "sun.max.fill" : "sun.max") {
            MenuView(controller: controller)
        }
        .menuBarExtraStyle(.window)
    }
}
