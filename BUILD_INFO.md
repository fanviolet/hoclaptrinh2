# Build 0.3.0

Godot 4.7.2 / Blender 5.2.1. Android portrait, ARM64 and x86_64.

The active GitHub Actions workflow is the authoritative build recipe. It generates
model and audio assets, runs the integration smoke suite, signs a test APK, verifies
its ZIP and Android signature, and installs/launches it on an Android API 35 emulator.
The Android export uses the official Godot binary template; the actual minimum and
target SDK values are those embedded in that template and should be checked from
the resulting APK before any store submission.

This is an offline playable build. Store uses in-game currency. Arena bot opponents
are labelled; human matchmaking remains unavailable until a server is integrated.
