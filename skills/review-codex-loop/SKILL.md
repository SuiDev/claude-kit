---
name: review-codex-loop
description: "公式codex-plugin-ccのネイティブレビューAPIを直接呼び出し、通常レビューと敵対的レビューの2フェーズで指摘がなくなるまでClaudeが自動修正を繰り返すスキル。Triggers on: 'codex review loop', 'codexレビューループ', 'official review loop'."
argument-hint: "[base-branch (default: auto-detect develop or main)]"
allowed-tools: Bash(node:*), Bash(git:*), Bash(find:*), Read, Edit, Grep, Glob
---

# review-codex-loop — Codexネイティブレビュー × 2フェーズ自動修正ループ

公式 codex-plugin-cc の codex-companion.mjs を直接実行し、Codex のネイティブレビュー API でレビューする。
Phase 1 (通常レビュー) で実装バグを潰し、Phase 2 (敵対的レビュー) で設計判断を問う。
各フェーズで指摘がなくなるまで Claude が自動修正を繰り返す。

## 前提条件

codex-plugin-cc がインストール済みであること。
未インストールの場合は以下を案内して終了する:

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

## 実行手順

### 1. 初期化

#### 1.1 公式プラグインのスクリプトパスを解決

```bash
find ~/.claude/plugins -path "*/codex/scripts/codex-companion.mjs" -type f 2>/dev/null | head -1
```

見つからない場合は「codex-plugin-cc が未インストール」と案内して終了する。
見つかったパスを `CODEX_COMPANION` として保持する。

#### 1.2 パラメータ設定

- ベースブランチ: `$ARGUMENTS` からブランチ名を抽出。指定がない場合は以下で自動検出する:
  ```bash
  git rev-parse --verify develop 2>/dev/null && echo develop || echo main
  ```
- 最大反復回数 (各フェーズ): MAX_ITERS = 5

---

### 2. Phase 1: 通常レビューループ (実装の正しさ)

Codex のネイティブレビュー API で実装上のバグ、セキュリティ、パフォーマンス問題を検出・修正する。

- current_iter = 0
- prev_summary = null

以下を MAX_ITERS 回まで繰り返す:

#### Step 2.1: 差分確認

```bash
git diff --stat <base-branch>
```

差分がなければ「変更なし」と出力して終了する。

#### Step 2.2: 通常レビュー実行

```bash
node "$CODEX_COMPANION" review --wait --base <base-branch>
```

レビュー結果 (stdout) を全て記録する。

#### Step 2.3: レビュー結果の解析

レビュー結果から指摘を抽出する:

- verdict が `approve` かつ findings が空 → Phase 1 完了、Phase 2 へ進む
- verdict が `needs-attention` または findings あり → Step 2.4 へ

各 finding の構造:
- severity: critical / high / medium / low
- title: 指摘タイトル
- body: 詳細説明
- file: 対象ファイル
- line_start, line_end: 対象行範囲
- confidence: 0〜1 の数値
- recommendation: 修正提案

#### Step 2.4: Claude が指摘に基づいて修正

各指摘に対して、以下の優先順位で Edit ツールを使い修正を適用する:

1. critical (セキュリティ、重大バグ) — 必ず修正
2. high (バグパターン、リソースリーク) — 修正する
3. medium (コード重複、保守性) — 可能なら修正
4. low (軽微な改善) — スキップ可

修正判断の基準:
- confidence が 0.7 以上の指摘を優先する
- confidence が 0.3 未満の指摘はスキップし、終了時に残存指摘として報告する
- recommendation に具体的なコード例がある場合はそれを参考にする

修正ごとに「何を」「なぜ」修正したかを記録する。

制約:
- 機能変更・仕様変更は行わない (バグ修正・リファクタのみ)
- 修正に自信がない場合はスキップし、終了時に残存指摘として報告する

#### Step 2.5: 同一指摘チェック (無限ループ防止)

今回の指摘サマリ (findings の file + title の組み合わせ) と prev_summary を比較する。
実質的に同じ指摘セットが繰り返されている場合、Phase 1 を打ち切り Phase 2 へ進む。

prev_summary を今回の指摘サマリで更新する。

#### Step 2.6: 次のイテレーションへ

current_iter += 1 して Step 2.1 に戻る。
MAX_ITERS に達した場合は Phase 1 を打ち切り Phase 2 へ進む。

---

### 3. Phase 2: 敵対的レビューループ (設計判断の妥当性)

Phase 1 で実装バグが片付いた状態で、設計選択・トレードオフ・隠れた前提を問う。

- current_iter = 0
- prev_summary = null

以下を MAX_ITERS 回まで繰り返す:

#### Step 3.1: 敵対的レビュー実行

```bash
node "$CODEX_COMPANION" adversarial-review --wait --base <base-branch>
```

レビュー結果 (stdout) を全て記録する。

#### Step 3.2: レビュー結果の解析

Step 2.3 と同じ手順で指摘を抽出する:

- verdict が `approve` かつ findings が空 → Phase 2 完了、終了処理へ
- findings あり → Step 3.3 へ

#### Step 3.3: Claude が指摘に基づいて修正

Step 2.4 と同じ優先順位・判断基準で修正を適用する。

ただし敵対的レビューの指摘は設計レベルが多いため、以下に注意:
- リファクタの範囲が大きくなりすぎる場合はスキップし、残存指摘として報告する
- 設計変更が必要な指摘は修正せず、推奨アクションとして報告する

#### Step 3.4: 同一指摘チェック (無限ループ防止)

Step 2.5 と同じ手順。繰り返しを検出したらループを打ち切る。

#### Step 3.5: 次のイテレーションへ

current_iter += 1 して Step 3.1 に戻る。

---

### 4. 終了処理

#### 全フェーズ成功 (両フェーズ指摘ゼロ)

```
Codex レビュー完了 (2フェーズ)
- Phase 1 (通常): N1 回で完了
- Phase 2 (敵対的): N2 回で完了
- 修正したファイル: [リスト]
- 修正内容サマリ: [概要]
```

#### 残存指摘あり

```
Codex レビュー完了 (残存指摘あり)
- Phase 1 (通常): N1 回 [完了 / 上限到達 / ループ検出]
- Phase 2 (敵対的): N2 回 [完了 / 上限到達 / ループ検出]
- 修正したファイル: [リスト]
- 残存指摘: [リスト (severity, confidence 付き)]
- 推奨アクション: [提案]
```

## 注意事項

- レビューは Codex のネイティブレビュー API が行い、修正は Claude が行う
- 機能変更・仕様変更は行わない (バグ修正・リファクタのみ)
- セキュリティ関連の指摘は最優先で対応する
- レビュー結果・修正サマリは日本語で出力する
- 公式プラグインの更新に追従するため、スクリプトパスは毎回動的に解決する
