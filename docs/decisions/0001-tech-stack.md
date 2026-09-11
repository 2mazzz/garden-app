# 0001 — Native SwiftUI over cross-platform or web

## Context

The app is for iPhone only, used by two people. Options considered: native
SwiftUI, React Native/Expo, or an installable web app (PWA).

## Decision

Native SwiftUI, targeting iOS 17+, using SwiftData for persistence.

## Consequences

- Best native feel and performance; direct access to SwiftData + CloudKit
  without a bridging layer.
- Requires a Mac with Xcode to build — there is no way to develop or ship
  this app from a non-Apple environment.
- No Android/web version is possible without a substantial rewrite. Given
  this is a 2-person iPhone-only app, that's an accepted trade-off, not an
  oversight.
