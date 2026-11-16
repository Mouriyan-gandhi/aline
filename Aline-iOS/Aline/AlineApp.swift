import SwiftUI

@main
struct AlineApp: App {
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(\.colorScheme, .light)
        }
    }
}


