import SwiftUI

@main
struct PlacesApp: App {
    
    init() {
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING"),
           let scenarioRaw = ProcessInfo.processInfo.environment["UI_TEST_SCENARIO"],
           let scenario = UITestScenario(rawValue: scenarioRaw) {
            DependencyModule.registerAll(
                locationsRepository: UITestLocationsRepository(scenario: scenario)
            )
        } else {
            DependencyModule.registerAll()
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigatorView()
        }
    }
}
