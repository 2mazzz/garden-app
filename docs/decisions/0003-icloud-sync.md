# 0003 — CloudKit private database for sync, no custom backend

## Context

Garden data needs to appear on both phones without running or paying for
any server infrastructure.

## Decision

SwiftData's built-in CloudKit sync, writing to the *private* CloudKit
database of container `iCloud.com.tomasrojder.gardenapp`. Both phones sign
into the same iCloud account, so they read/write the same private database.

## Consequences

- Zero backend cost or maintenance; sync "just works" as long as both
  devices are online and signed into the right iCloud account.
- No push-notification entitlement (`aps-environment`) is configured, since
  that capability is more restricted under free Apple ID provisioning (see
  0005). This means sync is not instantly push-driven — it happens when the
  app is foregrounded/active, not necessarily the moment the other person
  makes a change. Acceptable for a garden-tracking app; revisit if it's
  ever annoying in practice, and once a paid developer account is in place
  it's a small add (`remote-notification` background mode + entitlement).
- SwiftData + CloudKit requires every model relationship to be optional and
  forbids unique constraints — all models here were written with that
  constraint in mind from the start.
