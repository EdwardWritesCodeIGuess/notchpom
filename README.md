# NotchPom

A small, native Pomodoro timer for the Mac menu bar, with a clickable countdown beside the MacBook notch. Built with SwiftUI and AppKit; no dependencies, accounts, or network requests.

## Try it

Requires macOS 13 or later and Xcode Command Line Tools (`xcode-select --install`).

```sh
bash scripts/build-app.sh
open dist/NotchPom.app
```

The controls open on first launch. After that, click the countdown in your menu bar. There is no Dock icon. To keep the app, drag `dist/NotchPom.app` into Applications.

- Set focus and break durations independently from **1–180 minutes**. Pause before editing; changing either duration resets the current session.
- Start/pause with the main button or Space while the controls are open. Reset restarts the current phase; skip switches phases without counting a completed focus session.
- Click the small notch countdown to start or pause.
- Sessions alternate between focus and break. The next session waits for you unless **Start next session automatically** is enabled.
- Duration, sound, auto-start, and notch visibility preferences persist. Relaunching starts a fresh focus session. The completed count is for this app launch.
- On a display without a notch, the optional floating timer appears just below the center of the menu bar. On a notched MacBook, it appears immediately to the right of the notch using the screen's reported geometry. Screen changes reposition it automatically.
- Quit from the menu bar controls.

## Develop and test

```sh
swift run TimerCoreChecks
swift run NotchPom
bash scripts/build-app.sh
dist/NotchPom.app/Contents/MacOS/NotchPom --smoke-test
```

The UI smoke test needs a logged-in macOS desktop session. It opens the controls, verifies the menu bar item/popover/panel initialize, prints `UI_SMOKE_PASS`, and quits. Set `NOTCHPOM_PREVIEW` to an absolute PNG path to save a view snapshot.

The timer uses a wall-clock deadline rather than counting ticks. After sleep, an expired session completes once, and the next phase starts fresh if auto-start is enabled. Sleeping does not accumulate fictional completed sessions. Tests cover pause/resume, delayed ticks, phase transitions, configuration bounds, reset, and repeated starts.

GitHub Actions tests and packages the app as a downloadable workflow artifact. Builds use the runner's CPU architecture. The local test build uses your Mac's architecture.

## Test-build limits

This is an ad-hoc signed development build, without Apple notarization. A copy downloaded onto another Mac may require **Open Anyway** in System Settings → Privacy & Security. No Accessibility or Screen Recording permission is needed by the app.

The floating notch panel can overlap menu bar items on crowded menu bars; disable **Show beside notch** if needed. Placement uses Apple's [NSScreen geometry APIs](https://developer.apple.com/documentation/appkit/nsscreen). Full-screen behavior can vary by application and macOS version. Physical notch placement and full-screen behavior should be checked on a notched MacBook before distributing a production release.

No background daemon, launch-at-login setup, long-break scheduling, or session history is included.
