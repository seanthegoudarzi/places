import Foundation
import Combine
import Observation

/// Generic base ViewModel that owns the MVI wiring shared by every screen.
@Observable
open class ViewModel<Intent, State, Effect> {
    var state: State

    @ObservationIgnored
    var effectPublisher: AnyPublisher<Effect, Never> {
        effectSubject.eraseToAnyPublisher()
    }

    @ObservationIgnored
    private let effectSubject = PassthroughSubject<Effect, Never>()
    @ObservationIgnored
    private let intentHandler: any IntentHandler<Intent, State, Effect>

    init(
        intentHandler: any IntentHandler<Intent, State, Effect>,
        initialState: State
    ) {
        self.intentHandler = intentHandler
        self.state = initialState
    }

    func handle(_ intent: Intent) async {
        let context = IntentContext<State, Effect>(
            updateState: { [weak self] state in
                self?.state = state
            },
            effect: { [weak self] effect in self?.effectSubject.send(effect) }
        )
        await intentHandler.handle(intent, state: state, context: context)
    }
}
