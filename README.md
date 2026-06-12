# 🦋 mayfly

A throwaway home for generated HTML (e.g. what an AI/agent produces while
working). Push a file, get a browser-viewable URL served as a GitHub Actions
**artifact preview**. Most of it is meant to vanish — branches disappear after
**90 days**, like a mayfly. The pieces worth keeping can be committed instead.

This is **not** a general "paste any HTML" host. It's for HTML that comes out of
some process, that you want to glance at or share via a URL without it becoming
part of a codebase you merge.

## Two modes

| | command | lives on | lifespan |
|---|---|---|---|
| **Throwaway** (default) | `mayfly push -b <branch> ...` | a throwaway branch | auto-deleted after 90 days |
| **Keep** (design doc) | `mayfly keep ...` | the default branch | persists until you remove it |

Both upload each `.html` as its own browser-viewable artifact and return the
preview URLs. (Artifacts themselves always expire after 90 days; `keep` persists
the *source* so you can always re-preview it.)

## How it works

1. You publish `.html` files to a branch (via the CLI or plain git).
2. The `Preview` workflow uploads each changed `.html` as its own **non-zipped artifact**.
3. Each file gets a preview URL (also commented on the commit and shown in the run summary).
4. Open a URL and the file renders directly in your browser.

> GitHub Actions lets you open an artifact uploaded with `actions/upload-artifact@v7` and `archive: false` directly in the browser, but only for formats the browser can render natively (standalone HTML, images, markdown, etc.). This repo relies on that.

## Access control

Previews live in this repo as artifacts, so visibility follows the repo's
settings: make the repo **private** and only authenticated collaborators can
open the preview URLs.

## CLI

Put `mayfly` on your `PATH`:

```bash
ln -s "$PWD/mayfly" /usr/local/bin/mayfly   # or copy it anywhere on PATH
```

```bash
# throwaway preview (stdout is JSON only, so it pipes into jq)
mayfly push -b agent-run-42 -f /tmp/report.html

# keep some of them as design docs (committed to the default branch under docs/)
mayfly keep -p docs -f /tmp/design-v3.html

# clean up a throwaway branch early
mayfly delete -b agent-run-42
```

```json
{
  "branch": { "name": "agent-run-42", "url": "https://github.com/you/mayfly/tree/agent-run-42" },
  "files": [
    { "name": "report.html", "url": "https://github.com/you/mayfly/actions/runs/123/artifacts/456" }
  ]
}
```

The CLI talks to the GitHub API (no local checkout needed), so an agent can call
it directly. The target repo is resolved from `--repo`, then `$MAYFLY_REPO`,
then the repo of the current directory (`gh repo view`).

## Layout

| File | Role |
|---|---|
| `mayfly` | CLI: `push` (throwaway) / `keep` (persist) / `delete` |
| `.github/workflows/preview.yml` | Uploads each pushed `.html` as an artifact and comments the URLs |
| `.github/workflows/cleanup.yml` | Deletes branches idle for 90 days, daily (default branch is never touched) |
