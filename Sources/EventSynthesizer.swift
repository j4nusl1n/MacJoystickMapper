import ApplicationServices
import CoreGraphics
import Foundation

/// Posts synthetic CGEvent key-down/key-up events to the system.
enum EventSynthesizer {
    /// Set of currently pressed key codes, used for cleanup on shutdown.
    private(set) static var pressedKeys: Set<CGKeyCode> = []
    private static let lock = NSLock()

    /// Checks whether the process has Accessibility permissions.
    /// Prompts the user via system dialog if not yet granted.
    /// Returns `true` if trusted; `false` otherwise.
    @discardableResult
    static func checkAccessibility(prompt: Bool = true) -> Bool {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Posts a key-down or key-up event for the given key code.
    static func postKey(code: CGKeyCode, keyDown: Bool) {
        guard let source: CGEventSource = CGEventSource(stateID: .hidSystemState) else {
            print("Error: Failed to create CGEventSource.")
            return
        }

        guard let event: CGEvent = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: keyDown) else {
            print("Error: Failed to create CGEvent for key code \(code).")
            return
        }

        event.post(tap: .cghidEventTap)

        lock.lock()
        if keyDown {
            pressedKeys.insert(code)
        } else {
            pressedKeys.remove(code)
        }
        lock.unlock()
    }

    /// Releases all currently pressed keys. Called during graceful shutdown.
    static func releaseAllKeys() {
        lock.lock()
        let keys: Set<CGKeyCode> = pressedKeys
        lock.unlock()

        for code in keys {
            postKey(code: code, keyDown: false)
        }
    }
}
