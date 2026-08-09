<div align="center">

<img src="assets/banner.png" alt="iOS2Android" width="100%">

[Tiếng Việt](README.md) · [English](README.en.md) · [中文](README.zh-CN.md) · [한국어](README.ko.md) · **日本語**

![version](https://img.shields.io/badge/version-1.0.0-8FA8C4?style=flat-square)
![license](https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-22D3EE?style=flat-square)
![platform](https://img.shields.io/badge/platform-macOS-0B0F1A?style=flat-square)
![claude code](https://img.shields.io/badge/Claude%20Code-skill-38BDF8?style=flat-square)
![selftest](https://img.shields.io/badge/selftest-39%20checks-3DDC84?style=flat-square)

</div>

## iOS2Android とは

**Claude Code 用の skill**。iOS アプリ（Swift/SwiftUI）を Android（Kotlin/Compose）へ port するためのワークフローであり、目標は **測定可能な parity** であって、「なんとなく似せて作り直す」ことではない。

AI に port を任せたときの問題はこうだ。*なんとなく似ている* Android 版ができあがり、section がいくつか欠け、縦方向のリズムがずれ、エフェクトが失われたまま「ほぼ完了」と宣言される。この skill は「完了」を、agent の自己判断ではなく **script が決める二値条件** に変える。

```
測定値がない      →  VERIFIED ではない
VERIFIED でない   →  DONE ではない
DONE でない       →  agent は停止を許されない
```

## parity の 3 本柱と許容誤差

| 項目 | 最大誤差 |
|---|---|
| 位置 / サイズ / spacing | ≤ 2 dp |
| 色 | 0（hex/alpha が完全一致） |
| animation の長さ | ≤ 16 ms（60fps で 1 frame） |
| state ごとの pixel visual diff | ≤ 1.0%（システム chrome を除外後） |
| テキスト内容 | 0（i18n key 経由で完全一致） |

- **第 1 の柱 Visual**: layout、色、typography、icon、theme、すべての state。
- **第 2 の柱 Behavioral**: 機能、state machine、validation、edge case、persistence、navigation。
- **第 3 の柱 Perceptual**: animation、transition、gesture、haptic、scroll physics。

100% 一致させられない箇所（システムフォント、back gesture、ripple、Apple 独自のサービス）は `DEVIATIONS.md` に記録し、ユーザーの承認を待つこと。黙って別の実装にしてはならない。

## Pipeline

<img src="assets/pipeline.png" alt="Pipeline stage -1 から 6" width="100%">

## 検証ゲートの連鎖

スクリーンショットと測定値がなければ parity は成立しない。各ゲートは script が検査し、いずれかのゲートで落ちた時点でそこで停止する。

<img src="assets/gates.png" alt="Verify gate chain" width="100%">

## repo の中身

| File | 役割 |
|---|---|
| `SKILL.md` | 羅針盤: formula card、pipeline、18 個の不変ルール、load-on-demand 表 |
| `enforcement.md` | 途中放棄を防ぐ強制フォーム: ledger、Definition of Done、no-stop、anti-stub、element gate、section gate、release gate、log gate |
| `measurement.md` | 実測の方法: visual diff、onion-skin、IoU、デバイスペア、animation 計測、perf、regression baseline |
| `mapping-kb.md` | Swift ↔ Kotlin のマッピング集: motion、layout、state、concurrency、navigation、API、typography、i18n、log |
| `orchestration.md` | 上限を設けたタスク分割、複数セッションをまたぐ resume、context 肥大化の抑制 |
| `roles.md` | 8 つの役割: MANAGER、UI-AUDITOR、SOURCE-ANALYST、FLOW-CHECKER、DEV-FE、DEV-FUNC、QA-RECONCILER、PERF-OPTIMIZER |
| `telegram-grade.md` | Telegram の source から抽出した animation/render 技法と、やり過ぎを防ぐゲート |
| `parity-spec.template.md` | ゴールデンドキュメントのテンプレート: Structure Map、Flow Inventory、ledger、画面ごとの spec |
| `manifest.template.md` | 入力の宣言: path、source pin、test-env、デバイスペア、mode |
| `checklists/` | 手でサインする 3 つの checklist: ui-parity、capability、standards |
| `scripts/` | 7 つの script: preflight、inventory、extract-assets、parity-diff、verify、parity-status、selftest |
| `benchmark/` | ミニ iOS アプリ + process compliance の採点機 |

## インストール

**方法 1: plugin marketplace を使う（最速で、更新もコマンド 1 つで済む）**

```
/plugin marketplace add VietUy001/iOS2Android
/plugin install ios2android@ios2android
```

**方法 2: 手動でコピーする**

```bash
git clone https://github.com/VietUy001/iOS2Android.git
mkdir -p ~/.claude/skills
cp -R iOS2Android/plugins/ios2android/skills/ios2android ~/.claude/skills/
chmod +x ~/.claude/skills/ios2android/scripts/*.sh
```

その後 Claude Code で次を入力する:

```
/ios2android
```

skill が絶対パスを 2 つ（iOS ソースと対象の Android フォルダ）尋ね、ドキュメントの置き場所を確認してから preflight を実行する。

## 動作環境

- macOS、Xcode + iOS Simulator（oracle として使う。iOS アプリを動かせなければ比較対象が存在しない）。
- Android SDK、JDK、emulator または実機。
- `adb`、`ffmpeg`、ImageMagick（`compare`、`convert`、`composite`、`identify`）、`git`。
- 重要: Android emulator は参照する iOS デバイスと **同じ logical size** でなければならない（例: どちらも 393x852）。dp がずれると %diff や IoU の数値はすべて無意味になる。

## セルフチェック

```bash
scripts/selftest.sh      # 各ゲートに対する 39 個の assertion: ledger、証跡、deviation、preflight、IoU、texts-diff
benchmark/selftest.sh    # benchmark 採点機の検査
```

サンプルアプリで benchmark を実行する:

```bash
T=$(mktemp -d); cp -R benchmark/fixture-ios "$T/ios"; mkdir "$T/android"
# /ios2android を $T/ios と $T/android に向けて stage 1 完了まで実行する
benchmark/score.sh "$T/parity-spec.md" "$T/android"
```

## 既知の制限

- oracle が iOS Simulator 必須のため、macOS でしか動作しない。
- benchmark が採点するのは **プロセス** であり、pixel parity ではない。pixel の測定には simulator と emulator の両方が必要なため、自動化できない。
- iOS アプリが build できない場合は ORACLE-LIMITED を有効にし、第 1 の柱を失うことを受け入れる必要がある。ユーザーによる承諾の署名が要る。
- doctrine のドキュメントはベトナム語で書かれている。英語の要約は [docs/overview.en.md](docs/overview.en.md) にある。

## 作者

**Nguyen Viet Uy** · [@VietUy001](https://github.com/VietUy001)

- Facebook: https://www.facebook.com/1206463405
- Telegram: https://t.me/QTUNUy

フィードバック、バグ報告、使い方の質問は Telegram または repository の issue で受け付けている。

## ライセンス

[CC BY-NC-ND 4.0](LICENSE): 個人利用、学習、研究、および非商用の社内業務には無償で使える。**商用利用は禁止。改変版の配布も禁止。** 利用する際は出典を明記し、オリジナルの repo へリンクすること。

作者は、この repo を他所に **mirror したり再掲したりしないこと** を望んでいる。誰もが常に最新版を受け取れるよう、オリジナルへリンクしてほしい。

<div align="center">
<sub>iOS2Android · parity は測定値であって、感覚ではない</sub>
</div>
