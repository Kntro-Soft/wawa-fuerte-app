# 0003. Android as the primary demo target

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

Team hardware is asymmetric and this constrains the target platform more than any technical
preference does:

| Developer          | Machine | Phone   |
|--------------------|---------|---------|
| jhosepmyr          | macOS   | iPhone  |
| sharvel-irigoyen   | Windows | Android |
| farioraro          | Windows | Android |
| Eric396            | Windows | Android |

iOS builds require macOS with Xcode. Three of four developers cannot produce an iOS build at all,
so an iOS-first target would leave 75% of the team unable to run what they are writing.

On-device inference cannot be validated on a simulator: the iOS Simulator is CPU-only with a 256 MB
Metal allocation cap, so the model will not run there. Real hardware is mandatory for the AI path,
and the team owns three Android handsets against one iPhone.

MediaPipe's LLM Inference API is also more widely exercised on Android than on iOS, where
`flutter_gemma` additionally requires hand-editing the Podfile to link `MediaPipeTasksGenAI`.

## Decision

**Android is the primary target**: the demo runs on a physical Android phone, and CI, testing, and
the "does it work" bar are all defined against Android.

- The three Windows developers install Flutter + Android SDK and test on their own handsets.
- The macOS developer does **not** install the Android SDK. Instead, non-inference work (UI, RAG,
  nutrition logic, storage) is developed against the **iOS Simulator**, which is already available
  via the installed Xcode and costs no additional download.
- Flutter is cross-platform, so this split costs nothing at the source level. iOS remains buildable
  as a bonus, not as a deliverable.

## Consequences

- No Android SDK download (1–2 GB) on the macOS machine, saving sprint time on the one machine that
  is already the integration bottleneck.
- The owner of the inference module must be one of the Android developers, since only they can
  validate the model on real hardware. This drives the role assignment in `AGENTS.md`.
- The macOS developer cannot personally verify the Gemma path end-to-end and must rely on the
  inference owner. Integration risk concentrates at the hour-4 checkpoint.
- Anything platform-specific (permissions, file paths, TTS voices) must be checked on Android before
  it is called done, even if it looked fine in the iOS Simulator.
- If the Android inference path fails, falling back to iOS is not realistic within the sprint — the
  contingency is a mocked inference layer plus a recorded video, not a platform switch.
