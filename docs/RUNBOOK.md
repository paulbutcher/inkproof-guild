# Runbook

How the human runs Inkproof's kit on the guild, on the Mac. The guild's [docs/DEPLOYING.md](https://github.com/paulbutcher/lean-guild/blob/main/docs/DEPLOYING.md) says what each script and setting does; this says what Inkproof does with them.

## The kit and its settings

- Production runs from a checkout of its own on the Mac, apart from the one shared with the dev container, so that a build or a guild release being rehearsed there never reaches it. Keep it at the commit last rehearsed; to take a new one, pull it, `lake build`, then `scripts/up.sh`.
- Build Inkproof's kit executable in the checkout: `lake build`.
- Copy [deploy/settings.env.example](../deploy/settings.env.example) to `settings.env` at the checkout's root, which git ignores, as it does `state/`, and set your email and, for a deployment of its own, `STATE_DIR`. Keep its names: they are the reference's, which production's volumes and repositories hold.
- Each of the guild's scripts has one of the same name in [scripts/](../scripts/), which runs it with the executable and `settings.env`: `scripts/up.sh`, for example. The steps below run them from the checkout's root.
- Inkproof adds nothing to the proxies' allowlists and overrides nothing in the guild's compose files.

## First-time setup

For a new deployment, against an empty Forgejo. Production is set up already; the switch moves it onto the guild instead.

1. `scripts/up.sh` builds the images and starts Forgejo, CI, the dispatcher, the gatekeeper and the web UI.
2. `scripts/bootstrap.sh` asks for your Forgejo password, then creates the organisation, every repository, empty, and every account. With mirrors on, it needs `secrets/github/mirror-token` first.
3. Put a token from `claude setup-token` in `$STATE_DIR/secrets/claude/oauth-token`, and run `scripts/up.sh` again: it starts every agent, stopped, since none has run before.
4. `scripts/setup-repo.sh` once each repository has its first commit, then `scripts/backup-install.sh`. Start agents in the web UI when you are ready.

`scripts/stage3.sh` in this repository rehearses steps 1 to 3 in the dev container's own Docker engine, with mirrors off and a stand-in Claude token, and checks the result; it refuses any other engine.

## Rehearsal

`scripts/rehearse.sh backups/<time>` restores a production backup into the dev container's own engine, isolated from GitHub, compares the reference's view of it with the guild's, and rehearses the switch and the way back on it; its outputs are in `.lake/rehearsal/out`. Run it again before the Mac takes a new guild release.

## The switch

Beforehand, on the Mac: clone the production checkout at the commit last rehearsed, build the kit there, and write its settings as above, keeping `STATE_DIR=state`, with `HUMAN_EMAIL` as in the reference's `.env`, any resource or timing that `.env` sets, and mirrors on. Then, in the reference's checkout:

1. `scripts/status.sh > ~/switch-before.txt`, then `scripts/drain.sh`, and wait for "safe to stop".
2. `scripts/backup.sh`, `scripts/notify-install.sh --remove`, `scripts/backup-install.sh --remove`, then `scripts/down.sh`.

In the production checkout:

3. Copy the reference's state, which is four folders of its checkout, keeping permissions: `mkdir state && cp -Rp <reference>/{secrets,control,backups,proxy} state/`.
   Then give the ledger to your user, `HOST_UID:HOST_GID`, since the reference's dispatcher ran as uid 1000: `docker run --rm -v inkproof-forge_dispatcher-state:/state alpine:3.24 chown -R 501:20 /state`.
4. `scripts/up.sh`. It builds the guild's images and starts on the reference's volumes and the copied `secrets/`, still draining, from the copied `control/draining`.
5. `scripts/bootstrap.sh`. It leaves tokens and mirrors as they are. It sets the `DEPS_REPOSITORIES` and `MACOS_RUNNER` Actions variables, which only the guild's CI templates read, and makes what the reference's own bootstrap would have: production lacks the gatekeeper's webhook and most repositories' `not-verified` label.
6. In the web UI, `http://localhost:3002/`, check that the kit is draining and that what waits on you and what each agent owes match `~/switch-before.txt`.
7. Resume in the web UI, then run `scripts/backup-install.sh`.

The switch runs no `scripts/setup-repo.sh`. With no arguments it applies the configuration's starting levels, which are production's only until you change one, so give it a repository and the level it is already at, or one you are moving it to.

## The way back

To go back to a backup the guild made, restore it with `scripts/restore.sh BACKUP` in the production checkout first; the reference can't read one. Then:

1. Drain in the web UI, and wait until it says it is safe to stop.
2. `scripts/switch-back.sh`. Edit the `Blocked-by:` lines it lists out of their items, and run it again until it lists nothing.
3. `scripts/backup-install.sh --remove`, then `scripts/down.sh`.
4. In the reference's checkout, set `STATE_DIR` in `.env` to the production checkout's `state/`, as an absolute path. Give the ledger back to the reference's dispatcher, `docker run --rm -v inkproof-forge_dispatcher-state:/state alpine:3.24 chown -R 1000:1000 /state`, then `scripts/up.sh`. It starts draining, from the guild's drain in `control/`; check `scripts/status.sh`.
5. `scripts/resume.sh`, `scripts/backup-install.sh` and `scripts/notify-install.sh`.

`scripts/rehearse.sh` rehearses both, all but the launchd jobs, which only the Mac has.
