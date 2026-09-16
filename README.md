# Vue.js Template

A starter for a Vue 3 site, ready to use with almost no setup. Click **Use
this template** (green button, top right of this page on GitHub) to get your
own copy — a new repository with its own name, your own code, and a live
website, set up automatically.

This template does **not** depend on any Museum With No Frontiers shared
package or workflow. It is self-contained: everything it needs travels with
the files you get.

## What happens automatically

As soon as your repository is created, a workflow runs once to finish
setting it up (this takes under a minute):

- Your `main` branch is protected: nobody (including you) can push to it
  directly — all changes go through a pull request. Force-push and branch
  deletion are blocked too.
- **No review is required** — you can open a pull request and merge it
  yourself, as soon as its checks report.
- **GitHub Pages** is turned on, so your site will be published at
  `https://museumwithnofrontiers.github.io/<your-repo-name>/`.
- **Dependabot** is turned on. It opens a pull request for minor and patch
  dependency updates (never major ones, which need a human decision), and
  those pull requests merge themselves automatically once their checks pass.

## What you might need to click once

- **Make sure your repository is Public.** ("Use this template" defaults to
  the visibility you pick when creating it — pick **Public**.) This
  organization is on GitHub's Free plan, where the security scan below only
  runs on public repositories. If your repository ends up private, pull
  requests can never be merged, because that scan is the one check required
  to merge. If this happens, switch it in **Settings → General → Danger
  Zone → Change repository visibility**, then re-run the "Bootstrap
  repository settings" workflow from the **Actions** tab.
- If the **Actions** tab shows the "Bootstrap repository settings" workflow
  did *not* run automatically, open it and click **Run workflow** once. It
  is safe to run more than once.
- If any step of that workflow reports an error (rare — it means the
  built-in token could not make a particular change), the workflow's log
  tells you exactly which one-line command to run yourself to finish it. Ask
  Pascal if you are unsure.

## Making changes

1. Create a branch (`feature/your-change`, `fix/your-change`, `chore/...` or
   `docs/...`).
2. Commit your changes and open a pull request against `main`.
3. Four checks run and are informational only — they can be red without
   blocking you, but it's worth fixing them: a dependency **audit**, the
   production **build**, **lint**, and **tests** (skipped automatically if
   the project has none yet).
4. One check is required: **CodeQL**, a security scan. Once it reports,
   you can merge your own pull request — no one else needs to approve it.
   This scan is not a workflow in this repository — the
   `museumwithnofrontiers` organization runs it automatically for every
   repository ("default setup"), and individual repositories cannot turn it
   off or replace it with their own. As shipped, it scans your GitHub
   Actions workflow files, not your Vue/JavaScript code — if you want it to
   scan your application code too, ask an organization owner to add
   JavaScript/TypeScript to the organization's default code-scanning
   configuration (Organization Settings → Code security → Configurations).
   A repository admin cannot do this themselves; the API explicitly refuses
   with "controlled by organization administrators."
5. Merging into `main` automatically builds and publishes your site to
   GitHub Pages.

## Running it locally

You need [Node.js](https://nodejs.org/) installed (LTS version).

```sh
npm install     # once, after cloning
npm run dev     # starts a local server and prints its address
```

Other useful commands:

```sh
npm run build   # produces the production build in dist/
npm run lint    # checks and auto-fixes code style
```

## Where your site appears

`https://museumwithnofrontiers.github.io/<your-repo-name>/` — replace
`<your-repo-name>` with whatever you named your repository when you used
this template. It updates a minute or two after every merge to `main`.

## Recommended editor

[Visual Studio Code](https://code.visualstudio.com/) with the extensions
recommended in `.vscode/extensions.json` (VS Code will offer to install them
automatically when you open the project) — Vue's official language support
(Volar) and ESLint. Format-on-save and fix-on-save are already configured.

## License

See [`LICENSE.md`](LICENSE.md).
