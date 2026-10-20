import CoreGraphics
import Foundation

/// Watches system idle time and nudges the cursor when the user has been idle long enough.
final class Jiggler {
    private var timer: Timer?
    /// Time of our last jiggle while the user has remained idle since.
    private var lastJiggle: Date?
    private let anyInputEvent = CGEventType(rawValue: ~0)!

    func start() {
        stop()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        timer.tolerance = 0.25
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastJiggle = nil
    }

    private func tick() {
        // Our own posted events also reset the system idle counter, so after a jiggle we
        // compare against the jiggle time to tell whether the user has done anything since.
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInputEvent)

        if let last = lastJiggle {
            let sinceJiggle = Date().timeIntervalSince(last)
            if idle + 1 >= sinceJiggle {
                if sinceJiggle >= Double(Settings.interval) { jiggle() }
                return
            }
            lastJiggle = nil // user activity since our last jiggle
        }

        if idle >= Double(Settings.idleThreshold) { jiggle() }
    }

    private func jiggle() {
        guard let origin = CGEvent(source: nil)?.location else { return }
        let distance = Double(Settings.distance)
        let angle = Double.random(in: 0..<(2 * .pi))
        let dx = cos(angle) * distance
        let dy = sin(angle) * distance

        var target = CGPoint(x: origin.x + dx, y: origin.y + dy)
        if !Self.isOnScreen(target) {
            target = CGPoint(x: origin.x - dx, y: origin.y - dy)
        }

        Self.moveCursor(to: target)
        usleep(30_000)
        Self.moveCursor(to: origin)
        lastJiggle = Date()
    }

    private static func isOnScreen(_ point: CGPoint) -> Bool {
        var count: UInt32 = 0
        CGGetDisplaysWithPoint(point, 0, nil, &count)
        return count > 0
    }

    /// Posts a real HID mouse-move event so apps (Slack, Teams) see user activity.
    private static func moveCursor(to point: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?
            .post(tap: .cghidEventTap)
    }
}
