# Runbook

How the human runs Inkproof's kit on the guild, on the Mac. The guild's [docs/DEPLOYING.md](https://github.com/paulbutcher/lean-guild/blob/main/docs/DEPLOYING.md) says what each script and setting does; this says what Inkproof does with them.

## The kit and its settings

- Build Inkproof's kit executable from a checkout of this repository: `lake build`. It is `.lake/build/bin/inkproof-guild`, and the guild's scripts are in `.lake/packages/guild/scripts/`.
- Copy [deploy/settings.env.example](../deploy/settings.env.example) outside git, and set your email and, for a deployment of its own, `STATE_DIR`. Keep its names: they are the reference's, which production's volumes and repositories hold.
- Every script takes both from the environment: `export KIT="$PWD/.lake/build/bin/inkproof-guild" KIT_ENV=<your settings file>`, then run, for example, `.lake/packages/guild/scripts/up.sh`.
- Inkproof adds nothing to the proxies' allowlists and overrides nothing in the guild's compose files.

## First-time setup

For a new deployment, against an empty Forgejo. Production is set up already; the switch moves it onto the guild instead.

1. `up.sh` builds the images and starts Forgejo, CI, the dispatcher, the gatekeeper and the web UI.
2. `bootstrap.sh` asks for your Forgejo password, then creates the organisation, every repository, empty, and every account. With mirrors on, it needs `secrets/github/mirror-token` first.
3. Put a token from `claude setup-token` in `$STATE_DIR/secrets/claude/oauth-token`, and run `up.sh` again: it starts every agent, stopped, since none has run before.
4. `setup-repo.sh` once each repository has its first commit, then `backup-install.sh`. Start agents in the web UI when you are ready.

`scripts/stage3.sh` in this repository rehearses steps 1 to 3 in the dev container's own Docker engine, with mirrors off and a stand-in Claude token, and checks the result; it refuses any other engine.

## Rehearsal

`scripts/rehearse.sh backups/<time>` restores a production backup into the dev container's own engine, isolated from GitHub, compares the reference's view of it with the guild's, and rehearses the switch and the way back on it; its outputs are in `.lake/rehearsal/out`. Run it again before the Mac takes a new guild release.
