import SwiftUI

final class NavigatorViewModel: ViewModel<NavigatorIntent, NavigatorState, NavigatorEffect> {
    init(
        intentHandler: NavigatorIntentHandler,
        initialState: NavigatorState = NavigatorState()
    ) {
        super.init(intentHandler: intentHandler, initialState: initialState)
    }
}


struct NavigatorView: View {
    @State private var viewModel: NavigatorViewModel = DependencyContainer.shared.resolve()

    var body: some View {
        NavigationStack(path: Binding(
            get: { viewModel.state.navigationPath },
            set: { path in Task { await viewModel.handle(.updateNavigationPath(path)) } }
        )) {
            LocationsListScreenView(
                onNavigateToAddLocationRequested: {
                    Task { await viewModel.handle(.navigateToAddLocation) }
                }
            )
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .customLocation:
                    CustomLocationScreenView(
                        onNavigateToRootRequested: {
                            Task { await viewModel.handle(.navigateToRoot) }
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    NavigatorView()
}
