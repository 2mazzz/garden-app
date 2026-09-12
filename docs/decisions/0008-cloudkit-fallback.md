# 0008 — Fall back to local storage if the CloudKit container isn't provisioned

## Context

Discovered while first-ever running the app in the iOS Simulator
(2026-09-12): `ModelContainer(for:configurations:)` with a CloudKit-backed
`ModelConfiguration` throws if the CloudKit container isn't provisioned for
the current signing identity — which is always true on a Simulator build
signed "Sign to Run Locally" (no real team), and can also be true on a real
device the very first time, before Xcode has registered the container
under a real Apple ID/team. The original code (`fatalError` on any
`ModelContainer` creation error) turned this into an immediate crash loop.

## Decision

`GardenAppApp.init()` first attempts the CloudKit-backed configuration. If
that throws, it falls back to an identical schema with a local-only
(non-CloudKit) `ModelConfiguration` instead of crashing. Only if *that*
also fails does it `fatalError` — which would indicate a real schema bug,
not a provisioning issue.

## Consequences

- The app is usable (Simulator, or a real device before first proper
  signing) even when CloudKit isn't available yet — just without sync
  between the two phones until it's run with a real Apple ID team
  selected in Signing & Capabilities.
- There's currently no in-app indication of *which* mode it's running in
  (synced vs. local-only). If sync silently not working becomes confusing
  in practice, add a visible indicator rather than leaving it silent — not
  done yet since it hasn't been needed.
- This does not fix CloudKit provisioning itself — the real fix for actual
  two-phone sync is still running the app once on a real device with a
  real Apple ID team assigned, so Xcode registers the
  `iCloud.com.tomasrojder.gardenapp` container. That verification is still
  outstanding (see the design doc's testing section).
