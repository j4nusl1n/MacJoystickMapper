# MVP Implementation Plan: macOS Joystick-to-Keyboard Mapper

**Objective:** Build a lightweight, terminal-based macOS application that reads standard joystick/gamepad inputs and translates them into synthetic keyboard events based on a user-defined YAML configuration.

**Tech Stack:**
* **Language:** Swift 
* **Input Handling:** `GameController` framework
* **Output Handling:** `CoreGraphics` (`CGEvent`)
* **Config Parsing:** `Yams` (Swift YAML library)

---

## 1. Architecture Overview

| Component | Responsibility | Technology/Framework |
| :--- | :--- | :--- |
| **Config Loader** | Reads and parses the `config.yaml` file into a Swift dictionary or struct. | `Yams` + `Codable` |
| **Input Monitor** | Listens for controller connections, disconnections, and button/axis state changes. | `GameController` (`GCController`) |
| **Translation Engine** | Maps the physical button/axis ID to the corresponding virtual key code (`CGKeyCode`). | Swift Dictionary Lookup |
| **Event Synthesizer** | Generates and posts the OS-level keyboard events to simulate typing. | `CoreGraphics` (`CGEvent`) |

---

## 2. Implementation Phases

### Phase 1: Project Scaffolding
Set up the Swift project and ensure basic controller detection is working.
* Initialize the Swift executable package.
* Add the `Yams` dependency in `Package.swift`.
* Set up `NotificationCenter` observers for `.GCControllerDidConnect` and `.GCControllerDidDisconnect`.
* *Verification:* Running the script prints the name of the connected controller to the terminal.

### Phase 2: Configuration & Mapping
Build the logic to parse user preferences and map them to Apple's key codes.
* Define the YAML structure (e.g., `buttonA: "space"`, `dpadUp: "w"`).
* Create a Swift dictionary mapping human-readable string keys (like `"space"`) to their `CGKeyCode` integer equivalents (like `49`).
* Implement the `YAMLDecoder` logic to load the local `config.yaml` file on startup.

### Phase 3: Event Synthesis (The Core Loop)
Connect the input to the output.
* Attach value-changed handlers to the `GCController.extendedGamepad` elements (buttons, triggers, thumbsticks).
* Implement the `CGEvent` posting logic.
* > **Important Security Note:** The application or terminal running the script *must* be granted **Accessibility** permissions in macOS System Settings, otherwise `CGEvent` will fail silently.

### Phase 4: Refinement & Stability
Ensure the MVP handles edge cases gracefully.
* Implement "Key Up" (release) events. If a button is released, ensure the corresponding key is unpressed so it doesn't get stuck.
* Add a deadzone threshold for analog sticks to prevent keyboard drift.
* Implement graceful shutdown logic (e.g., capturing `Ctrl+C` to release all currently pressed keys before exiting).

---

## 3. To-Do Checklist

### Setup & Config
- [ ] Run `swift package init --type executable`
- [ ] Add `Yams` to `Package.swift` dependencies
- [ ] Create `config.yaml` template in the project root
- [ ] Write `ConfigParser.swift` to read YAML and output a routing table

### Input & Output
- [ ] Create `CGKeyCode` mapping dictionary (String -> UInt16)
- [ ] Write `EventSynthesizer.swift` with `postKey(code:down:)` function
- [ ] Write `ControllerManager.swift` to listen for connection notifications
- [ ] Bind `buttonA`, `buttonB`, `buttonX`, `buttonY` to the translation engine
- [ ] Bind analog stick axes to directional keys (WASD) with a `0.5` deadzone

### Testing & Deployment
- [ ] Add Terminal / IDE to macOS Accessibility privacy settings
- [ ] Test single button presses (tap and hold)
- [ ] Test analog stick threshold mapping
- [ ] Test hot-plugging (disconnecting and reconnecting the controller while the script runs)