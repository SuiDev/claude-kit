# frontend-boilerplate

フロントエンドアプリの新規作成と拡張を、規約と機械検証つきで実行する Claude Code スキルです。スタック選定からディレクトリ設計、デザイントークン、アクセシビリティ、E2E 品質検証までを一括で行います。

このファイルは人間向けの説明です。AI への命令書は `SKILL.md` にあり、実行時に読まれるのはそちらだけです。

## 何をするものか

- スタック選定: 要件から Next.js App Router / TanStack Start / TanStack Router を判定表で決めます
- ディレクトリ設計: Atomic Design の層（atoms / molecules / organisms / templates）と features / shared / external の分離
- 規約の機械的強制: import 境界の ESLint、デザイントークンの迂回検出、UX 規約の lint
- 状態網羅: 読込中・空・部分取得・エラー・権限なし・成功の6状態を完了条件にします
- 検証: lint、型、テスト、ビルド、バンドル寸法、3テーマのコントラスト、視覚回帰、LCP / CLS、操作対象の寸法を1コマンドで判定します

## 動かし方

前提は Docker が起動していることです。スクリプトの進行はホストの bash が担いますが、依存のインストール、ビルド、テスト、ブラウザ検証、JSON の解釈とバンドル計測まで、実行はすべてコンテナ内で行います。ホストのランタイム（python や node）には依存しません。

Claude Code のセッションで `/frontend-boilerplate` を呼ぶか、「管理画面作って」のような作成依頼で自動起動します。生成後の検証は次の1コマンドです。

```bash
bash ~/.claude/skills/frontend-boilerplate/scripts/verify.sh <app-root>
```

各ステップの所要時間が表示されます。失敗したステップだけを再実行する場合は `--only lint` のように指定できます（合否の最終判定はフルスイートで行います）。

## 何が保証されるか

`verify.sh` が PASS を返した時点で、次が機械的に確認されています。

| 項目 | 手段 |
|---|---|
| lint / 型 / 単体テスト / ビルド | コンテナ内で npm scripts を実行 |
| 初期 JavaScript の寸法 | ビルドマニフェストから gzip 後サイズを算出し予算と比較 |
| トークン迂回・汎用パレット直書き・アイコンの絵文字代用など | `scripts/ux-lint.sh` |
| 明色・暗色・高コントラストの3テーマでのコントラスト比 | Playwright による実測 |
| 共有部品の視覚的な破壊的変更 | 視覚回帰（基準画像との比較） |
| LCP / CLS / 操作対象の寸法 / 最小対応幅での横スクロール | Playwright |

しきい値はすべて生成先プロジェクトの `e2e/budgets.json` に集約されています。数値を変えるときはこのファイルだけを編集します。

機械判定できない項目（視覚階層、密度、文言など）は `assets/ux-review-checklist.md` に分離してあり、人手確認が未実施のまま完了と報告されることはありません。

## 設計上の意見

このスキルは意見が強めです。既定から外したい場合は依頼時に明示してください。

- 素の HTML と CDN 読み込みの React は採用しません。Create React App と新規の Pages Router も採用しません
- ローカルへの依存インストールとローカルビルドを行いません。すべて Docker です
- 主入力は机上ブラウザ（ポインタとキーボード）を既定とし、携帯端末が主要経路と明記された場合のみ切り替えます
- 重ね合わせ・選択・開閉・通知・表は自前実装せず shadcn/ui から生成します
- バージョンをドキュメントに決め打ちせず、実行時に `npm view` と公式手順で確認します
- 正常系だけの実装は未完成として扱います

## 構成

```
SKILL.md          AI への命令書（フェーズ定義、既定値表、エラーハンドリング）
references/       判断規範（スタック選定、UX、視覚設計、デザインシステム）
assets/           配置物の雛形（トークン、E2E、compose、チェックリスト）
scripts/          scaffold.sh / verify.sh / ux-lint.sh（shellcheck クリーン）
```

## 参考文献

- Nielsen Norman Group
- WCAG 2.2 AA
- Brad Frost, Atomic Design
- Radix Colors / Carbon Design System
