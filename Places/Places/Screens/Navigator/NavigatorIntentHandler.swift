import Foundation

struct NavigatorIntentHandler: IntentHandler {
    typealias Intent = NavigatorIntent
    typealias State = NavigatorState
    typealias Effect = NavigatorEffect

    func handle(
        _ intent: NavigatorIntent,
        state: NavigatorState,
        context: IntentContext<NavigatorState, NavigatorEffect>
    ) async {
        switch intent {
        case .navigateToAddLocation:
            var updatedState = state
            updatedState.navigationPath.append(.customLocation)
            await context.updateState(updatedState)

        case .navigateToRoot:
            var updatedState = state
            updatedState.navigationPath = []
            await context.updateState(updatedState)

        case .updateNavigationPath(let path):
            var updatedState = state
            updatedState.navigationPath = path
            await context.updateState(updatedState)
        }
    }
}
