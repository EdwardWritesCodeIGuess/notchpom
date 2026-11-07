# NotchPom

A tiny Pomodoro timer for your Mac menu bar, with a clickable countdown beside the MacBook notch. Simple controls, adjustable focus and break times, and a Liquid Glass background.

## Download

### [Download NotchPom for Mac](https://github.com/EdwardWritesCodeIGuess/notchpom/releases/latest/download/NotchPom.dmg)

**macOS 13 or later · Apple Silicon and Intel · Free · No account or developer tools needed**

[All releases and ZIP download](https://github.com/EdwardWritesCodeIGuess/notchpom/releases/latest)

## Install in a minute

1. Download **NotchPom.dmg** using the link above.
2. Open the downloaded disk image and drag **NotchPom** into the **Applications** shortcut.
3. Eject the disk image, then open **NotchPom** from Applications.
4. Click the countdown in your **menu bar** at the top of the screen. Set your **Focus** and **Break** minutes, then click **Start**.

NotchPom lives in the menu bar, so **there is no Dock icon**. The controls open automatically the first time.

### If macOS blocks the first launch

This is a community test build, ad-hoc signed but **not Apple-notarized**. macOS may say the developer cannot be verified or that Apple could not verify the app is free of malware.

1. Try opening NotchPom once, then dismiss the message.
2. Open **System Settings → Privacy & Security**.
3. Scroll to **Security**, click **Open Anyway** for NotchPom, then confirm **Open**. Authenticate if asked.

Use this exception only for the copy you intended to download from this repository. You do not need to disable Gatekeeper or run terminal commands. School or work Macs may require administrator approval. [Apple's first-launch instructions](https://support.apple.com/en-us/102445).

## Use the timer

| Control | What it does |
| --- | --- |
| Focus / Break | Set each duration independently, from **1–180 minutes**. Pause before editing; a change resets the current session. |
| Start / Pause | Run or pause the timer. Space works while the controls are open. |
| Reset ↶ | Reset the current focus or break session. |
| Skip ⏭ | Switch to the next phase without counting a completed focus session. |
| Show beside notch | Show a small countdown to the right of the MacBook notch. Click it to start or pause. |
| Auto-start | Start the next phase automatically. Off by default, so you control when to continue. |
| Sound | Play a sound when a session ends. |
| Quit | Close NotchPom from the bottom of the controls. |

On Macs without a notch, the floating timer appears just below the center of the menu bar. You can hide it and use only the menu bar countdown. Liquid Glass appears on **macOS 26+**; older versions use frosted material. Appearance follows macOS accessibility settings.

Duration and display preferences persist. Relaunching starts a fresh focus session; the completed count is for the current app launch. After sleep, an expired session completes once. Auto-start begins the next phase fresh rather than counting sessions while you were away.

## Update or uninstall

**Update:** Quit NotchPom, download the latest release, and replace the old copy in Applications. Your preferences are kept. Updates are manual.

**Uninstall:** Quit NotchPom and move it from Applications to Trash.

## Help

[Report a bug or request a feature](https://github.com/EdwardWritesCodeIGuess/notchpom/issues). Include your macOS version and whether your Mac has a notch. The floating timer may overlap items on crowded menu bars; turn off **Show beside notch** if needed. Full-screen behavior varies by application.

## Build from source

For developers: use **Xcode 26+ or matching Command Line Tools with the macOS 26+ SDK**. The app still runs on macOS 13+. Built with SwiftUI and AppKit, with no third-party dependencies or network requests.

```sh
git clone https://github.com/EdwardWritesCodeIGuess/notchpom.git
cd notchpom
swift run TimerCoreChecks
bash scripts/build-app.sh
open dist/NotchPom.app
```

To make the universal DMG, ZIP, and SHA-256 checksums:

```sh
bash scripts/package-release.sh
```

The timer checks cover pause/resume, delayed ticks, phase transitions, configuration bounds, reset, and repeated starts. To check the menu bar controls in a logged-in desktop session:

```sh
dist/NotchPom.app/Contents/MacOS/NotchPom --smoke-test
```

Set `NOTCHPOM_PREVIEW` to an absolute PNG path to capture the controls. GitHub Actions builds and tests pushes. Version tags (`v*`) also publish universal DMG/ZIP downloads to Releases with installation instructions.
