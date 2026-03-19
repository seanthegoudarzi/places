import Foundation

/// Contract for all intent handlers in the app.
///
/// Every screen's handler receives the current state and an `IntentContext`
/// through which it updates the state and emits side effects back to the ViewModel.
protocol IntentHandler<Intent, State, Effect> {
    associatedtype Intent
    associatedtype State
    associatedtype Effect

    func handle(
        _ intent: Intent,
        state: State,
        context: IntentContext<State, Effect>
    ) async
}
