import SwiftUI

@main
struct LifeArchiveAIApp: App {
    @StateObject private var store = ArchiveStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.settings.useDarkMode ? .dark : nil)
        }
    }
}
