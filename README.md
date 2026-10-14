# aaron-martin-phd.dev

Quarto website with the automated BBL Daily section. Editions arrive from the
HUB pipeline on the `editions` branch; GitHub Actions validates and renders
them, you approve the PR, merge to `main` deploys to GitHub Pages.

## One-time setup (owner)

0. The CI definitions live in `github-workflows/` (remote tooling cannot
   write `.github/workflows/` directly). Review them, then move:
   `mkdir -p .github/workflows && git mv github-workflows/*.yml .github/workflows/`
1. Create the GitHub repository (private or public; Pages needs public on
   free accounts) and push this directory as its initial `main` commit.
2. Repo Settings -> Pages -> Source: "GitHub Actions".
3. Repo Settings -> Pages -> Custom domain: `aaron-martin-phd.dev`
   (enforce HTTPS once the certificate is issued).
4. Porkbun DNS for aaron-martin-phd.dev:
   - A records on the apex: 185.199.108.153, 185.199.109.153,
     185.199.110.153, 185.199.111.153
   - CNAME `www` -> `<github-username>.github.io`
5. Deploy key for the pipeline (on HUB):
   `ssh-keygen -t ed25519 -f ~/.ssh/website_deploy -N ""` then add the public
   key under Repo Settings -> Deploy keys with **write access**.
6. Clone on HUB:
   `GIT_SSH_COMMAND="ssh -i ~/.ssh/website_deploy" git clone git@github.com:<user>/<repo>.git ~/newsletter/website`
   and set in the clone: `git config core.sshCommand "ssh -i ~/.ssh/website_deploy"`,
   plus `git config user.name "bbl-pipeline"` and `git config user.email "<your contact>"`.
7. In the pipeline's `config.yaml`: `website_repo: /home/aaron-martin/newsletter/website`.

## Flow

- Pipeline: `python -m bbl_newsletter ... publish` commits
  `bbl/posts/<date>.qmd` to `editions` and pushes.
- `edition-checks.yml`: validates every edition (frontmatter, structure,
  citations, English, live links), renders the site, opens/refreshes a PR
  to `main`. The PR is the manual approval gate.
- Merging the PR triggers `deploy.yml`: render + deploy to Pages.

Remove the approval gate later by enabling auto-merge on the PR or merging
from the pipeline; not before the summaries have earned it.
