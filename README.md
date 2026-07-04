# SnapKeys

Tiny keyboard-only macOS window mover. It is meant to cover the useful parts of
Magnet without global mouse hooks, edge dragging, or polling.

I built this because I was running into severe Magnet performance issues where
macOS input events, including scrolling and typing, would stop registering
reliably. I only needed keyboard-driven window splits, so SnapKeys intentionally
keeps the scope much smaller.

## AI disclosure

This project was written end to end by OpenAI Codex in response to a user request.
The human maintainer chose the requirements, reviewed the resulting behavior, and
published the source for transparency.

This is intentionally small software. Please audit the code before relying on it
for anything sensitive.

## Why

SnapKeys exists for people who only need keyboard-driven window positioning and
want to avoid always-on window-manager behavior. It does not try to clone drag
snapping, edge detection, window previews, Spaces behavior, or complex app rules.

The original motivation was replacing my personal Magnet usage after repeated
input-lag and high-CPU problems.

SnapKeys is not affiliated with Magnet, CrowdCafé, or BOOTCODE A.S.

## Privacy and security

SnapKeys requires macOS Accessibility permission so it can move the focused
window. The current code does not include networking, telemetry, analytics,
automatic updates, or persistence beyond running as a menu bar app.

Its event model is deliberately quiet: it registers global keyboard shortcuts and
does nothing until one of those shortcuts, or one of its menu commands, is used.

## Build

```sh
make
```

The app bundle is written to:

```text
.build/SnapKeys.app
```

Run it with:

```sh
make run
```

For day-to-day use, install it to a stable path first:

```sh
make run-installed
```

That installs and launches `~/Applications/SnapKeys.app`.

On first use, choose `Grant Accessibility Permission` from the SnapKeys menu bar
menu, or open System Settings > Privacy & Security > Accessibility and enable
SnapKeys. If you previously granted permission to a copy under `.build`, remove
that old entry and grant permission to `~/Applications/SnapKeys.app`.

## Download

Prebuilt app zips are attached to GitHub Releases:

https://github.com/akhilravidas/SnapKeys/releases

Release builds are ad-hoc signed but not notarized. macOS may require opening
the app from Finder with Control-click > Open the first time.

## Install from source

```sh
git clone https://github.com/akhilravidas/SnapKeys.git
cd SnapKeys
make run
```

For a normal install, copy `.build/SnapKeys.app` to `/Applications` after
building it, or run `make install` to install to `~/Applications/SnapKeys.app`.

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Left 5/8 | Control-Option-E |
| Right 3/8 | Control-Option-G |
| Left | Control-Option-Left |
| Right | Control-Option-Right |
| Top | Control-Option-Up |
| Bottom | Control-Option-Down |
| Top Left | Control-Option-U |
| Top Right | Control-Option-I |
| Bottom Left | Control-Option-J |
| Bottom Right | Control-Option-K |
| Left Third | Control-Option-D |
| Center Third | Control-Option-F |
| Right Third | Control-Option-H |
| Left Two Thirds | Control-Option-Shift-W |
| Center Two Thirds | Control-Option-R |
| Right Two Thirds | Control-Option-T |
| Maximize | Control-Option-Return |
| Center | Control-Option-C |

## Design

SnapKeys only wakes up when a registered hotkey or menu item is used. It does
not install a mouse event tap, does not watch dragging, and does not continuously
poll Accessibility or WindowServer.

The default shortcuts use Control-Option, not Command-Control.

## License

MIT.
