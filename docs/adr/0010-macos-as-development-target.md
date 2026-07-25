# 0010. macOS as a development-only target

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

ADR-0003 assigns the macOS developer the non-inference work and expects them to run it against the
iOS Simulator, on the grounds that Xcode was already installed and no further download was needed.

That assumption turned out to be wrong. Xcode 26.6 ships the iOS 26.5 SDK, but the only simulator
runtime present on the machine is iOS 26.3, left over from an earlier Xcode. `xcodebuild
-showdestinations` reports no simulator destination at all for the Runner scheme — only the
`Any iOS Device` placeholder, with `iOS 26.5 is not installed`.

Fixing that properly means `xcodebuild -downloadPlatform iOS`, roughly 7–8 GB. The machine is
running on a phone hotspot, because the venue Wi-Fi measured ~66 KB/s against ~2 MB/s tethered.
Spending 7–8 GB of a personal mobile data plan, plus about an hour, to obtain a simulator that
**cannot run the model anyway** (ADR-0004) is a poor trade inside a six-hour sprint.

The macOS SDK, by contrast, is already installed and needs no download.

## Decision

Add **macOS as a development-only target** so the macOS developer can run the app locally with
`flutter run -d macos`.

- `macos/` is committed so the target keeps working across clones.
- It exists to exercise UI, fakes, and pure-Dart logic on the one machine that cannot build for
  Android. It is **not** a deliverable and is never demoed.
- Android remains the primary and only shipped target (ADR-0003). iOS remains a bonus that is now
  effectively unavailable on this machine until the platform is downloaded.
- Nothing platform-specific may be considered done because it worked on macOS. Permissions, file
  paths, and TTS voices are still verified on a physical Android handset.

## Consequences

- Zero download and zero mobile data spent; the macOS developer is unblocked immediately.
- A third platform folder now exists in the repository. It costs one `flutter create` invocation and
  is inert for everyone else.
- Desktop window sizing does not reflect a phone screen, so layout judgements made on macOS can
  mislead. Layout is reviewed on Android before it counts.
- Plugins that lack macOS support (notably `flutter_gemma`, which is Android/iOS only) will not
  build here. This is why every device-bound dependency sits behind an interface with a fake
  (ADR-0004) — the macOS target only ever runs the fakes.
- If the iOS platform is downloaded later, this ADR does not need reversing; the macOS target simply
  becomes redundant.
