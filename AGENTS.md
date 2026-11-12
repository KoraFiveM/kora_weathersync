# kora_weathersync agent guide

`kora_weathersync` is a Kora resource that keeps weather, clock, blackout and environmental effects server-authoritative, publishing one `GlobalState.kora_weathersync` snapshot that clients apply. Layout: `fxmanifest.lua`, `shared/config.lua` (all config), `server/state.lua` (state, setters, exports, events, clock loop), `server/commands.lua` (admin commands), `client/main.lua` (applies state and effects, legacy client events), `locales/en.lua`, `test/` (offline Lua tests) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first for an overview of features, configuration, commands, exports, events and compatibility.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
