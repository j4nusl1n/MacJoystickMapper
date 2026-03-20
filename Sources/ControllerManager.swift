import Foundation
import GameController

/// Operating mode for the controller manager.
enum ControllerMode {
    /// Normal mapping mode — gamepad inputs produce keyboard events.
    case map
    /// Scan mode — prints all detected inputs without sending keyboard events.
    case scan
}

/// Manages gamepad connections and binds input handlers to the translation engine.
final class ControllerManager {
    private let config: GamepadConfig
    private let mode: ControllerMode

    init(config: GamepadConfig, mode: ControllerMode = .map) {
        self.config = config
        self.mode = mode
    }

    /// Start observing controller connect/disconnect notifications.
    func startListening() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] (notification: Notification) in
            guard let controller: GCController = notification.object as? GCController else { return }
            print("Controller connected: \(controller.vendorName ?? "Unknown")")
            self?.handleController(controller)
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { (notification: Notification) in
            guard let controller: GCController = notification.object as? GCController else { return }
            print("Controller disconnected: \(controller.vendorName ?? "Unknown")")
            EventSynthesizer.releaseAllKeys()
        }

        // Handle any already-connected controllers.
        for controller: GCController in GCController.controllers() {
            print("Controller already connected: \(controller.vendorName ?? "Unknown")")
            handleController(controller)
        }

        if GCController.controllers().isEmpty {
            print("No controllers detected. Waiting for connection...")
        }
    }

    private func handleController(_ controller: GCController) {
        switch mode {
        case .map:
            bindInputs(for: controller)
        case .scan:
            printControllerInfo(controller)
            bindScanHandlers(for: controller)
        }
    }

    // MARK: - Scan Mode

    private func printControllerInfo(_ controller: GCController) {
        print("")
        print("╔══════════════════════════════════════════╗")
        print("║         Controller Scan Results          ║")
        print("╠══════════════════════════════════════════╣")
        print("║ Name: \(pad(controller.vendorName ?? "Unknown", to: 34))║")
        if let productCategory: String = controller.productCategory as String? {
            print("║ Type: \(pad(productCategory, to: 34))║")
        }
        print("╠══════════════════════════════════════════╣")

        guard let gamepad: GCExtendedGamepad = controller.extendedGamepad else {
            print("║ ⚠ No extended gamepad profile          ║")
            print("╚══════════════════════════════════════════╝")
            return
        }

        print("║ Profile: Extended Gamepad                ║")
        print("╠══════════════════════════════════════════╣")

        // Collect all available elements
        var elements: [(name: String, configKey: String)] = []

        // Face buttons
        elements.append(("Button A", "buttonA"))
        elements.append(("Button B", "buttonB"))
        elements.append(("Button X", "buttonX"))
        elements.append(("Button Y", "buttonY"))

        // Shoulder buttons
        elements.append(("Left Shoulder", "leftShoulder"))
        elements.append(("Right Shoulder", "rightShoulder"))

        // Triggers
        elements.append(("Left Trigger", "leftTrigger"))
        elements.append(("Right Trigger", "rightTrigger"))

        // D-Pad
        elements.append(("D-Pad Up", "dpadUp"))
        elements.append(("D-Pad Down", "dpadDown"))
        elements.append(("D-Pad Left", "dpadLeft"))
        elements.append(("D-Pad Right", "dpadRight"))

        // Left stick
        elements.append(("Left Stick Up", "leftStickUp"))
        elements.append(("Left Stick Down", "leftStickDown"))
        elements.append(("Left Stick Left", "leftStickLeft"))
        elements.append(("Left Stick Right", "leftStickRight"))

        // Right stick
        elements.append(("Right Stick Up", "rightStickUp"))
        elements.append(("Right Stick Down", "rightStickDown"))
        elements.append(("Right Stick Left", "rightStickLeft"))
        elements.append(("Right Stick Right", "rightStickRight"))

        // Optional buttons (may not exist on all controllers)
        if gamepad.buttonHome != nil {
            elements.append(("Home Button", "buttonHome"))
        }
        elements.append(("Menu Button", "buttonMenu"))
        if gamepad.buttonOptions != nil {
            elements.append(("Options Button", "buttonOptions"))
        }
        if #available(macOS 13.0, *) {
            if gamepad.leftThumbstickButton != nil {
                elements.append(("Left Stick Click", "leftStickButton"))
            }
            if gamepad.rightThumbstickButton != nil {
                elements.append(("Right Stick Click", "rightStickButton"))
            }
        }

        print("║ Available Inputs:                        ║")
        print("║──────────────────────────────────────────║")
        print("║ \(pad("Input", to: 20)) \(pad("Config Key", to: 20))║")
        print("║──────────────────────────────────────────║")

        for element: (name: String, configKey: String) in elements {
            let mapped: CGKeyCode? = config.buttonMap[element.configKey]
            let mappedStr: String = mapped.map { "→ \(KeyCodeMap.keyName(for: $0))" } ?? "(unmapped)"
            print("║ \(pad(element.name, to: 20)) \(pad(element.configKey, to: 20))║")
            print("║ \(pad("", to: 20)) \(pad(mappedStr, to: 20))║")
        }

        print("╠══════════════════════════════════════════╣")
        print("║ Total: \(pad("\(elements.count) inputs detected", to: 33))║")
        print("╚══════════════════════════════════════════╝")
        print("")
        print("Press buttons/triggers to see live input events.")
        print("Press Ctrl+C to exit.\n")
    }

    private func pad(_ str: String, to width: Int) -> String {
        if str.count >= width { return String(str.prefix(width)) }
        return str + String(repeating: " ", count: width - str.count)
    }

    private func bindScanHandlers(for controller: GCController) {
        guard let gamepad: GCExtendedGamepad = controller.extendedGamepad else { return }

        // Face buttons
        scanButton(gamepad.buttonA, name: "buttonA", label: "Button A")
        scanButton(gamepad.buttonB, name: "buttonB", label: "Button B")
        scanButton(gamepad.buttonX, name: "buttonX", label: "Button X")
        scanButton(gamepad.buttonY, name: "buttonY", label: "Button Y")

        // Shoulders
        scanButton(gamepad.leftShoulder, name: "leftShoulder", label: "Left Shoulder")
        scanButton(gamepad.rightShoulder, name: "rightShoulder", label: "Right Shoulder")

        // Triggers
        scanTrigger(gamepad.leftTrigger, name: "leftTrigger", label: "Left Trigger")
        scanTrigger(gamepad.rightTrigger, name: "rightTrigger", label: "Right Trigger")

        // D-Pad
        scanButton(gamepad.dpad.up, name: "dpadUp", label: "D-Pad Up")
        scanButton(gamepad.dpad.down, name: "dpadDown", label: "D-Pad Down")
        scanButton(gamepad.dpad.left, name: "dpadLeft", label: "D-Pad Left")
        scanButton(gamepad.dpad.right, name: "dpadRight", label: "D-Pad Right")

        // Sticks
        scanStick(gamepad.leftThumbstick, prefix: "leftStick", label: "Left Stick")
        scanStick(gamepad.rightThumbstick, prefix: "rightStick", label: "Right Stick")

        // Optional buttons
        if let home: GCControllerButtonInput = gamepad.buttonHome {
            scanButton(home, name: "buttonHome", label: "Home")
        }
        scanButton(gamepad.buttonMenu, name: "buttonMenu", label: "Menu")
        if let options: GCControllerButtonInput = gamepad.buttonOptions {
            scanButton(options, name: "buttonOptions", label: "Options")
        }
        if #available(macOS 13.0, *) {
            if let l3: GCControllerButtonInput = gamepad.leftThumbstickButton {
                scanButton(l3, name: "leftStickButton", label: "Left Stick Click")
            }
            if let r3: GCControllerButtonInput = gamepad.rightThumbstickButton {
                scanButton(r3, name: "rightStickButton", label: "Right Stick Click")
            }
        }
    }

    private func scanButton(_ button: GCControllerButtonInput, name: String, label: String) {
        let mappedKey: String? = config.buttonMap[name].map { KeyCodeMap.keyName(for: $0) }

        button.pressedChangedHandler = { (_: GCControllerButtonInput, value: Float, pressed: Bool) in
            let state: String = pressed ? "PRESSED " : "RELEASED"
            let mapping: String = mappedKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
            print("[\(state)] \(label) (\(name)) value: \(String(format: "%.2f", value))\(mapping)")
        }
    }

    private func scanTrigger(_ trigger: GCControllerButtonInput, name: String, label: String) {
        let mappedKey: String? = config.buttonMap[name].map { KeyCodeMap.keyName(for: $0) }
        var wasPressed: Bool = false

        trigger.valueChangedHandler = { (_: GCControllerButtonInput, value: Float, pressed: Bool) in
            if pressed != wasPressed {
                wasPressed = pressed
                let state: String = pressed ? "PRESSED " : "RELEASED"
                let mapping: String = mappedKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
                print(
                    "[\(state)] \(label) (\(name)) value: \(String(format: "%.2f", value))\(mapping)"
                )
            }
        }
    }

    private func scanStick(_ stick: GCControllerDirectionPad, prefix: String, label: String) {
        let deadzone: Float = config.deadzone
        let upKey: String? = config.buttonMap["\(prefix)Up"].map { KeyCodeMap.keyName(for: $0) }
        let downKey: String? = config.buttonMap["\(prefix)Down"].map { KeyCodeMap.keyName(for: $0) }
        let leftKey: String? = config.buttonMap["\(prefix)Left"].map { KeyCodeMap.keyName(for: $0) }
        let rightKey: String? = config.buttonMap["\(prefix)Right"].map { KeyCodeMap.keyName(for: $0) }

        var yPos: Bool = false
        var yNeg: Bool = false
        var xPos: Bool = false
        var xNeg: Bool = false

        stick.valueChangedHandler = { (_: GCControllerDirectionPad, xValue: Float, yValue: Float) in
            let nowUp: Bool = yValue > deadzone
            let nowDown: Bool = yValue < -deadzone
            let nowRight: Bool = xValue > deadzone
            let nowLeft: Bool = xValue < -deadzone

            if nowUp != yPos {
                yPos = nowUp
                let state: String = nowUp ? "PRESSED " : "RELEASED"
                let mapping: String = upKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
                print(
                    "[\(state)] \(label) Up (\(prefix)Up) value: \(String(format: "%.2f", yValue))\(mapping)"
                )
            }
            if nowDown != yNeg {
                yNeg = nowDown
                let state: String = nowDown ? "PRESSED " : "RELEASED"
                let mapping: String = downKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
                print(
                    "[\(state)] \(label) Down (\(prefix)Down) value: \(String(format: "%.2f", yValue))\(mapping)"
                )
            }
            if nowRight != xPos {
                xPos = nowRight
                let state: String = nowRight ? "PRESSED " : "RELEASED"
                let mapping: String = rightKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
                print(
                    "[\(state)] \(label) Right (\(prefix)Right) value: \(String(format: "%.2f", xValue))\(mapping)"
                )
            }
            if nowLeft != xNeg {
                xNeg = nowLeft
                let state: String = nowLeft ? "PRESSED " : "RELEASED"
                let mapping: String = leftKey.map { " → mapped to: \($0)" } ?? " (unmapped)"
                print(
                    "[\(state)] \(label) Left (\(prefix)Left) value: \(String(format: "%.2f", xValue))\(mapping)"
                )
            }
        }
    }

    // MARK: - Normal Map Mode

    private func bindInputs(for controller: GCController) {
        guard let gamepad: GCExtendedGamepad = controller.extendedGamepad else {
            print("Warning: Controller does not support extended gamepad profile.")
            return
        }

        // Face buttons
        bindButton(gamepad.buttonA, name: "buttonA")
        bindButton(gamepad.buttonB, name: "buttonB")
        bindButton(gamepad.buttonX, name: "buttonX")
        bindButton(gamepad.buttonY, name: "buttonY")

        // Shoulder buttons
        bindButton(gamepad.leftShoulder, name: "leftShoulder")
        bindButton(gamepad.rightShoulder, name: "rightShoulder")

        // Triggers (analog, treated as buttons)
        bindButton(gamepad.leftTrigger, name: "leftTrigger")
        bindButton(gamepad.rightTrigger, name: "rightTrigger")

        // D-Pad
        bindButton(gamepad.dpad.up, name: "dpadUp")
        bindButton(gamepad.dpad.down, name: "dpadDown")
        bindButton(gamepad.dpad.left, name: "dpadLeft")
        bindButton(gamepad.dpad.right, name: "dpadRight")

        // Analog sticks
        bindStick(
            gamepad.leftThumbstick,
            upName: "leftStickUp", downName: "leftStickDown",
            leftName: "leftStickLeft", rightName: "leftStickRight"
        )
        bindStick(
            gamepad.rightThumbstick,
            upName: "rightStickUp", downName: "rightStickDown",
            leftName: "rightStickLeft", rightName: "rightStickRight"
        )

        print("Inputs bound for \(controller.vendorName ?? "Unknown").")
    }

    private func bindButton(_ button: GCControllerButtonInput, name: String) {
        guard let keyCode: CGKeyCode = config.buttonMap[name] else { return }
        let keyName: String = KeyCodeMap.keyName(for: keyCode)

        button.pressedChangedHandler = { (_: GCControllerButtonInput, _: Float, pressed: Bool) in
            let action: String = pressed ? "↓" : "↑"
            print("\(action) \(name) → \(keyName)")
            EventSynthesizer.postKey(code: keyCode, keyDown: pressed)
        }
    }

    private func bindStick(
        _ stick: GCControllerDirectionPad,
        upName: String, downName: String,
        leftName: String, rightName: String
    ) {
        let deadzone: Float = config.deadzone
        let upCode: CGKeyCode? = config.buttonMap[upName]
        let downCode: CGKeyCode? = config.buttonMap[downName]
        let leftCode: CGKeyCode? = config.buttonMap[leftName]
        let rightCode: CGKeyCode? = config.buttonMap[rightName]

        let upKeyName: String? = upCode.map { KeyCodeMap.keyName(for: $0) }
        let downKeyName: String? = downCode.map { KeyCodeMap.keyName(for: $0) }
        let leftKeyName: String? = leftCode.map { KeyCodeMap.keyName(for: $0) }
        let rightKeyName: String? = rightCode.map { KeyCodeMap.keyName(for: $0) }

        // Track axis active states to send proper key-up events.
        var yPositive: Bool = false
        var yNegative: Bool = false
        var xPositive: Bool = false
        var xNegative: Bool = false

        stick.valueChangedHandler = { (_: GCControllerDirectionPad, xValue: Float, yValue: Float) in
            // Y-axis: up (positive) / down (negative)
            let nowUp: Bool = yValue > deadzone
            let nowDown: Bool = yValue < -deadzone

            if nowUp != yPositive {
                yPositive = nowUp
                if let code: CGKeyCode = upCode {
                    let action: String = nowUp ? "↓" : "↑"
                    print("\(action) \(upName) → \(upKeyName ?? "(unmapped)")")
                    EventSynthesizer.postKey(code: code, keyDown: nowUp)
                }
            }
            if nowDown != yNegative {
                yNegative = nowDown
                if let code: CGKeyCode = downCode {
                    let action: String = nowDown ? "↓" : "↑"
                    print("\(action) \(downName) → \(downKeyName ?? "(unmapped)")")
                    EventSynthesizer.postKey(code: code, keyDown: nowDown)
                }
            }

            // X-axis: right (positive) / left (negative)
            let nowRight: Bool = xValue > deadzone
            let nowLeft: Bool = xValue < -deadzone

            if nowRight != xPositive {
                xPositive = nowRight
                if let code: CGKeyCode = rightCode {
                    let action: String = nowRight ? "↓" : "↑"
                    print("\(action) \(rightName) → \(rightKeyName ?? "(unmapped)")")
                    EventSynthesizer.postKey(code: code, keyDown: nowRight)
                }
            }
            if nowLeft != xNegative {
                xNegative = nowLeft
                if let code: CGKeyCode = leftCode {
                    let action: String = nowLeft ? "↓" : "↑"
                    print("\(action) \(leftName) → \(leftKeyName ?? "(unmapped)")")
                    EventSynthesizer.postKey(code: code, keyDown: nowLeft)
                }
            }
        }
    }
}
