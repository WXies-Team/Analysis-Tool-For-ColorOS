# AGENTS.md — Analysis Tool For ColorOS

Python CLI that downloads ColorOS ROMs, extracts images and version-tracks APKs into JSON sets; released with **semantic-release**: every push to `main`/`beta` runs `release.yml` (version from Conventional Commits → 8 platform zips → OpenList + GitHub Release). No `VERSION` file, no marker commit, no hand-written release notes.

## Commands

| Purpose | Command |
| --- | --- |
| Install (only Python dep) | `pip install -r requirements.txt` (`pyaxmlparser==0.3.31`) |
| Usage / all flags | `python3 main.py -h` (flow `-d` → `-p` → `-i` → `-f` → …) |
| Release dry-run (no publish) | `npx --package semantic-release --package conventional-changelog-conventionalcommits semantic-release --dry-run --no-ci` |
| Pack script syntax | `bash -n ci/pack-all.sh && bash -n ci/prepare-release.sh && bash -n ci/publish-openlist.sh` |
| Workflow YAML parse | `python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml` |
| No server paths in source | `grep -rn '/www/' ci .github && echo FAIL \|\| echo OK` |

No test suite; these are the only local checks. Local run needs Python 3.x + `aria2c` + 7zip; distributed zips bundle `payload-dumper-go` and `extract.erofs` in `tools/` (CI fetches them via `gh release download` — upstream 500s → rerun). The self-hosted runner's workspace persists, so check stale `output/` before trusting artifacts.

## Release model (semantic-release)

`release.config.mjs` drives everything: `feat`→MINOR, `fix`/`perf`/`revert`→PATCH, `!`/`BREAKING CHANGE:`→MAJOR; push `main` → stable `X.Y.Z`, push `beta` → `X.Y.Z-beta.N`. `ci/prepare-release.sh` reads the generated notes from stdin, writes `changelog.txt` and calls `ci/pack-all.sh` (data-driven 8-platform packer); `ci/publish-openlist.sh` maps the channel and calls `ci/upload-openlist.sh` with `ARTIFACT_DIR=output` / `ARTIFACT_PREFIX`/ `PRIMARY_ARTIFACT`. GitHub Release assets are `output/*.zip`. Changelog headings are Chinese with emoji (`✨ 新增` / `🐛 修复` / `⚡ 改进` / `🚨 破坏性变更`).

## Context loading

| Task | Read |
| --- | --- |
| Release rules / templates | `~/.config/opencode/docs/VERSIONING.md`, `RELEASE-PIPELINE.md`, `COMMITTING.md` |
| Shared across the three Analysis tools | `~/.config/opencode/docs/SISTER-REPOS.md` |
| CI / deploy behavior | `.github/workflows/release.yml`, `ci/pack-all.sh`, `ci/upload-openlist.sh` |
| End-user usage | `README.md` |

## Boundaries

### Always
- Use the `docs:` prefix for doc-only commits (`paths-ignore` skips the release; changelog hides docs/chore/ci/test/style/build/refactor/revert).
- Keep `ci/pack-all.sh`'s platform table in sync with upstream asset names; `gh release download` patterns were verified against live assets.
- Keep `ci/upload-openlist.sh` standalone: `bash -n` clean and free of hard-coded server paths (`OPENLIST_STORAGE_DIR` comes from secret `SERVER_OPENLIST_DIR`).

### Ask first
- Changing the platform table, artifact naming, OpenList retention, or `.github/workflows/release.yml`.
- Bumping a dependency pin in `ci/pack-all.sh` (erofs macOS tag is pinned because newer builds dropped `extract.erofs`).

### Never
- Hand-edit `CHANGELOG.md`, `changelog.txt` or `version.json` on the server — CI regenerates and uploads them.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`) or extracted ROM dirs.
- Reintroduce a `VERSION` file, `chore(release)` marker, `release-notes.md` or `ci/release-*.sh` scripts.

General rules: `~/.config/opencode/AGENTS.md`.
