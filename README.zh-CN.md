<div align="center">

<img src="assets/banner.png" alt="iOS2Android" width="100%">

[Tiếng Việt](README.md) · [English](README.en.md) · **中文** · [한국어](README.ko.md) · [日本語](README.ja.md)

![version](https://img.shields.io/badge/version-1.0.0-8FA8C4?style=flat-square)
![license](https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-22D3EE?style=flat-square)
![platform](https://img.shields.io/badge/platform-macOS-0B0F1A?style=flat-square)
![claude code](https://img.shields.io/badge/Claude%20Code-skill-38BDF8?style=flat-square)
![selftest](https://img.shields.io/badge/selftest-39%20checks-3DDC84?style=flat-square)

[![stars](https://img.shields.io/github/stars/VietUy001/iOS2Android?style=flat-square&color=FFD166)](https://github.com/VietUy001/iOS2Android/stargazers)
[![forks](https://img.shields.io/github/forks/VietUy001/iOS2Android?style=flat-square&color=8FA8C4)](https://github.com/VietUy001/iOS2Android/network/members)
![last commit](https://img.shields.io/github/last-commit/VietUy001/iOS2Android?style=flat-square&color=5B7290)

</div>

## iOS2Android 是什么

一个**面向 Claude Code 的 skill**：把 iOS 应用（Swift/SwiftUI）移植到 Android（Kotlin/Compose）的完整流程，目标是**可测量的 parity（一致性）**，而不是「照着做个差不多的」。

让 AI 移植应用的通病：它做出一个*看着有点像*的 Android 版本，少几个 section，纵向节奏对不上，动效丢失，然后宣布「基本完成」。这个 skill 把「完成」变成一个**由脚本判定的二元条件**，而不是让 agent 自己说了算。

```
没有量化数据  →  就不算 VERIFIED
没有 VERIFIED →  就不算 DONE
没有 DONE     →  agent 不允许停下
```

## parity 三大支柱与允许误差

| 项目 | 最大误差 |
|---|---|
| 位置 / 尺寸 / 间距 | ≤ 2 dp |
| 颜色 | 0（hex/alpha 完全一致） |
| animation 时长 | ≤ 16 ms（60fps 下 1 帧） |
| 每个 state 的 visual diff 像素占比 | ≤ 1.0%（剔除系统 chrome 后） |
| 文案内容 | 0（完全一致，通过 i18n key 对齐） |

- **支柱 1 Visual**：layout、颜色、typography、图标、theme、所有 state。
- **支柱 2 Behavioral**：功能、state machine、validation、edge case、persistence、navigation。
- **支柱 3 Perceptual**：animation、transition、手势、haptic、scroll physics。

凡是无法做到 100% 一致的地方（系统字体、back gesture、ripple、Apple 独有服务）都必须写进 `DEVIATIONS.md` 并等待用户批准，不允许悄悄改成别的做法。

## Pipeline

<img src="assets/pipeline.png" alt="Pipeline stage -1 到 6" width="100%">

## 验证 gate 链

没有截图和量化数据就没有 parity。每一道 gate 都由脚本检查，卡在哪道 gate 就在那里立即停下。

<img src="assets/gates.png" alt="Verify gate chain" width="100%">

## 仓库里有什么

| 文件 | 作用 |
|---|---|
| `SKILL.md` | 指南针：formula card、pipeline、18 条不变量规则、load-on-demand 对照表 |
| `enforcement.md` | 防半途而废的强制约束：ledger、Definition of Done、no-stop、anti-stub、element gate、section gate、release gate、log gate |
| `measurement.md` | 真实测量方法：visual diff、onion-skin、IoU、设备配对、animation 测量、perf、regression baseline |
| `mapping-kb.md` | Swift ↔ Kotlin 映射知识库：motion、layout、state、concurrency、navigation、API、typography、i18n、log |
| `orchestration.md` | 有边界的任务拆分、跨多个会话 resume、防止 context 膨胀 |
| `roles.md` | 8 个角色：MANAGER、UI-AUDITOR、SOURCE-ANALYST、FLOW-CHECKER、DEV-FE、DEV-FUNC、QA-RECONCILER、PERF-OPTIMIZER |
| `telegram-grade.md` | 从 Telegram 源码提炼的 animation/render 技术，并附带防止用力过猛的 gate |
| `parity-spec.template.md` | 黄金文档模板：Structure Map、Flow Inventory、ledger、逐屏 spec |
| `manifest.template.md` | 输入声明：path、source pin、test-env、设备配对、mode |
| `checklists/` | 3 份需手工签署的 checklist：ui-parity、capability、standards |
| `scripts/` | 7 个 script：preflight、inventory、extract-assets、parity-diff、verify、parity-status、selftest |
| `benchmark/` | 迷你 iOS app + process compliance 评分器 |

## 安装

**方式一：通过 plugin marketplace（最快，之后更新也只需一条命令）**

```
/plugin marketplace add VietUy001/iOS2Android
/plugin install ios2android@ios2android
```

**方式二：手动复制**

```bash
git clone https://github.com/VietUy001/iOS2Android.git
mkdir -p ~/.claude/skills
cp -R iOS2Android/plugins/ios2android/skills/ios2android ~/.claude/skills/
chmod +x ~/.claude/skills/ios2android/scripts/*.sh
```

然后在 Claude Code 中输入：

```
/ios2android
```

skill 会询问两个绝对路径（iOS 源码与目标 Android 目录），请你确认文档放置位置，然后运行 preflight。

## 环境要求

- macOS、Xcode + iOS Simulator（充当 oracle：iOS app 跑不起来就没有可比对的基准）。
- Android SDK、JDK、emulator 或真机。
- `adb`、`ffmpeg`、ImageMagick（`compare`、`convert`、`composite`、`identify`）、`git`。
- 重要：Android emulator 必须与作为参照的 iOS 设备具有**相同的 logical size**（例如两边都是 393x852）。dp 对不齐，所有 %diff 和 IoU 数字都没有意义。

## 自检

```bash
scripts/selftest.sh      # 39 条针对各道 gate 的断言：ledger、证据、deviation、preflight、IoU、texts-diff
benchmark/selftest.sh    # 检查 benchmark 评分器
```

在示例 app 上运行 benchmark：

```bash
T=$(mktemp -d); cp -R benchmark/fixture-ios "$T/ios"; mkdir "$T/android"
# 运行 /ios2android，指向 $T/ios 与 $T/android，跑完 stage 1
benchmark/score.sh "$T/parity-spec.md" "$T/android"
```

## 已知限制

- 只能在 macOS 上运行，因为 oracle 必须是 iOS Simulator。
- benchmark 评的是**流程**，不评 pixel parity：像素测量需要同时用到 simulator 和 emulator，无法自动化。
- iOS app 无法构建时，必须启用 ORACLE-LIMITED 并接受失去支柱 1，需要用户签字确认。
- doctrine 文档使用越南语撰写。英文摘要见 [docs/overview.en.md](docs/overview.en.md)。

## 作者

**Nguyen Viet Uy** · [@VietUy001](https://github.com/VietUy001)

- Facebook: https://www.facebook.com/1206463405
- Telegram: https://t.me/QTUNUy

反馈、问题报告或使用疑问：可通过 Telegram 联系，或在仓库提 issue。

## 许可证

[CC BY-NC-ND 4.0](LICENSE)：可免费用于个人、学习、研究以及非商业的内部工作。**禁止商业用途。禁止发布修改版。** 使用时请注明出处并附上原始仓库链接。

作者希望你**不要镜像或转载**本仓库。请链接回原始版本，让所有人都能拿到最新版。

<div align="center">
<sub>iOS2Android · parity 是量出来的，不是感觉出来的</sub>
</div>
