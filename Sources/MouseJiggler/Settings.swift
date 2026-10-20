import Foundation

/// User preferences, persisted in UserDefaults.
enum Settings {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let enabled = "enabled"
        static let distance = "distance"
        static let interval = "interval"
        static let idleThreshold = "idleThreshold"
    }

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.enabled: true,
            Key.distance: 5,
            Key.interval: 60,
            Key.idleThreshold: 60,
        ])
    }

    static var enabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// Jiggle distance in pixels.
    static var distance: Int {
        get { defaults.integer(forKey: Key.distance) }
        set { defaults.set(newValue, forKey: Key.distance) }
    }

    /// Seconds between jiggles while idle.
    static var interval: Int {
        get { defaults.integer(forKey: Key.interval) }
        set { defaults.set(newValue, forKey: Key.interval) }
    }

    /// Seconds without mouse/keyboard input before jiggling starts.
    static var idleThreshold: Int {
        get { defaults.integer(forKey: Key.idleThreshold) }
        set { defaults.set(newValue, forKey: Key.idleThreshold) }
    }
}
