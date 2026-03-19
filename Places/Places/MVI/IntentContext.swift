import Foundation

/// The output environment provided to every `IntentHandler` conformer.
///
/// Handlers call `updateState(_:)` to push state transitions and `emitEffect(_:)` to
/// dispatch side effects.
struct IntentContext<State, Effect> {
    private let updateState: (State) -> Void
    private let emitEffect: (Effect) -> Void

    init(
        updateState: @escaping (State) -> Void,
        effect: @escaping (Effect) -> Void
    ) {
        self.updateState = updateState
        self.emitEffect = effect
    }

    /// Delivers a new state snapshot to the ViewModel on the main actor.
    func updateState(_ state: State) async { updateState(state) }

    /// Dispatches a side-effect signal to the ViewModel on the main actor.
    func emitEffect(_ effect: Effect) async { emitEffect(effect) }
}
