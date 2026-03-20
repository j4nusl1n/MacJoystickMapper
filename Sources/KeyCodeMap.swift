import CoreGraphics

/// Maps human-readable key names to CGKeyCode values.
enum KeyCodeMap {
    static let map: [String: CGKeyCode] = [
        // Letters
        "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02,
        "e": 0x0E, "f": 0x03, "g": 0x05, "h": 0x04,
        "i": 0x22, "j": 0x26, "k": 0x28, "l": 0x25,
        "m": 0x2E, "n": 0x2D, "o": 0x1F, "p": 0x23,
        "q": 0x0C, "r": 0x0F, "s": 0x01, "t": 0x11,
        "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07,
        "y": 0x10, "z": 0x06,

        // Numbers
        "0": 0x1D, "1": 0x12, "2": 0x13, "3": 0x14,
        "4": 0x15, "5": 0x17, "6": 0x16, "7": 0x1A,
        "8": 0x1C, "9": 0x19,

        // Special keys
        "space": 0x31,
        "return": 0x24,
        "enter": 0x24,
        "tab": 0x30,
        "escape": 0x35,
        "delete": 0x33,
        "forwardDelete": 0x75,

        // Modifiers
        "shift": 0x38,
        "rightShift": 0x3C,
        "control": 0x3B,
        "rightControl": 0x3E,
        "option": 0x3A,
        "rightOption": 0x3D,
        "command": 0x37,
        "rightCommand": 0x36,

        // Arrow keys
        "upArrow": 0x7E,
        "downArrow": 0x7D,
        "leftArrow": 0x7B,
        "rightArrow": 0x7C,

        // Function keys
        "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76,
        "f5": 0x60, "f6": 0x61, "f7": 0x62, "f8": 0x64,
        "f9": 0x65, "f10": 0x6D, "f11": 0x67, "f12": 0x6F,

        // Punctuation
        "minus": 0x1B,
        "equal": 0x18,
        "leftBracket": 0x21,
        "rightBracket": 0x1E,
        "backslash": 0x2A,
        "semicolon": 0x29,
        "quote": 0x27,
        "comma": 0x2B,
        "period": 0x2F,
        "slash": 0x2C,
        "grave": 0x32,
    ]

    /// Reverse lookup: CGKeyCode → human-readable key name.
    static let reverseMap: [CGKeyCode: String] = {
        var result: [CGKeyCode: String] = [:]
        for (name, code): (String, CGKeyCode) in map {
            // Keep first entry (avoid "enter" overwriting "return")
            if result[code] == nil {
                result[code] = name
            }
        }
        return result
    }()

    static func keyCode(for name: String) -> CGKeyCode? {
        map[name]
    }

    static func keyName(for code: CGKeyCode) -> String {
        reverseMap[code] ?? "unknown(\(code))"
    }
}
