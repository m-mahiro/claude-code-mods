# claude-code-mods

Claude Code 用の mods（`claude plugin validate`/`claude plugin test` で検証できる、hooks ベースのプラグイン）を開発・管理するリポジトリです。

各 mod は `mods/<name>/` 以下に独立したプラグインとして置かれています。

## mods

- [`mods/btw-fix`](mods/btw-fix) — `/btw` がメイン会話をスクロール不能にし、パネルを閉じると回答がキャンセルされる問題への対処
