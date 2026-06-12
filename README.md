# 🦋 mayfly

A throwaway home for generated HTML (e.g. what an AI/agent produces while
working). Push a file, get a browser-viewable URL served as a GitHub Actions
**artifact preview**. Most of it is meant to vanish — preview branches disappear
after **90 days**, like a mayfly. The pieces worth keeping get promoted to
GitHub Pages.

This is **not** a general "paste any HTML" host. It's for HTML that comes out of
some process, that you want to glance at or share via a URL without it becoming
part of a codebase you merge.

## Two modes

| | command | mechanism | lifespan |
|---|---|---|---|
| **Throwaway** | `mayfly push` | per-file browser-viewable artifact on a `preview/*` branch | auto-deleted after 90 days |
| **Keep** | `mayfly keep` | opens a PR placing the file under `docs/<path>`; merging publishes it to GitHub Pages | persists; stable URL |

> Artifact previews work because GitHub Actions can open an artifact uploaded
> with `actions/upload-artifact@v7` + `archive: false` directly in the browser
> (standalone HTML, images, markdown). Self-contained HTML only — inline your
> CSS/JS/images. Pages, by contrast, serves a real static site (external assets
> work) at a stable URL.

## Access control

- **Throwaway/artifacts:** visibility follows the repo — make the repo private
  and only authenticated collaborators can open the preview URLs.
- **Keep/Pages:** on **GitHub Enterprise Cloud** you can set Pages visibility to
  *private* (Settings → Pages), so kept previews are restricted to people with
  repo access. On non-Enterprise accounts, Pages is always public.

## CLI

Put `mayfly` on your `PATH`:

```bash
ln -s "$PWD/mayfly" /usr/local/bin/mayfly
```

```bash
# throwaway preview — branch name auto-generated (preview/<ts>-<rnd>) if -b omitted
mayfly push -f /tmp/report.html
mayfly push -f a.html -f b.html --open      # multiple files, open the first in a browser
mayfly push -b design-review -f r.html      # name it to keep updating the same preview

# keep it — opens a PR placing the file at docs/<path> (the eventual Pages URL path)
mayfly keep -p design-v3/index.html -f /tmp/design.html
mayfly keep -p design-v3/index.html -b preview/20260612-... -f design.html   # source from a preview branch

# see what's live / clean up
mayfly list
mayfly delete -b preview/20260612-...        # one or more -b
mayfly delete --all-previews                 # every preview/* branch
```

`push` prints per-file URLs; `keep` prints the PR URL. stdout is JSON only
(stderr carries progress), so it pipes into `jq`:

```bash
mayfly push -f r.html | jq -r '.files[0].url'
```

**Fire-and-forget** (no need for a flag): background the call and capture the
JSON to a file.

```bash
mayfly push -f r.html > /tmp/r.json 2>/dev/null &
# ... later ...
jq -r '.files[0].url' /tmp/r.json
```

The CLI talks to the GitHub API (no local checkout), so an agent can call it
directly. Target repo: `--repo` > `$MAYFLY_REPO` > the current directory's repo.

### Shell completion

```bash
# zsh
source <(mayfly completion zsh)     # or save to a file in your $fpath
# bash
source <(mayfly completion bash)
```

## Layout

| File | Role |
|---|---|
| `mayfly` | CLI: `push` / `keep` / `list` / `delete` / `completion` |
| `.github/workflows/preview.yml` | Uploads each pushed `.html` as an artifact and comments the URLs |
| `.github/workflows/cleanup.yml` | Deletes `preview/*` branches idle for 90 days, daily |
| `.github/workflows/pages.yml` | Publishes `docs/` to GitHub Pages on merge to the default branch |
| `docs/` | GitHub Pages root; kept previews live here |
