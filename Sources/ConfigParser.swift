import CoreGraphics
import Foundation
import Yams

/// Parsed configuration mapping gamepad inputs to CGKeyCode values.
struct GamepadConfig {
    let buttonMap: [String: CGKeyCode]
    let deadzone: Float

    /// All gamepad input keys recognized in the YAML config.
    static let gamepadKeys: Set<String> = [
        "buttonA", "buttonB", "buttonX", "buttonY",
        "leftShoulder", "rightShoulder",
        "leftTrigger", "rightTrigger",
        "dpadUp", "dpadDown", "dpadLeft", "dpadRight",
        "leftStickUp", "leftStickDown", "leftStickLeft", "leftStickRight",
        "rightStickUp", "rightStickDown", "rightStickLeft", "rightStickRight",
    ]
}

/// Parses a YAML config file into a GamepadConfig.
enum ConfigParser {
    private static let maxConfigFileSize: Int = 1_000_000  // 1 MB

    static func parse(filePath: String) throws -> GamepadConfig {
        let url: URL = URL(fileURLWithPath: filePath)

        // Guard against large files (YAML bomb / DoS)
        let attributes: [FileAttributeKey: Any] = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize: Int = (attributes[.size] as? NSNumber)?.intValue, fileSize > maxConfigFileSize {
            throw ConfigError.fileTooLarge(fileSize)
        }

        let yamlString: String = try String(contentsOf: url, encoding: .utf8)
        guard let yaml: [String: Any] = try Yams.load(yaml: yamlString) as? [String: Any] else {
            throw ConfigError.invalidFormat
        }

        var buttonMap: [String: CGKeyCode] = [:]
        var deadzone: Float = 0.5

        for (key, value): (String, Any) in yaml {
            if key == "deadzone" {
                if let dz: Double = value as? Double {
                    if dz >= 0.0 && dz <= 1.0 {
                        deadzone = Float(dz)
                    } else {
                        print("Warning: Deadzone value \(dz) out of range [0.0, 1.0], using default 0.5.")
                    }
                }
                continue
            }

            guard GamepadConfig.gamepadKeys.contains(key) else {
                print("Warning: Unknown config key '\(key)', skipping.")
                continue
            }

            guard let keyName: String = value as? String else {
                print("Warning: Value for '\(key)' is not a string, skipping.")
                continue
            }

            guard let code: CGKeyCode = KeyCodeMap.keyCode(for: keyName) else {
                print("Warning: Unknown key name '\(keyName)' for '\(key)', skipping.")
                continue
            }

            buttonMap[key] = code
        }

        if buttonMap.isEmpty {
            throw ConfigError.noMappingsFound
        }

        print("Loaded \(buttonMap.count) button mappings, deadzone: \(deadzone)")
        return GamepadConfig(buttonMap: buttonMap, deadzone: deadzone)
    }
}

enum ConfigError: Error, CustomStringConvertible {
    case invalidFormat
    case fileTooLarge(Int)
    case noMappingsFound

    var description: String {
        switch self {
        case .invalidFormat:
            return "Config file is not a valid YAML dictionary."
        case .fileTooLarge(let size):
            return "Config file too large (\(size) bytes). Maximum allowed: 1 MB."
        case .noMappingsFound:
            return "Config file contains no button mappings."
        }
    }
}
