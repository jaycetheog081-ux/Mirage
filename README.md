# Mirage

Mirage is an original, from-scratch iOS userspace-emulation research project targeting an iOS 18.5-like guest environment.

## Current status

This is the **v0.1 bootstrap scaffold**. It includes:
- An Objective-C/UIKit host app.
- A C-based MirageCore command interpreter.
- A persistent, app-sandboxed guest root directory.
- A simple terminal UI.
- A GitHub Actions workflow that builds the iOS app.

The current core runs built-in Mirage commands (`help`, `pwd`, `ls`, `echo`, `cat`, `mkdir`, `write`, and `uname`). It does **not yet execute arbitrary Mach-O binaries**, boot Apple's iOS, or provide full POSIX/syscall compatibility. Those are separate future milestones.

## Build

Open `Mirage.xcodeproj` in Xcode and build the `Mirage` scheme for an iOS Simulator or a connected device.

GitHub Actions uses a macOS runner and builds for the iOS Simulator. Device installation/signing is not configured in this initial scaffold.

## Publish to GitHub from iPad

1. Create a **public** repository named `Mirage` on GitHub.
2. Download and unzip this source package.
3. In the repository, choose **Add file → Upload files**.
4. Upload the contents of the `Mirage` folder (including `.github` and `Mirage.xcodeproj`), then commit to `main`.
5. Open **Actions** and enable workflows if GitHub asks.

## Architecture

- `MirageApp/`: native UIKit app and terminal presentation.
- `MirageCore/`: C implementation of the first guest command layer.
- `Mirage.xcodeproj/`: Xcode project.
- `.github/workflows/ios.yml`: CI build.

## Planned next milestones

1. Improve guest filesystem operations and path handling.
2. Add a proper guest process model and structured command interface.
3. Implement a documented POSIX compatibility subset.
4. Investigate executable loading and dynamic linking for compatible guest binaries.
5. Explore Procursus package compatibility.
6. Build the virtual Home Screen, system-app simulations, and tweak preferences.

Sileo, NewTerm 3, arbitrary IPA execution, and real iOS system apps are goals to investigate—not features implemented by this scaffold.
