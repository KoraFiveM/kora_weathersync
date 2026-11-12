# kora_weathersync agent guide

`kora_weathersync` is a Kora resource that keeps weather, clock, blackout and environmental effects server-authoritative, publishing one `GlobalState.kora_weathersync` snapshot that clients apply. Layout: `fxmanifest.lua`, `shared/config.lua` (all config), `server/state.lua` (state, setters, exports, events, clock loop), `server/commands.lua` (admin commands), `client/main.lua` (applies state and effects, legacy client events), `locales/en.lua`, `test/` (offline Lua tests) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first (overview and documentation map). Layout of `docs/`: `installation.md` (install, manifest, requirements, file layout), `how-to-use.md` (state flow, blending, suspend/resume sync, config summary), `commands.md` (admin commands), `api/` (`index.md`, `state.md` for server/client exports and the state snapshot, `compat.md` for the qb-weathersync exports/events), and topic pages `configuration.md`, `events.md`, `troubleshooting.md`. Update the page that owns the topic.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Feature and behaviour changes must update the matching docs in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.

## Shared contribution standards

Read [CONTRIBUTING.md](CONTRIBUTING.md) before editing. Humans and agents follow
the same Kora standards and self-contained local Lua checks. Preserve the domain
constraints above and in module guides; record policy conflicts explicitly.
