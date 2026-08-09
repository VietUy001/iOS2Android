<div align="center">

<img src="assets/banner.png" alt="iOS2Android" width="100%">

[Tiếng Việt](README.md) · **English** · [中文](README.zh-CN.md) · [한국어](README.ko.md) · [日本語](README.ja.md)

![version](https://img.shields.io/badge/version-1.0.0-8FA8C4?style=flat-square)
![license](https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-22D3EE?style=flat-square)
![platform](https://img.shields.io/badge/platform-macOS-0B0F1A?style=flat-square)
![claude code](https://img.shields.io/badge/Claude%20Code-skill-38BDF8?style=flat-square)
![selftest](https://img.shields.io/badge/selftest-39%20checks-3DDC84?style=flat-square)

[![stars](https://img.shields.io/github/stars/VietUy001/iOS2Android?style=flat-square&color=FFD166)](https://github.com/VietUy001/iOS2Android/stargazers)
[![forks](https://img.shields.io/github/forks/VietUy001/iOS2Android?style=flat-square&color=8FA8C4)](https://github.com/VietUy001/iOS2Android/network/members)
![last commit](https://img.shields.io/github/last-commit/VietUy001/iOS2Android?style=flat-square&color=5B7290)

</div>

## What iOS2Android is

A **Claude Code skill**: a process for porting an iOS app (Swift/SwiftUI) to Android (Kotlin/Compose) with **measurable parity**, not "rebuild something that looks roughly the same".

The usual failure mode when an AI ports an app: it produces an Android build that *looks similar*, quietly drops a section, shifts the vertical rhythm, loses an animation, then declares "basically done". This skill turns "done" into a **binary condition decided by a script**, never by the agent's own judgement.

```
No measurement   ->  not VERIFIED
Not VERIFIED     ->  not DONE
Not DONE         ->  the agent is not allowed to stop
```

## Three parity pillars and the tolerance table

| Item | Max deviation |
|---|---|
| Position / size / spacing | ≤ 2 dp |
| Colour | 0 (exact hex/alpha) |
| Animation duration | ≤ 16 ms (one frame @60fps) |
| Pixel diff per state | ≤ 1.0% after system chrome is cropped |
| Text content | 0 (identical, through i18n keys) |

- **Pillar 1, Visual**: layout, colour, typography, icons, theme, every state.
- **Pillar 2, Behavioural**: features, state machines, validation, edge cases, persistence, navigation.
- **Pillar 3, Perceptual**: animation, transitions, gestures, haptics, scroll physics.

Anything that genuinely cannot match (system font, back gesture, ripple, Apple-only services) goes into `DEVIATIONS.md` and waits for the user to sign off. Silently diverging is not allowed.

## Pipeline

<img src="assets/pipeline.png" alt="Pipeline stage -1 to 6" width="100%">

## Verify gate chain

No screenshots and no numbers means no parity. Every gate is script-checked, and failing one stops the chain right there.

<img src="assets/gates.png" alt="Verify gate chain" width="100%">

## What is in the repo

| File | Role |
|---|---|
| `SKILL.md` | The compass: formula card, pipeline, 18 invariants, load-on-demand table |
| `enforcement.md` | Anti-abandonment machinery: ledger, Definition of Done, no-stop, anti-stub, element gate, section gate, release gate, log gate |
| `measurement.md` | How to actually measure: visual diff, onion-skin, IoU, device pairing, animation timing, perf, regression baselines |
| `mapping-kb.md` | Swift ↔ Kotlin knowledge base: motion, layout, state, concurrency, navigation, platform APIs, typography, i18n, logging |
| `orchestration.md` | Bounded task splitting, resuming across sessions, keeping context thin |
| `roles.md` | 8 roles: MANAGER, UI-AUDITOR, SOURCE-ANALYST, FLOW-CHECKER, DEV-FE, DEV-FUNC, QA-RECONCILER, PERF-OPTIMIZER |
| `telegram-grade.md` | Animation and rendering techniques distilled from Telegram source, with an anti-over-engineering gate |
| `parity-spec.template.md` | The golden document: Structure Map, Flow Inventory, ledger, per-screen spec |
| `manifest.template.md` | Inputs: paths, source pin, test env, device pair, mode |
| `checklists/` | Three signed checklists: ui-parity, capability, standards |
| `scripts/` | Seven scripts: preflight, inventory, extract-assets, parity-diff, verify, parity-status, selftest |
| `benchmark/` | A miniature iOS app plus a process-compliance scorer |

## Install

**Option 1: plugin marketplace (fastest, and updates are one command too)**

```
/plugin marketplace add VietUy001/iOS2Android
/plugin install ios2android@ios2android
```

**Option 2: copy the folder yourself**

```bash
git clone https://github.com/VietUy001/iOS2Android.git
mkdir -p ~/.claude/skills
cp -R iOS2Android/plugins/ios2android/skills/ios2android ~/.claude/skills/
chmod +x ~/.claude/skills/ios2android/scripts/*.sh
```

Then in Claude Code:

```
/ios2android
```

The skill asks for two absolute paths (iOS source and the target Android folder), asks where to put its documents, and runs preflight.

## Requirements

- macOS with Xcode and the iOS Simulator. The running iOS app is the oracle: without it there is nothing to compare against.
- Android SDK, JDK, an emulator or a real device.
- `adb`, `ffmpeg`, ImageMagick (`compare`, `convert`, `composite`, `identify`), `git`.
- Important: the Android device must have the **same logical size** as the reference iOS device (for example both at 393x852). If dp and pt differ, every %diff and IoU number is meaningless.

## Self-test

```bash
scripts/selftest.sh      # 39 assertions over the gates: ledger, evidence, deviations, preflight, IoU, texts-diff
benchmark/selftest.sh    # checks the benchmark scorer itself
```

Run the benchmark against the sample app:

```bash
T=$(mktemp -d); cp -R benchmark/fixture-ios "$T/ios"; mkdir "$T/android"
# run /ios2android against $T/ios and $T/android, through stage 1
benchmark/score.sh "$T/parity-spec.md" "$T/android"
```

## Known limits

- macOS only, because the oracle has to be the iOS Simulator.
- The benchmark scores **process compliance**, not pixel parity: measuring pixels needs both a simulator and an emulator, which is impractical to automate.
- If the iOS app cannot be built, you must enable ORACLE-LIMITED mode, lose Pillar 1, and get an explicit user sign-off.
- The doctrine files are written in Vietnamese. An English summary lives in [docs/overview.en.md](docs/overview.en.md).

## ⭐ Star History

If this project helps you, please consider giving it a star.

<a href="https://star-history.com/#VietUy001/iOS2Android&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=VietUy001/iOS2Android&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=VietUy001/iOS2Android&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=VietUy001/iOS2Android&type=Date" width="100%" />
  </picture>
</a>

## Author

**Nguyen Viet Uy** · [@VietUy001](https://github.com/VietUy001)

- Facebook: https://www.facebook.com/1206463405
- Telegram: https://t.me/QTUNUy

Feedback, bug reports or questions: message me on Telegram or open an issue.

## Licence

[CC BY-NC-ND 4.0](LICENSE): free for personal, educational, research and internal non-commercial use. **No commercial use. No distribution of modified versions.** Credit the author and link back to the original repository.

The author asks you **not to mirror or re-upload** this repository elsewhere. Link to the original instead, so people always get the maintained version.

<div align="center">
<sub>iOS2Android · parity is a number, not an impression</sub>
</div>
