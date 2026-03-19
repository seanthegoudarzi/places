import SwiftUI

@main
struct PlacesApp: App {
    
    init() {
        DependencyModule.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            NavigatorView()
        }
    }
}
