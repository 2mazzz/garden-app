# 0002 — Shared iCloud account instead of per-user auth

## Context

Two people (a married couple) need to see and edit the same garden data.
Options considered: a real multi-user auth system, two personal logins
sharing data via CloudKit sharing, or no in-app auth at all.

## Decision

No in-app authentication. The app assumes whoever opens it is authorized,
and relies on both phones being signed into the same iCloud account for
CloudKit private-database sync to work (see 0003).

## Consequences

- Drastically simpler app — no login screens, no user model, no permission
  system to build or maintain.
- Access control is entirely outside the app's control: it's whatever
  iCloud account is signed in on the device. This is fine for a private,
  2-person household app and would not be fine for anything with more users
  or any sensitivity beyond "which vegetables are in bed 3."
- If this ever needs to support two *different* Apple IDs instead of one
  shared account, the sync mechanism (0003) would need to change to CloudKit
  *shared* zones (CKShare) rather than one private database — that's a
  bigger change than it sounds like, and should be its own ADR if it
  happens.
