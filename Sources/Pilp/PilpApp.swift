import SwiftUI

@main
struct PilpApp: App {
    @StateObject private var model = ClipboardModel()

    var body: some Scene {
        MenuBarExtra("Pilp", systemImage: "clipboard") {
            ClipboardMenuView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
