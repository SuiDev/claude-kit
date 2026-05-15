# review-codex-loop

公式 [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) のネイティブレビュー API を直接呼び出し、通常レビューと敵対的レビューの 2 フェーズで指摘がなくなるまで Claude が自動修正を繰り返す Claude Code 用スキルです。

## 特徴

- 公式 `codex-companion.mjs` を直接実行するため、CLI ラッパー越しの劣化が発生しません。
- 2 フェーズ構成で実装バグと設計判断の両方を網羅的に検証します。
  - Phase 1: 通常レビュー (実装の正しさ・バグ・セキュリティ・パフォーマンス)
  - Phase 2: 敵対的レビュー (設計判断の妥当性・隠れた前提・トレードオフ)
- 各フェーズで指摘ゼロになるまで Claude が `Edit` ツールで自動修正を反復します。
- severity と confidence に基づいて修正優先度を判定し、無限ループ検出機構も組み込まれています。

## 前提条件

公式の codex-plugin-cc が Claude Code にインストール済みである必要があります。

```bash
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

未インストール状態でスキルを起動した場合、上記コマンドの案内を表示して終了します。

## インストール

本リポジトリを任意の場所にクローンし、スキルディレクトリにシンボリックリンクを張ります。

```bash
git clone https://github.com/SuiDev/claude-kit.git
ln -s "$(pwd)/claude-kit/skills/review-codex-loop" ~/.claude/skills/review-codex-loop
```

Claude Code を再起動するとスキルがロードされ、トリガーフレーズで起動できるようになります。

## 使い方

Claude Code のチャットで以下のいずれかのトリガーフレーズを入力します。

- `codex review loop`
- `codexレビューループ`
- `official review loop`

ベースブランチを明示したい場合は引数で渡せます。

```
codexレビューループ develop
```

引数を省略した場合は `develop` ブランチが存在すればそちらを、なければ `main` を自動検出します。

## 動作仕様

1. 公式プラグインの `codex-companion.mjs` のパスを `find ~/.claude/plugins` で動的解決します。
2. `git diff --stat <base-branch>` で差分の有無を確認します。
3. `node <codex-companion> review --wait --base <base-branch>` で通常レビューを実行します。
4. 結果の `verdict` と `findings` を解析し、severity と confidence に応じて Claude が `Edit` ツールで修正します。
5. 同一指摘が繰り返される場合は無限ループとして検出し、フェーズを打ち切ります。
6. 通常レビューで指摘がゼロになったら敵対的レビューに進み、同じループを実行します。
7. 両フェーズで指摘ゼロを達成、または最大反復回数 (デフォルト 5 回) に到達したら終了します。

## 修正方針

- 機能変更・仕様変更は行わず、バグ修正とリファクタのみに限定します。
- severity が `critical` の指摘は必ず修正します。
- `confidence >= 0.7` の指摘を優先し、`confidence < 0.3` の指摘はスキップして残存指摘として報告します。
- 修正に自信が持てない場合はスキップし、推奨アクションとして報告します。

## 出力

完了時に以下のサマリを日本語で出力します。

- Phase 1 / Phase 2 の反復回数と完了状態 (完了 / 上限到達 / ループ検出)
- 修正したファイル一覧
- 修正内容のサマリ
- 残存指摘 (severity, confidence 付き)
- 推奨アクション

## ライセンス

MIT License を採用しています。詳細は [LICENSE](https://github.com/SuiDev/claude-kit/blob/main/LICENSE) を参照してください。

## 関連リンク

- [codex-plugin-cc (公式)](https://github.com/openai/codex-plugin-cc)
- [Claude Code Skills ドキュメント](https://docs.claude.com/en/docs/claude-code/skills)
