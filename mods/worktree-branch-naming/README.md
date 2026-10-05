# worktree-branch-naming

Claude Code の `EnterWorktree` ツール（`--worktree` フラグや "work in a worktree" 指示）でワークスペースを作ると、名前を指定しなかった場合は `worktree-<ランダムな名前>` というブランチ名になる。このプラグインは、そのブランチ命名規則を好きなテンプレートに変更する。

## 仕組み

Claude Code の [`WorktreeCreate` フック](https://code.claude.com/docs/en/hooks#worktreecreate)はデフォルトの `git worktree` 作成ロジックを完全に置き換えられる。このプラグインはそのフックで:

1. 作成されるワークスペースの `name`（指定しなければ自動生成されたスラッグ）を受け取る
2. `branch_template` オプション（デフォルト `claude/{name}`）の `{name}` を置き換えてブランチ名を決める
3. 通常の `git worktree add` と同じ場所（`.claude/worktrees/<name>/`）にワークツリーを作り、そのブランチ名で作成する
4. 対になる `WorktreeRemove` フックで、ワークツリー削除時にブランチも削除する（デフォルトの git 連携だとブランチは残ってしまうため）

CLAUDE.md に「push 前にリネームして」と書くような運用はClaudeが指示を忘れたり解釈がブレたりするので避け、作成そのものを差し替えている。

## 設定

プラグイン有効化時に聞かれる設定（`/config` からも変更可能）:

| オプション | デフォルト | 説明 |
| :- | :- | :- |
| `branch_template` | `claude/{name}` | 作成するブランチ名のテンプレート。`{name}` がワークツリー名に置き換わる |
| `base_ref` | `fresh` | ブランチの起点。`fresh` はリモートのデフォルトブランチ、`head` は現在のローカル HEAD（Claude Code 組み込みの [`worktree.baseRef`](https://code.claude.com/docs/en/settings-reference#worktree) 設定と同じ意味） |

例えば `claude/issue-32-fix-{name}` にすると、`issue-32-fix-xxxx` という名前で worktree を作ったときにブランチが `claude/issue-32-fix-issue-32-fix-xxxx` のように重複するので、ワークツリー名自体をそのまま使う場合は `claude/{name}` のままで十分。Claude に「`issue-32-fix-xxx` という名前で worktree を作って」と頼めば、ブランチは `claude/issue-32-fix-xxx` になる。

## 試す

```sh
claude plugin validate mods/worktree-branch-naming
```

実際にセッションで使う場合は、マーケットプレイスなしで `--plugin-dir` から読み込める:

```sh
claude --plugin-dir mods/worktree-branch-naming
```

常用するならプロジェクトの `.claude/settings.json` に `enabledPlugins` で登録する。

## 制限事項

- `jq` と `git` が PATH にある必要がある。
- 既存のワークツリー名を再利用したときの「クリーンならデフォルトブランチにリセットする」という組み込みの挙動は再現していない。ブランチが既に存在する場合は単純に再利用する。
- 非 git リポジトリ（SVN/Perforce/Mercurial 用の `WorktreeCreate` フック代替）には対応していない。
