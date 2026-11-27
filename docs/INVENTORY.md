# Inventory

Everything Inkproof-specific in the reference, inkproof-forge at the commit [PLAN.md](PLAN.md#the-reference) names, and where each piece goes. Seams are those of the reference's `proposals/generic-specific-split.md`. Anything a file holds that is not listed here is the kit's or a layer's, and stays with the guild.

## Destinations

| Destination | Meaning |
|---|---|
| **configuration** | Lean values of the guild's types, in this repository |
| **text** | Files in this repository: roles, protocol sections, the project document |
| **settings** | The environment, through this repository's settings template |
| **deployment** | This repository's allowlist additions or compose overrides |
| **kit**, **Lean**, **Lasm** | The guild, or one of its layers: Inkproof supplies nothing |
| **gone** | Not carried over |
| **interface** | The guild must be able to express it before it can go anywhere: see [What the interface must express](#what-the-interface-must-express) |

## `agents.conf`

| Lines | Content | Destination |
|---|---|---|
| 1-22 | The format, and the kinds and what each does | kit |
| 24-40 | 17 agents: name, kind, own repository, repositories it files on | configuration |
| `*` in 24, 37-40 | Every repository but the agent's own | configuration: the guild expands it, or Inkproof lists them |
| 24 | The coordinator owns `inkproof-coordination` | configuration: the coordination repository |
| 25 | `devtools` owns `inkproof-tools`: an agent's name need not match its repository's | configuration |

## `roles/`

All seventeen are text, with the placeholders `{{AGENT}}`, `{{ORG}}`, `{{GH_OWNER}}` and `{{FORGE_WEB_URL}}`. They also name `inkproof-coordination` (29 times across roles and protocol) and the project's repositories by the bare prefix `inkproof-` (9 times), which need placeholders of their own (interface). Beyond that, six of them hold text that is not Inkproof's but the behaviour of their kind, which the dispatcher's rules rely on.

| Role | Inkproof's own | The kind's (interface) |
|---|---|---|
| `coordinator.md` | The opening (its files), the `PRIOR-ART.md` bullet, the ARCH-1 bullets, the FP-3 example | Milestones, Priority, Closing what you finish, Releases (`scripts/release.sh`, `Release <repo>` decisions), At autonomy level 3, When the kit is idle (`ROADMAP.md`, `Status: finished`, the idle summary's form) |
| `conformance.md` | Nothing | All of it: the review procedure, findings' states, `forge review`, the three protocol checks |
| `process.md` | The `inkproof-coordination#235` example | All of the rest: the evidence (`forge ledger`, the archive at `/var/lib/inkproof/archive-all/`), the review, Supervision and its nudge limit |
| `architecture.md` | The questions | Report once, and reading earlier `review:<agent>` recommendations |
| `lasm.md` | Lasm's purpose and what to gather | Report once, and reading earlier recommendations, as for architecture |
| `demos.md` | uPlot, the dependencies, ACC-10, PERF-5, the rendering limits | Deployment (`build-site.sh`, `_site/`, relative paths, no `github.io` access): the Lasm layer's `site` kind |
| The eleven library roles | All of it | Nothing; but "Dependencies" restates configuration, and the `inkproof-tools` line is in ten roles, so it could be one project protocol section |

## `docker/agent/PROTOCOL.md`

| Lines | Section | Destination |
|---|---|---|
| 3 | "the Inkproof libraries" | configuration: the project's name |
| 5, 9, 11 | Introduction, Trust | kit |
| 10 | `Ghost`'s issues were migrated from GitHub | kit, for any project imported into Forgejo (interface); Inkproof's Forgejo holds that history |
| 15-18, 20 | Tools: `tea`, `forge`, `git`, denied commands | kit |
| 19 | Chromium, Playwright pinned at 1.64.1 | Lasm |
| 21 | Toolchains: elan, and Lasm's cache | Lean, Lasm |
| 25-35 | Working in your repository | kit; the `inkproof-demo#35` example in 27 is Inkproof's, and should become a generic one |
| 36 | `API.lock` changes | Lean (seam 5) |
| 37 | `README.md` keeps `## What it does` | text: Inkproof's convention, which conformance and the architecture review check |
| 38 | Files only the human may change | configuration (seam 6) |
| 42-46 | Comments | kit |
| 50-51 | Dependencies: release tags, no `Internal`, GitHub URLs fetched from Forgejo | Lean; 51 is the Forgejo mode with mirrors |
| 55-62 | Reuse before you build: the order, Loogle, Reservoir, the `Prior art:` line | Lean; 57-58 need the coordination repository and the project's repositories as placeholders |
| 64 | Two reasons not to reuse: PLAT-3 and WebAssembly size | text: PLAT-3 is Inkproof's requirement, and the size reason is Lasm's |
| 66-69 | Where it exists, and what to do | kit; 67 (ARCH-1) and 68 (PLAT-3) name Inkproof's requirements, so text |
| 73-78 | Never work around a dependency | kit; 76's Lasm bindings are Lasm |
| 80 | File only on dependencies and `inkproof-coordination` | kit, with the coordination repository as a placeholder |
| 84-107 | Handling requests on your repository | kit |
| 111-121 | Decisions for the human | kit |
| 125-130 | Sessions with the human | kit; 130 names `.inkproof/` (seam 1, interface) |
| 134, 138 | Requirements: where `REQUIREMENTS.md` lives | kit, with the coordination repository as a placeholder |
| 136 | Its cross-cutting sections: floating point, process, platform, validation, trusted computing base | text |
| 142-144 | Conventions: `CLAUDE.md`, `DESIGN.md`, Forgejo links | kit |
| 148-160 | Priority, Finishing a task | kit |
| 164 | Definition of done | kit and Lean (versioning from `API.lock`, `forge version`); "under Lasm" is Lasm; the `Theorems:` line is text, as Inkproof's convention |

## `.env.example`

The values below are the reference's defaults. Where the production kit's `.env` sets another, it is given too, and the bounds start from it.

| Setting | Reference value | Destination |
|---|---|---|
| `GH_OWNER`, `GH_FORMER_OWNERS` | `paulbutcher`, `tentenths` | configuration |
| `MIRROR_BRANCHES` | `main` | configuration |
| `FORGE_ORG` | `tentenths` | interface: neither of the guild's lists names it |
| `REPO_PREFIX` | `inkproof-` | gone: the explicit list of repositories replaces it |
| `HUMAN_USER`, `HUMAN_EMAIL` | the human's account | settings |
| `HOST_UID`, `HOST_GID`, `STATE_DIR`, `FORGE_PORT`, `DISPATCHER_PORT` | `501`, `20`, `./`, `3000`, `3001` | settings; at the switch, the guild's `STATE_DIR` holds a copy of the reference's state, which the reference then points at for the way back |
| `MAX_RUN_MINUTES`, `MAX_RUNS_PER_DAY`, `MAX_COORDINATOR_RUNS_PER_DAY`, `MAX_SPEND_PER_DAY` | 240, 20, 40, 0; production sets 150 and 250 runs a day | configuration: bounds, at production's values |
| `AGENT_MEMORY`, `AGENT_PIDS`, `AGENT_CPUS`, `CI_MEMORY`, `CI_CPUS`, `DISPATCHER_MEMORY` | `16g`, 4096, 6, `24g`, 8, `2g` | settings: the Mac's resources |
| `FORGE_CONCURRENCY`, `CLAIM_START_SECONDS`, `PR_OPENED_HOLD_SECONDS`, `MERGE_STUCK_SECONDS`, `CI_MISSING_SECONDS`, `RECONCILE_SECONDS`, `ITEM_CACHE_SECONDS`, `IDLE_SECONDS`, `OBLIGATION_BACKOFF`, `CI_LATE_SECONDS`, `CONFORMANCE_SETTLE_SECONDS`, `CONFORMANCE_ROUNDS`, `GATEKEEPER_SWEEP_SECONDS` | 8, 900, 600, 600, 600, 900, 3600, 1200, `0,900,900`, 3600, 600, 3, 900 | interface: timings and limits that aren't bounds; Inkproof proposes configuration for those the states and proofs depend on (`OBLIGATION_BACKOFF`, `CONFORMANCE_ROUNDS`, `CI_LATE_SECONDS`) and settings for the rest |
| `BACKUP_DIR`, `BACKUP_KEEP`, `RESTORE_TEST_PORT` | `./backups`, 7, 3002 | settings |
| The guild's new bounds: the re-run limit, the run budget, `patience` | none | configuration: the re-run limit at the guild's default of one, the others from the production ledger's history |

## `docker/proxy/`

| File | Content | Destination |
|---|---|---|
| `allow-agents.txt` | Claude Code, VS Code | kit |
| | GitHub by exact host, its content hosts, `.lean-lang.org` | Lean; `demos` relies on `github.com` to clone uPlot, and Loogle and Reservoir are under `.lean-lang.org` |
| | `registry.npmjs.org` | Lasm |
| `allow-ci.txt` | As above, without Claude Code and VS Code | Lean, Lasm |
| `allow-forge.txt`, `squid-forge.conf` | `github.com`, for mirror pushes; `api.github.com` only during an import | kit |
| `squid.conf` | The proxy | kit |

Inkproof's allowlist additions are none, as long as the Lean layer allows `github.com`.

## `templates/`

| File | Inkproof's content | Destination |
|---|---|---|
| `library/` (all) | The namespace root `Inkproof` (`Inkproof.{{NAME}}`, `lib = Inkproof<Name>`), "Part of Inkproof" and its licence in `README.md`, the `leanOptions` | interface: the Lean layer's template, with the namespace root, `README.md`'s line and the options from configuration |
| `library/`, via `new-library.sh` | Shared files and the copyright header copied from `inkproof-core` (`SEED_FROM`) | configuration: the library to seed from |
| `repo/.forgejo/workflows/checks.yml` | `inkproof-ci:1`, the `inkproof-elan` volume, `insteadOf` rules for `inkproof-`, `INKPROOF_REQUIRE_LASM` | interface: every repository's copy is code-owned by the human, and `inkproof-tools`' test driver reads `INKPROOF_REQUIRE_LASM` |
| `repo/.forgejo/workflows/checks.yml` | Everything else | Lean, and Lasm for its browser and site steps |
| `repo/scripts/check-pins.sh` | Internal dependencies are those under `github.com/<owner>/inkproof-` | Lean, with the explicit list of repositories |
| `repo/scripts/api-lock.sh.example` | None | Lean |
| `repo/.forgejo/issue_template/request.md` | None | kit |
| `site/.github/workflows/pages.yml` | None | Lasm |

## `launchd/`

| File | Content | Destination |
|---|---|---|
| `backup.plist` | The daily backup, with a notification titled "Inkproof forge" on failure | kit, the guild's backup job; the title from the project's name |
| `notify.plist` | Notices each minute | gone: the web UI replaces it |

## Labels, and the dispatcher's rules

| Where | Inkproof's content | Destination |
|---|---|---|
| `setup-repo.sh` 30-41 | The labels on every repository | kit |
| `setup-repo.sh` 42-53 | `upstream:lasm`; `review:architecture`, `review:process`, `review:lasm` | configuration: derived from the upstream project and its tracking agent, and from the milestone reviewers and the supervisor (seam 4) |
| `setup-repo.sh` 25, 101, 166 | `conformance` on every approvals list and a code owner of every path (`CONFORMANCE_REVIEW`) | configuration: the pull request reviewer is required |
| `dispatcher.py` 76, `agent-clone-all` 12 | `REPO_PREFIX` defaulting to `inkproof-` | gone: the explicit list of repositories |
| `dispatcher.py` 108 | `REVIEWER = "conformance"` | configuration: the agent of kind `pr-reviewer` |
| `dispatcher.py` 109 | `MILESTONE_REVIEWERS = ("architecture", "process", "lasm")` | configuration: agents of kind `milestone-reviewer` or `supervisor` |
| `dispatcher.py` 831 | A milestone reviewer's report on an issue labelled `milestone-review` or `upstream:lasm` | configuration: `upstream:<project>` for each upstream project |
| `dispatcher.py` 949-956, rule 16 | No coordinator run for `needs-human` on `review:process` or `review:lasm` recommendations | configuration: those reviewers' recommendations are the human's |
| `dispatcher.py` 961-964, rule 22 | `lasm` is woken for a blocking `upstream:lasm` issue | configuration: Lasm is an upstream project tracked by `lasm` |
| `dispatcher.py` 3095 | Only `process` or the supervisor reads the ledger | kit: the supervisor |

## Names

Seam 1. Some of these are only names, which the guild renames freely; others are held in data that outlives the switch, or in files every repository has.

| Name | Where | Destination |
|---|---|---|
| `inkproof-forge` | The compose project, and so every volume, `inkproof-forge_work-<agent>` and `inkproof-forge_claude-<agent>` included | settings: the compose project name ([REQUIREMENTS.md](REQUIREMENTS.md#the-switch)) |
| `inkproof-ci:1`, `inkproof-elan` | CI's image and runner label, and its toolchain volume, named in every repository's `checks.yml` | interface |
| `INKPROOF_REQUIRE_LASM` | Set by `checks.yml`, read by `inkproof-tools` | interface |
| `.inkproof/` | Every agent's workspace volume: `runs/`, `current.md`, `sessions.jsonl` not yet in the ledger | interface |
| `INKPROOF_RUN`, `inkproof-hook`, `inkproof-render`, `/usr/local/share/inkproof`, `/var/lib/inkproof`, `/etc/inkproof` | Inside images and containers | kit |
| `inkproof-restore-test` | The reference's restore test | kit |

## `DESIGN.md` and `RUNBOOK.md`

Both become the guild's (seam 11). What is Inkproof's goes into the project document, as text.

| Where | Inkproof's content | Destination |
|---|---|---|
| `DESIGN.md` 41, 54-55 | The reviewers' accounts and permissions | kit, derived from configuration |
| `DESIGN.md` 48 | `inkproof-tentenths`, the GitHub account agents shared before the kit, is never used or recreated | text |
| `DESIGN.md` 439-467 | Milestone reviews: architecture, process and Lasm | text for each review's questions; the rest is the kit's |
| `DESIGN.md` 469-477, 586 | Dependencies we don't control: Lasm outside Forgejo, its bindings, npm, Chromium | Lasm, with Inkproof's choice of Lasm as text |
| `DESIGN.md` 505-516 | GitHub mirror, with `inkproof-` in its rules | kit |
| `DESIGN.md` 518-529 | Sites: `inkproof-demos` | Lasm; that `demos` is a site is configuration |
| `RUNBOOK.md` 29-43 | Bringing the repositories over from GitHub | gone: Inkproof is already in Forgejo |
| `RUNBOOK.md` 73 | `inkproof-coordination` stays at level 1, with no CI | interface, with autonomy levels |
| `RUNBOOK.md` 102-115 | Adding a site | Lasm |
| `RUNBOOK.md` 117-126 | Retiring an agent, as with `inkproof-demo` | kit; `inkproof-demo` is in [Production state](#production-state) |
| `RUNBOOK.md` 257-271, 344-346 | Bounds; upgrading Playwright | kit; Lasm |

## Production state

What the reference's files can't show, but the switch must keep.

| What | Where it is | Destination |
|---|---|---|
| Each repository's autonomy level | Its `CODEOWNERS` on `main`, written by `setup-repo.sh` | interface: configuration lists levels, while the reference and the coordinator's role read them from the forge |
| `inkproof-demo`, a retired agent's archived repository and disabled account | Forgejo | interface: a repository in the organisation but not in configuration |
| History attributed to `Ghost`, from the import | Forgejo | kit: PROTOCOL.md line 10 |
| The run budget's and `patience`'s starting values | The production ledger, which the human exports | configuration |

## What the interface must express

Each item marked "interface" above, as a need any project switching from the reference could have:

1. **Kinds' role text.** The coordinator, `pr-reviewer`, milestone reviewers, supervisor and `site` kinds carry behaviour the dispatcher relies on. The guild or a layer supplies it, and a project's role adds only its own.
2. **Placeholders** for the coordination repository, the project's repositories as a whole, and the project's name, beside `{{AGENT}}`, `{{REPO}}`, `{{ORG}}`, `{{HUMAN}}`, `{{GH_OWNER}}` and `{{FORGE_WEB_URL}}`.
3. **Names in repositories' code-owned files**: CI's image and runner label, its toolchain volume, and the variable telling tests that Lasm is required. Every repository's `checks.yml` names them, and only the human can change it.
4. **The agents' workspace state directory**, `.inkproof/`, on volumes the switch keeps.
5. **Autonomy levels**: compiled configuration, or the forge's state as in the reference. The coordination repository, with no CI, stays at level 1.
6. **The forge organisation**: configuration or a setting.
7. **The library template**: the namespace root, `README.md`'s line, Lake options and the library to seed from.
8. **Timings and limits that aren't bounds**: which are configuration and which settings.
9. **Repositories in the organisation but not in configuration**, such as an archived one.
