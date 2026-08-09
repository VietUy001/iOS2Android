# iOS2Android Technical Overview

## Purpose

iOS2Android is a Claude Code skill for porting an iOS app written in Swift or SwiftUI to Android with Kotlin and Jetpack Compose, with measurable parity rather than a loose visual reinterpretation.
The iOS app is the oracle for structure, content, behavior, and feel, and each Android decision must trace back to observed iOS behavior or source.
Platform differences are recorded explicitly instead of being hidden.

The skill addresses common failure modes in AI-assisted ports:

- Missing screens, sections, states, or gated features.
- Layout that looks similar but has incorrect spacing or safe-area behavior.
- Lost animation, gestures, haptics, persistence, or navigation semantics.
- Placeholder code that compiles but does not implement the original flow.
- Premature completion claims without reproducible evidence.
- Android release failures that never appear in debug builds.

The workflow turns completion into a machine-checked state: no measurement means no VERIFIED state, and no complete ledger means no DONE state.

## The three parity pillars

Every screen and flow must satisfy all three pillars.

1. Visual parity covers layout, color, typography, icons, assets, themes, and every visible state.
2. Behavioral parity covers features, state machines, validation, edge cases, persistence, navigation, and platform service adapters.
3. Perceptual parity covers animation, transitions, gestures, haptics, sound, scrolling, and focus behavior.

Apple-only services are mapped to Android-native equivalents while preserving their user-facing role, such as APNs to FCM, StoreKit to Play Billing, and HealthKit to Health Connect.
Each platform-equivalent swap is documented in `DEVIATIONS.md`.

## Tolerance contract

| Category | Maximum deviation |
|---|---:|
| Position, size, and spacing | 2 dp |
| Color | 0, exact hex and alpha |
| Animation duration | 16 ms, one frame at 60 fps |
| Pixel difference per state | 1.0% after approved system chrome is excluded |
| Displayed text | 0, exact content through localization keys |

These thresholds are fixed by the Parity Contract and must not be weakened to make a failing port pass.
Unavoidable platform differences require a documented deviation.

## Source of truth and project modes

The Parity Spec is the single source of truth and contains a Structure Map, Flow Inventory, Completeness Ledger, screen specifications, measurements, and evidence links.
Existing Android code is not trusted merely because it exists, so a brownfield project is audited against iOS before old work is accepted.

Small apps may use Lite Mode, which keeps the same contract, tolerances, visual gates, and evidence requirements.
It reduces orchestration overhead and keeps the main agent sequential.

If the iOS app cannot build or run, Oracle-Limited Mode requires explicit user approval.
Source-derived evidence and a mandatory deviation must identify every item that cannot be measured at runtime.

## Pipeline from Stage -1 to Stage 6

### Stage -1: Preflight

Validate the iOS source, toolchain, source pin, test environment, and device pair.
The iOS app should build and run in an iOS Simulator before specification work begins.
The test backend must be staging, mock, or another approved non-production environment.
The manifest records the iOS revision and matching logical device sizes.
The `pre` mode does not require an Android Gradle wrapper for a greenfield project.
The `verify` mode later requires the complete measurement toolchain and a real connected Android target.

### Stage 0: Contract

Agree on the three pillars and fixed tolerances, then choose Lite or Full mode.
Identify brownfield intake requirements, artifact locations, and deviations that are already known.

### Stage 1: Spec extraction

Traverse the complete iOS source tree and give every relevant file a disposition in the Structure Map.
Exercise the full iOS UI, including content below the fold and all observable states.
Create the Flow Inventory before implementation.
For every screen, record Composition, Element, Layout, safe-area, Motion, and Log inventories.
Inspect source for hidden, hardware-only, feature-flagged, gated, and VIP behavior.
Copy the three checklists next to the project Parity Spec, which the user approves before Kotlin work starts.

### Stage 2: Scaffold

Create the Android skeleton with Kotlin DSL, Compose, and a feature structure that reflects iOS, then derive color, type, spacing, motion, and shape tokens from the spec.
Do not allow Material defaults to define visible parity-sensitive behavior.
Reuse the iOS asset catalog as the asset source of truth.
Use a metric-compatible font because SF Pro cannot be bundled on Android.
Put user-visible text in Android resources, with Vietnamese as the default locale, and pass `assembleDebug` before mapping proceeds.

### Stage 3: Map

Map each Swift or SwiftUI unit to the lowest-complexity Android implementation that reaches parity, using the knowledge base for language, layout, state, lifecycle, concurrency, navigation, motion, APIs, haptics, typography, and assets.
Write explicit adapters for platform-specific APIs instead of mechanically converting services with different contracts.
Document every unresolved parity limit before implementation.

### Stage 4: Port

Port one vertical flow at a time, including models, services, ViewModels, UI, tests, logs, build checks, and preliminary comparisons.
Do not spread work across many partially finished screens.
Search for reusable components and adapters before creating new ones.
Add centralized, privacy-safe logging with the code, and keep user-visible text in localization resources.
Each module must compile and match its approved spec before the next dependent module starts.

### Stage 5: Verify

Run preflight in `verify` mode first; Layer A then checks debug build, unit tests, anti-stub rules, file size, logging hygiene, and release/R8 build.
Layer B checks deterministic screenshots, pixel difference, onion-skin overlays, element IoU, displayed text, and exact source-derived colors.
Layer C walks through behavior and perceptual parity for every flow, gesture, edge case, animation, haptic, and back action.
Animation timing is derived from Swift source and confirmed with frame analysis, while performance is measured against iOS rather than judged by feel.
Every failure returns to implementation and repeats the measurement loop.

### Stage 6: Harvest

Add new mappings, adapters, motion conversions, and approved platform solutions back to `mapping-kb.md`, with a concrete Swift and Kotlin pair for each entry.
The reusable knowledge base improves later ports without changing the current app's oracle.

## Blocking gates

### Binary Definition of Done

The Completeness Ledger assigns one row to each screen, section, component, flow, function, animation, gesture, adapter, and string group; FAIL and RECHECK keep the project open.
`scripts/parity-status.sh` is the final authority for VERIFIED progress.
Its full mode prints `DONE` only when every ledger row is verified, every checklist is signed, deviations are closed, and full verification is green.
Fast mode can diagnose ledger state but can never print `DONE`.

### Evidence gate

A VERIFIED row needs reproducible evidence, including passing tests, signed checklist items, and paths to visual artifacts.
Screen and section rows need numeric measurement evidence such as `parity-diff %=...` or `IoU=...`.
An agent statement such as "looks correct" has no completion value.

### Section composition gate

The number of top-level iOS and Android sections must match in top-to-bottom order, one to one.
Hidden and gated subsystems still count.
Attribute-level comparison does not begin until composition passes.

### Element gate

Every iOS widget in the Element Inventory must map to Android, including cards, wrappers, heroes, icons, helper text, secondary actions, toggles, and headers.
Displayed text is compared separately so a low global pixel score cannot hide a missing text section.

### Layout and safe-area gate

Top and bottom insets must reproduce the iOS layout contract, and each top-level vertical anchor must stay within 2 dp.
Padding, margin, gap, alignment, and size come from iOS source or measured evidence.
Element bounding boxes are checked with IoU, with 0.90 as the default script threshold.

### Motion gate

Every element is inspected in source for animation, transitions, implicit motion, repeat behavior, and gesture-driven effects.
Elements with no motion are recorded explicitly as `none`.
Android timing must be within 16 ms, and sampled curve progress must stay within one frame.

### Device-pair rule

iOS points and Android density-independent pixels are compared one to one only when logical sizes match, such as 393x852 pt against 393x852 dp.
The manifest values must match, and the connected Android device is checked again before verification.
A mismatched pair invalidates pixel difference and IoU results.

### Log gate

Screens, regions, scroll events, decision branches, and caught errors require centralized logs; direct `Log.d`, `println`, and `System.out` calls are rejected.
Logs are guarded for debug builds, use lazy message construction, and must not contain personally identifiable information.
QA rejects a screen whose required log coverage is missing.

### Release gate

`assembleDebug` is not enough, so full verification runs `assembleRelease` to expose R8, minification, reflection, serialization, and resource-shrinking failures.
The release artifact must then be installed and smoke-tested on an emulator or device.
Release evidence is recorded per verified flow before DONE.

### Regression and performance gates

Changing a shared token, component, adapter, or string group moves dependent VERIFIED rows to RECHECK, and consumers repeat visual comparison before returning to VERIFIED.
Cold start should be no more than 20% slower than iOS.
Jank, frame targets, recomposition, main-thread work, and leaks are measured with platform tools.

## The seven scripts

| Script | Purpose |
|---|---|
| `scripts/preflight.sh` | Runs the staged environment gate. `pre` checks the oracle, source pin, non-production test backend, and declared device pair. `verify` adds Android tooling and validates the connected device. |
| `scripts/inventory.sh` | Traverses the iOS source and emits a Structure Map skeleton with file types, line counts, and large-file warnings. |
| `scripts/extract-assets.sh` | Maps iOS asset catalog bitmaps into Android density buckets and reports vectors, color sets, and app icons that require controlled manual handling. |
| `scripts/parity-diff.sh` | Determinizes capture, takes screenshots, computes pixel diff, creates onion overlays, checks element IoU, compares displayed text, samples color, and validates device size. |
| `scripts/verify.sh` | Checks file limits, stubs, localization risks, logging hygiene, debug build, unit tests, and optional full release/R8 build. |
| `scripts/parity-status.sh` | Evaluates the ledger, evidence, flow state, copied checklists, deviations, and full verification to print `DONE` or an exact `NOT DONE` reason. |
| `scripts/selftest.sh` | Exercises the core gates with temporary fixtures without requiring an emulator or a real Gradle project. |

The benchmark has separate scorer and self-test scripts that evaluate skill process compliance, not runtime parity.

## Installation for Claude Code

Clone the repository, copy it into the Claude Code skills directory, and keep the scripts executable:

```bash
git clone https://github.com/VietUy001/iOS2Android.git
mkdir -p ~/.claude/skills
cp -R iOS2Android ~/.claude/skills/ios2android
chmod +x ~/.claude/skills/ios2android/scripts/*.sh
```

Start the workflow in Claude Code with:

```text
/ios2android
```

The skill asks for absolute iOS and Android paths plus approval of the Parity Spec, manifest, and deviation document locations.

## Environment requirements

- macOS.
- Xcode and an iOS Simulator for the reference oracle.
- Android SDK, JDK, and an Android emulator or physical device.
- `adb`, `git`, and `xcrun`.
- `ffmpeg` for motion analysis.
- ImageMagick tools including `compare`, `convert`, `composite`, and `identify`.
- An Android device configuration whose logical dp size matches the iOS reference pt size.

Dependencies are never installed implicitly; the workflow proposes a minimal package and waits for user approval.

## Known limitations

The complete workflow is macOS-specific because it relies on Xcode and the iOS Simulator, while pixel and motion verification also require Android tooling and a connected target.
Some hardware capabilities need source-derived contracts, fixtures, or real-device testing.
Oracle-Limited Mode cannot supply normal runtime visual evidence and therefore requires explicit acceptance.
System font rendering, OS chrome, provider branding, permission UI, and other platform-owned surfaces may require documented deviations.

The included benchmark scores process compliance only, including inventory coverage, required spec sections, gate consistency, and anti-stub signals.
It does not score pixel parity or runtime behavioral parity.
Those outcomes require the real iOS Simulator, Android target, deterministic fixtures, and the Stage 5 evidence pipeline.
