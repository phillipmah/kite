# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product Vision

Kite is a **family AI intelligence layer** — a trusted AI companion for children (ages 5–13) and a parenting co-pilot for parents. It sits between children and the AI tools they use, guiding how they learn and giving parents actionable weekly insights into their child's curiosity and struggles.

**Core principles:**
- This is not a parental control / surveillance product — it's a family intelligence layer
- Homework interception: never give the answer, never refuse — always reconstruct as a Socratic teaching moment
- Weekly Curiosity Report is the hero feature: what the child wondered about, academic struggles, conversation starters for sensitive topics
- Filters that grow with the child — AI proactively recommends relaxing restrictions as children mature
- Built to European privacy standards (Switzerland-based, GDPR + EU AI Act compliant, no data resale, no training on children's conversations)

**Target:** Families with children aged 5–13. Teen product (13–18) is post-MVP.
**Tagline:** *"Let them fly. Stay connected."*

## Commands

```bash
mix setup              # install deps, create/migrate DB, build assets
mix phx.server         # start dev server at localhost:4000
iex -S mix phx.server  # start with interactive shell

mix test               # run all tests (auto-creates/migrates test DB)
mix test test/path/to/file_test.exs          # run single test file
mix test test/path/to/file_test.exs:42       # run test at line 42
mix test --failed      # re-run previously failing tests

mix precommit          # compile (warnings-as-errors), check unused deps, format, test — run before finishing

mix ecto.gen.migration migration_name   # generate a migration
mix ecto.migrate                        # run migrations
mix ecto.reset                          # drop, recreate, migrate, seed
```

**Deploy to Fly.io:**
```bash
~/.fly/bin/flyctl deploy
~/.fly/bin/flyctl logs                                              # tail production logs
~/.fly/bin/flyctl postgres connect -a phoenix-starter-wild-dew-1011-db  # connect to prod DB
```

## Architecture

Phoenix 1.8 app with LiveView. Single-page app currently serving a waitlist landing page.

- **`lib/kite/`** — business logic (contexts, schemas)
  - `Kite.Waitlist` — context for waitlist operations (`join_waitlist/1`, `change_entry/2`)
  - `Kite.Waitlist.Entry` — Ecto schema for `waitlist_entries` table
  - `Kite.Repo` — Ecto repo (PostgreSQL)
  - `Kite.Release` — production migration runner (`/app/bin/migrate` release command)

- **`lib/kite_web/`** — web layer
  - `router.ex` — single route: `live "/", HomeLive`
  - `live/home_live.ex` — waitlist signup LiveView with `validate`/`submit` events
  - `components/core_components.ex` — shared UI components (`<.input>`, `<.icon>`, etc.)
  - `components/layouts.ex` — root and app layout wrappers

- **`assets/`** — frontend
  - `css/app.css` — Tailwind v4 with daisyUI; uses `@import "tailwindcss" source(none)` syntax
  - `js/app.js` — Phoenix LiveView socket setup; no `phoenix-colocated` package (removed)

- **`priv/repo/migrations/`** — Ecto migrations

- **`rel/overlays/bin/`** — release scripts (`server`, `migrate`) used inside the Docker container

## Deployment

| | |
|---|---|
| **Live app** | https://phoenix-starter-wild-dew-1011.fly.dev/ |
| **GitHub** | https://github.com/phillipmah/kite |
| **VS Code tunnel** | https://vscode.dev/tunnel/kite/home/sprite/projects/kite |

Fly.io app: `phoenix-starter-wild-dew-1011` (sjc region)
Postgres: `phoenix-starter-wild-dew-1011-db` (must be running before deploy — restart with `flyctl machine restart <id> --app phoenix-starter-wild-dew-1011-db` if it's in an error state)

The `fly.toml` `release_command` runs `/app/bin/migrate` (calls `Kite.Release.migrate`) before each deploy.

## Development Workflow

Kite is built spec-first, AI-native. Before writing any code, check the vault.

### Vault structure
```
~/vault/01 Projects/kite/
├── Project Kite.md          # Product vision + technical reference + settled decisions
├── Roadmap.md               # Milestones, epics, status, decisions log, agent instructions
├── Marketing/
│   ├── Customer Discovery.md      # Lean Startup hypothesis stack + interview guide
│   └── Child Safety Benchmark.md  # Family AI Safety Index spec
└── Product/
    └── Kite Landing Page.md       # Landing page spec + issue tracker
```

New feature specs → `Product/`. Marketing initiatives → `Marketing/`. One file per feature.

### Flow for every piece of work
1. Check `Roadmap.md` — find the current milestone, pick an epic with no unmet dependencies
2. Read the linked vault spec fully before writing any code. No spec = don't build, flag it.
3. Check `Project Kite.md` for settled product decisions — do not re-litigate them
4. Build only what the spec describes. Add bugs found to the spec's **Issues** section.
5. New product decisions go in the Decisions Log in `Roadmap.md`

### Customer discovery gate
Do not start M2+ product features until Customer Discovery Phase 1 exit criteria are met (3 of 4 hypothesis groups validated). See `Marketing/Customer Discovery.md`. The Family AI Safety Index is the primary discovery mechanism — it generates inbound interviews without cold outreach.

## Key Guidelines

See `AGENTS.md` for the full set of coding guidelines. Critical ones:

- Run `mix precommit` when done with all changes
- LiveView templates must begin with `<Layouts.app flash={@flash} ...>`
- Use `<.input>` for form inputs, `<.form for={@form}>` (not `@changeset`) in templates
- Use `{...}` for attribute interpolation, `<%= ... %>` for block constructs in tag bodies
- Tailwind v4: no `tailwind.config.js`, use `@source` directives in `app.css`; never use `@apply`
- Use `mix ecto.gen.migration` to generate migration files (never create manually)
- Colocated JS hooks (`:type={Phoenix.LiveView.ColocatedHook}`) require names starting with `.`
