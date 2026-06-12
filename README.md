# 🦋 mayfly

Drop in some HTML and get back browser-viewable URLs, served as GitHub Actions **artifact previews**. Disposable HTML hosting.

Short-lived like a mayfly: branches vanish after **90 days**.

## How it works

1. You push `.html` files to a branch.
2. The `Preview` workflow uploads each changed `.html` as its own **non-zipped artifact**.
3. Each file gets a preview URL (also commented on the commit and shown in the run summary).
4. Open a URL and the file renders directly in your browser.

> GitHub Actions lets you open an artifact uploaded with `actions/upload-artifact@v7` and `archive: false` directly in the browser, but only for formats the browser can render natively (standalone HTML, images, markdown, etc.). This repo relies on that.

## Usage

**Fork** this repository (or use "Use this template") and use it under your own account.

### `mayfly` CLI

Put `mayfly` on your `PATH`:

```bash
# from your clone
ln -s "$PWD/mayfly" /usr/local/bin/mayfly   # or copy it anywhere on PATH
```

Push files and get JSON back (stdout is JSON only, so it pipes into `jq`):

```bash
mayfly -b my-page -f page.html -f assets.html
```

```json
{
  "branch": { "name": "my-page", "url": "https://github.com/you/mayfly/tree/my-page" },
  "files": [
    { "name": "page.html",   "url": "https://github.com/you/mayfly/actions/runs/123/artifacts/456" },
    { "name": "assets.html", "url": "https://github.com/you/mayfly/actions/runs/123/artifacts/789" }
  ]
}
```

Delete a branch when you're done:

```bash
mayfly delete -b my-page
```

The target repo is resolved from `--repo`, then `$MAYFLY_REPO`, then the repo of
the current directory (`gh repo view`). Run it inside your fork's clone, or set
`MAYFLY_REPO=you/mayfly`.

### Plain git

You don't need the CLI — pushing `.html` on any branch works too:

```bash
git checkout -b my-page
echo '<!doctype html><h1>hello</h1>' > index.html
git add index.html && git commit -m "add page" && git push -u origin my-page
```

## Constraints & notes

- **Only self-contained HTML renders.** Externally linked CSS / JS / images are not resolved, so inline everything (embed `<style>` / `<script>`, use data URIs for images).
- **URLs change on every push.** Artifacts are numbered per run, so there is no stable URL — you always get the latest preview's URL.
- **Retention is 90 days** (the artifact default). The `Cleanup stale branches` workflow deletes any branch (other than the default) with no commits in 90 days.
- **Visibility follows your fork's settings.** To keep previews private, make your fork private.

## Layout

| File | Role |
|---|---|
| `mayfly` | CLI: `push` files / `delete` a branch |
| `.github/workflows/preview.yml` | Uploads each pushed `.html` as an artifact and comments the URLs |
| `.github/workflows/cleanup.yml` | Deletes branches idle for 90 days, daily |
