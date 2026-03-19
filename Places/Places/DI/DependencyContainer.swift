import Foundation

final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var singletonFactories: [ObjectIdentifier: () -> Any] = [:]
    private var singletonInstances: [ObjectIdentifier: Any] = [:]
    private let lock = NSRecursiveLock()

    init() {}

    func register<T>(_ type: T.Type = T.self, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        factories[key] = factory
        singletonFactories.removeValue(forKey: key)
        singletonInstances.removeValue(forKey: key)
    }

    func registerSingleton<T>(_ type: T.Type = T.self, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }
        singletonFactories[key] = factory
        factories.removeValue(forKey: key)
        singletonInstances.removeValue(forKey: key)
    }

    func resolve<T>(_ type: T.Type = T.self) -> T {
        let key = ObjectIdentifier(type)
        lock.lock()
        defer { lock.unlock() }

        if let instance = singletonInstances[key] as? T {
            return instance
        }

        if let factory = singletonFactories[key] {
            let instance = factory() as! T
            singletonInstances[key] = instance
            return instance
        }

        guard let factory = factories[key] else {
            fatalError("No registration found for type \(T.self)")
        }
        return factory() as! T
    }
}
