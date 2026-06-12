# 🦋 mayfly

Drop in some HTML and get back a browser-viewable URL, served as a GitHub Actions **artifact preview**. Disposable HTML hosting.

Short-lived like a mayfly: branches vanish after **90 days**.

## How it works

1. Edit a `.html` file and push it.
2. The `Preview` workflow runs and uploads the changed `.html` files as a **non-zipped artifact**.
3. The preview URL is posted as a comment on the pushed commit (and shown in the Actions run summary).
4. Open the URL, click an `.html` file, and it renders in your browser.

> GitHub Actions lets you open an artifact uploaded with `actions/upload-artifact@v7` and `archive: false` directly in the browser, but only for formats the browser can render natively (standalone HTML, images, markdown, etc.). This repo relies on that.

## Usage

**Fork** this repository (or use "Use this template" to create a copy) and use it under your own account.

```bash
# Create a branch and add your HTML
git checkout -b my-page
echo '<!doctype html><h1>hello</h1>' > index.html
git add index.html && git commit -m "add page"
git push -u origin my-page
```

Once the Actions run finishes, the preview URL is commented on the target commit.

## Constraints & notes

- **Only self-contained HTML renders.** Externally linked CSS / JS / images are not resolved, so inline everything you want to display (embed `<style>` / `<script>`, use data URIs for images).
- **The URL changes on every push.** Artifacts are numbered per run, so there is no stable URL — you always get the URL of the latest preview.
- **Retention is 90 days** (the artifact default). The `Cleanup stale branches` workflow deletes any branch (other than the default) with no commits in 90 days.
- **Visibility follows your fork's repository settings.** To keep previews private, make your fork private.

## Workflows

| File | Role |
|---|---|
| `.github/workflows/preview.yml` | Uploads pushed `.html` as an artifact and comments the URL |
| `.github/workflows/cleanup.yml` | Deletes branches idle for 90 days, daily |
