# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MacJoystickMapper is a lightweight, terminal-based macOS application that reads joystick/gamepad inputs and translates them into synthetic keyboard events via a user-defined YAML configuration.

## Tech Stack

- **Language:** Swift (executable package)
- **Input:** `GameController` framework (`GCController`)
- **Output:** `CoreGraphics` (`CGEvent`) for synthetic keyboard events
- **Config:** `Yams` (Swift YAML library) with `Codable`

## Build & Run

```bash
# Build
swift build

# Run (normal mapping mode)
swift run

# Run with custom config
swift run MacJoystickMapper my-mapping.yaml

# Scan mode (detect inputs, no keyboard events)
swift run MacJoystickMapper -- --scan

# Build release
swift build -c release
```

## Architecture

Four core components form a pipeline: Config Loader → Input Monitor → Translation Engine → Event Synthesizer.

- **ConfigParser** (`ConfigParser.swift`) — Parses `config.yaml` via Yams into a `GamepadConfig` struct containing a `[String: CGKeyCode]` routing table and deadzone value
- **KeyCodeMap** (`KeyCodeMap.swift`) — Static dictionary mapping human-readable key names (e.g., `"space"`) to `CGKeyCode` values, plus reverse lookup for display
- **ControllerManager** (`ControllerManager.swift`) — Listens for `GCControllerDidConnect`/`GCControllerDidDisconnect` notifications; binds button/axis handlers on the `extendedGamepad` profile; supports map and scan modes
- **EventSynthesizer** (`EventSynthesizer.swift`) — Posts `CGEvent` key-down/key-up events to the system; tracks pressed keys for graceful shutdown cleanup

## CLI Modes

- **Map mode** (default) — Translates gamepad inputs to keyboard events; logs each press/release with the mapped key name (e.g., `↓ buttonA → space`)
- **Scan mode** (`--scan`) — Prints a table of all detected controller inputs with their config keys and current mappings; shows live press/release events without sending keyboard events

## Key Technical Details

- The app requires **macOS Accessibility permissions** to post `CGEvent` — without this, events fail silently
- Analog sticks use a configurable deadzone threshold (default `0.5`) to prevent keyboard drift
- Key-up events are sent on button release to avoid stuck keys
- Graceful shutdown (SIGINT/SIGTERM) releases all currently pressed keys before exiting
- On controller disconnect, all pressed keys are released immediately
- YAML config format maps gamepad elements to human-readable key names (e.g., `buttonA: "space"`, `dpadUp: "w"`)
- Supports face buttons (A/B/X/Y), shoulders, triggers, D-pad, both analog sticks, and optional buttons (Home, Menu, Options, stick clicks)

## Implementation Status

All core MVP phases from `PLAN.md` are implemented. Remaining items are manual testing tasks requiring a physical controller and Accessibility permissions.
