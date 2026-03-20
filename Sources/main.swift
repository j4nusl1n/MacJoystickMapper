import Foundation
import GameController

// MARK: - Argument Parsing

var configPath: String?
var mode: ControllerMode = .map

for arg: String in CommandLine.arguments.dropFirst() {
    if arg == "--scan" {
        mode = .scan
    } else if arg == "--help" || arg == "-h" {
        print(
            """
            Usage: MacJoystickMapper [options] [config-file]

            Options:
              --scan     Scan mode: detect all buttons/axes and show live input
                         events without sending keyboard events.
              --help     Show this help message.

            If no config file is specified, looks for config.yaml in the
            current directory.

            Examples:
              MacJoystickMapper                      # Run with ./config.yaml
              MacJoystickMapper my-mapping.yaml      # Run with custom config
              MacJoystickMapper --scan               # Scan controller inputs
              MacJoystickMapper --scan my-mapping.yaml  # Scan with config to show mappings
            """)
        exit(0)
    } else {
        configPath = arg
    }
}

if configPath == nil {
    let cwd: String = FileManager.default.currentDirectoryPath
    configPath = (cwd as NSString).appendingPathComponent("config.yaml")
}

// MARK: - Startup

print("MacJoystickMapper starting...")
print("Config: \(configPath!)")
if mode == .scan {
    print("Mode: SCAN (no keyboard events will be sent)")
}
print("Press Ctrl+C to quit.\n")

let config: GamepadConfig
do {
    config = try ConfigParser.parse(filePath: configPath!)
} catch {
    print("Error loading config: \(error)")
    exit(1)
}

// MARK: - Graceful Shutdown

signal(SIGINT) { _ in
    print("\nShutting down — releasing all keys...")
    EventSynthesizer.releaseAllKeys()
    exit(0)
}

signal(SIGTERM) { _ in
    print("\nShutting down — releasing all keys...")
    EventSynthesizer.releaseAllKeys()
    exit(0)
}

// MARK: - Controller Setup

let manager: ControllerManager = ControllerManager(config: config, mode: mode)
manager.startListening()

// Start polling for controllers (needed for some connection types).
GCController.startWirelessControllerDiscovery {}

// Keep the run loop alive to receive controller events.
RunLoop.main.run()
