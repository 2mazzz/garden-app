# 0005 — Free Apple ID provisioning instead of paid developer account

## Context

The app needs to be installed on two personal iPhones, not distributed
publicly. A paid Apple Developer account ($99/year) enables TestFlight and
push notifications; free provisioning does not, and app installs expire
roughly every 7 days without a reinstall from Xcode.

## Decision

Use free (non-paid) Apple ID provisioning for now.

## Consequences

- No ongoing cost.
- Each phone must be reconnected to a Mac and re-run from Xcode roughly
  weekly, or the installed app stops opening.
- No push-notification entitlement available, which is part of why sync is
  foreground-driven rather than instant (see 0003).
- If the 7-day reinstall cadence becomes annoying, upgrading to a paid
  developer account removes both limitations — that's a config-only change
  (enable the capability, switch provisioning), not a rewrite.
