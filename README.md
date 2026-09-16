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
- **CodeQL** (a security scan) is extended to cover your Vue/JavaScript
  application code, not just your GitHub Actions workflow files.

## What you might need to click once

GitHub does not let a repository's own built-in automation change that
repository's *settings* (branch protection, Pages, Dependabot, and so on —
see "Why some things need a manual step" below). So the very first run of
the "Bootstrap repository settings" workflow almost always ends **red** in
the **Actions** tab — that is expected, not a broken template. It is a
to-do list, not a failure: scroll to the bottom of its log for the one
command it needs a human to run.

- **Make sure your repository is Public.** ("Use this template" defaults to
  the visibility you pick when creating it — pick **Public**.) This
  organization is on GitHub's Free plan, where the CodeQL scan below only
  runs on public repositories. If your repository ends up private, pull
  requests can never be merged, because that scan is the one check required
  to merge. Fix it in **Settings → General → Danger Zone → Change repository
  visibility**.
- **Run the setup script once, as yourself:**
  ```sh
  ./scripts/setup-repo.sh          # macOS/Linux/WSL/Git Bash
  ./scripts/setup-repo.ps1         # Windows PowerShell
  ```
  This needs the [GitHub CLI](https://cli.github.com/) (`gh`), logged in as
  a user with admin rights on the new repository (`gh auth login`, once,
  if you have not already). It never touches or stores a token of its own —
  every command it runs uses your own `gh` session — and it is safe to run
  more than once: it checks what is already in place before changing
  anything, and just tells you so.
- If the **Actions** tab shows "Bootstrap repository settings" did not run
  automatically at all, open it and click **Run workflow** once.

### Why some things need a manual step

GitHub's built-in automation token (`GITHUB_TOKEN`) is deliberately never
allowed to manage a repository's own administrative settings — no
permission grants it that, at any level (confirmed directly: GitHub even
rejects a workflow file that tries to request it). So a handful of settings
that only a human — using their own GitHub login — is allowed to change:
protecting `main`, turning on Pages, enabling auto-merge, enabling
Dependabot's security updates, and extending the CodeQL scan to your
application code. `scripts/setup-repo.sh` / `.ps1` does all five in one go.

## Making changes

1. Create a branch (`feature/your-change`, `fix/your-change`, `chore/...` or
   `docs/...`).
2. Commit your changes and open a pull request against `main`.
3. Five checks run and are informational only — they can be red without
   blocking you, but it's worth fixing them: **consistency** (the Node
   version declared in `.nvmrc` and in `Dockerfile` still match), a
   dependency **audit**, the production **build**, **lint**, and **tests**
   (skipped automatically if the project has none yet).
4. One check is required: **CodeQL**, a security scan. Once it reports,
   you can merge your own pull request — no one else needs to approve it.
   This scan is not a workflow in this repository — the
   `museumwithnofrontiers` organization runs it automatically for every
   repository ("default setup"). Only *disabling* default setup, or
   replacing it with a custom workflow, is locked to organization owners;
   *extending its language coverage* (so it scans your Vue/JavaScript code,
   not just GitHub Actions workflow files) is an ordinary repository-admin
   action — `scripts/setup-repo.sh` already does it for you as part of the
   one-time setup above.
5. Merging into `main` automatically builds and publishes your site to
   GitHub Pages.

## Running it locally

You need [Node.js](https://nodejs.org/) installed — the version declared in
[`.nvmrc`](.nvmrc) (currently Node 24, the current LTS). If you use
[nvm](https://github.com/nvm-sh/nvm) or a similar tool, running `nvm use` in
this folder picks it up automatically.

```sh
npm install     # once, after cloning
npm run dev     # starts a local server and prints its address
```

Other useful commands:

```sh
npm run build   # produces the production build in dist/
npm run lint    # checks and auto-fixes code style
```

## Running it with Docker (recommended if you don't already have Node)

Nothing to install beyond [Docker Desktop](https://www.docker.com/products/docker-desktop/)
— the container uses the exact same Node version as CI, so "works on my
machine" differences are far less likely.

```sh
docker compose up          # starts the dev server at http://localhost:5173
```

Edits to the source under `src/` hot-reload in the browser as usual. Other
one-off commands, without starting the dev server:

```sh
docker compose run --rm dev npm run build
docker compose run --rm dev npm run lint
docker compose run --rm dev npm test
```

**Is Docker required?** No. `npm install && npm run dev` (above) is the
faster path if you already have Node installed locally, and it is exactly
what CI itself does. Docker is offered because it needs nothing installed
beyond Docker Desktop itself and removes any doubt about which Node version
or OS-level toolchain you're building with — but be aware that hot reload
inside a container is sometimes slower than running natively, and on some
Windows setups file-change notifications don't reach the container reliably
(if saves stop showing up live, set `CHOKIDAR_USEPOLLING=true` — see the
comment in `compose.yml`). Either way, what actually guarantees you get the
same dependency versions as CI is `package-lock.json`, not Docker — Docker
only guarantees the same *toolchain* (Node, npm), not the dependency tree,
which `package-lock.json` already pins regardless of where `npm install`
runs.

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
