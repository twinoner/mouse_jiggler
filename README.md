# Mouse Jiggler

A tiny macOS menu bar app that keeps Slack, Teams, and similar apps from marking you as away. Once you've been idle (no mouse or keyboard input) for a set time, it nudges the cursor a few pixels in a random direction and straight back, repeating on an interval until you touch the machine again. It never moves the cursor while you're using it.

## Features

- Lives in the menu bar — no Dock icon or window
- Only jiggles after you've been idle; any input pauses it
- Real system mouse events, so apps that check system idle time see activity
- Cursor returns to where it was, so it never drifts
- Settings saved automatically

## Requirements

- macOS 13 (Ventura) or later
- Swift toolchain — the Xcode Command Line Tools are enough (`xcode-select --install`)

## Build & install

```sh
./build.sh
cp -R MouseJiggler.app /Applications/
open /Applications/MouseJiggler.app
```

On first launch, macOS asks for **Accessibility** access, which is required to post mouse events. Grant it in **System Settings → Privacy & Security → Accessibility**. Until it's granted, the menu shows a "⚠️ Grant Accessibility Access…" shortcut at the top.

## Usage

Click the cursor icon in the menu bar:

| Setting | Options | Default |
|---|---|---|
| Enabled | on / off | on |
| Distance | 1, 2, 5, 10, 20, 50 px | 5 px |
| Interval | 10 sec – 10 min | 1 min |
| Idle Threshold | 10 sec – 30 min | 1 min |
| Launch at Login | on / off | off |

The icon dims when the jiggler is off.

## How it works

Every second the app reads the system idle time (`CGEventSource.secondsSinceLastEventType`). When it passes the idle threshold, it posts a HID mouse-move event to a point *distance* pixels away at a random angle, then moves the cursor back. Because those events also reset the system idle counter, the app remembers when it last jiggled and only treats you as active if input happened after that.

## Project layout

```
Package.swift                 Swift package definition
build.sh                      Builds and ad-hoc signs MouseJiggler.app
Resources/Info.plist          Bundle metadata (menu-bar-only app)
Sources/MouseJiggler/
  main.swift                  App entry point
  AppDelegate.swift           Menu bar icon, menu, actions
  Jiggler.swift               Idle detection and cursor movement
  Settings.swift              Persisted preferences
```

## Troubleshooting

- **Cursor doesn't move after a rebuild:** the app is ad-hoc signed, so macOS may treat each rebuild as a new app. Remove Mouse Jiggler from the Accessibility list, add it again, and relaunch.
- **Launch at Login won't enable:** check **System Settings → General → Login Items** and approve Mouse Jiggler there. The app needs to be in `/Applications`.
