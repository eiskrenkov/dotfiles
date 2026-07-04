# Sublime Merge — local patch

Vendored fork of [adhamu/history-in-sublime-merge](https://github.com/adhamu/history-in-sublime-merge)
(upstream `v1.3.3`), patched to work from the Command Palette and inside git
worktrees.

## Identity (forked to avoid marketplace conflicts)

To keep this fully independent of the marketplace extension, the identity was
changed so the two can never collide (extension id, command ids, or command
registration), regardless of install timing:

| | Marketplace | This fork |
|---|---|---|
| Extension id | `adhamu.history-in-sublime-merge` | `local.sublime-merge` |
| Command ids  | `history-in-sublime-merge.*` | `sublime-merge.*` |
| Config key   | `history-in-sublime-merge.path` | `sublime-merge.path` |
| Display name | History in Sublime Merge | Sublime Merge |

Keybindings referencing the old command ids were migrated in the managed
Cursor and VS Code `keybindings.json`. The marketplace id was removed from the
managed Cursor extensions list, and the install script uninstalls it before
installing this fork.

Installed headlessly into Cursor / VS Code by
`home/.chezmoiscripts/mac/run_onchange_install-sublime-merge.sh.tmpl`, which
runs `<editor> --install-extension` on the packaged `.vsix`. This folder lives
outside the chezmoi root (`home/`), so it is never copied into `$HOME`.

The only remaining `history-in-sublime-merge` references are upstream
attribution: the `repository` URL in `package.json` and the original upstream
`README.md`.

## What was broken

1. **Command Palette crash** — `Cannot read properties of undefined (reading 'path')`.
   `viewFileHistory` / `blameFile` read `file.path` directly, but the Command
   Palette invokes commands with no argument (`file === undefined`). Only the
   explorer / editor right-click passes a Uri.

2. **Worktrees never resolved the repository** — `getRepository` used
   `find-up('.git', { type: 'directory' })`. In a linked worktree (and in
   submodules) `.git` is a *file* containing `gitdir: …`, not a directory, so
   find-up skipped it and the repo could not be found.

## The fix (`src/extension.ts`)

- `openFile` now falls back to `vscode.window.activeTextEditor?.document.uri`
  when no Uri is passed, and passes a repository-relative path to Sublime Merge
  (matching what the line-history command already did — also correct in
  worktrees).
- `getRepository` walks up the tree with a small `fs`-based helper
  (`findGitPath`) that matches `.git` whether it is a file or a directory. This
  removed the `find-up` dependency entirely, so the bundle has zero runtime
  dependencies.

## Rebuilding the .vsix

Requires Node (see `.nvmrc`). From this directory:

```sh
npm install
npm run typecheck                       # optional: tsc --noEmit
npx @vscode/vsce package --no-dependencies
```

`vscode:prepublish` bundles `src/extension.ts` into `out/extension.js` with
esbuild (inlining any deps). After rebuilding, commit the new `.vsix`; the
`run_onchange` script re-installs it automatically on the next `chezmoi apply`
because its embedded `sha256` changes.
