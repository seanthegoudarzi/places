import Foundation

enum DependencyModule {
    static func registerAll(locationsRepository: LocationsRepository? = nil) {
        let container = DependencyContainer.shared

        // MARK: - Formatters

        container.registerSingleton(CoordinateFormatter.self) {
            DefaultCoordinateFormatter()
        }

        // MARK: - Repositories
        
        container.register {
            GithubLocationsDataSource()
        }
        container.register {
            TemporaryInMemoryLocationDataSource()
        }

        if let override = locationsRepository {
            container.registerSingleton(LocationsRepository.self) { override }
        } else {
            container.registerSingleton(LocationsRepository.self) {
                DefaultLocationsRepository(
                    githubDataSource: container.resolve(),
                    inMemoryDataSource: container.resolve()
                )
            }
        }

        // MARK: - Intent Handlers

        container.register(NavigatorIntentHandler.self) {
            NavigatorIntentHandler()
        }

        container.register(LocationsScreenIntentHandler.self) {
            LocationsScreenIntentHandler(
                locationsRepository: container.resolve(),
                coordinateFormatter: container.resolve()
            )
        }

        container.register(CustomLocationScreenIntentHandler.self) {
            CustomLocationScreenIntentHandler(
                locationsRepository: container.resolve(),
                coordinateFormatter: container.resolve()
            )
        }

        // MARK: - View Models

        container.register(NavigatorViewModel.self) {
            NavigatorViewModel(intentHandler: container.resolve())
        }

        container.register(LocationsListScreenViewModel.self) {
            LocationsListScreenViewModel(intentHandler: container.resolve())
        }

        container.register(CustomLocationScreenViewModel.self) {
            let handler: CustomLocationScreenIntentHandler = container.resolve()
            return CustomLocationScreenViewModel(
                intentHandler: handler,
                initialState: handler.makeInitialState()
            )
        }
    }
}
