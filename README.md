# Lumina

Premium retro film camera app for iOS.

## Features
- Live camera preview with film effects
- Film stocks: Portra 400, Disposable Flash, Foggy SLR, Expired
- Vignette, grain, highlight crush, flash overexposure, lens haze
- Developing ritual animation after shutter

## Setup in Xcode

1. Create a new Xcode project: iOS App, SwiftUI, Swift.
2. Name it Lumina.
3. Delete the default ContentView.swift and LuminaApp.swift if they exist.
4. Add all the Swift files from this repo into the project (drag & drop, check "Copy items if needed").
5. In Info.plist (or target Info), add:
   - Privacy - Camera Usage Description: "Lumina needs camera access to capture film-style photos."
6. Set Deployment Target to iOS 16+.
7. Build and run on your device (with developer account).

Enjoy the imperfect beauty of film.
