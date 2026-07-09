# CLAUDE.md

Dev notes for `relaton-data-sdo` — the SDO organization & logo data store.

## What this is

The **data** companion to the `Relaton::Sdo` client in the `relaton` gem
(`lib/relaton/sdo/`, entry point `Relaton.organization`). It holds, per
standards-development organization, its names/translations and logo variants,
and publishes them as one `index.yaml` manifest. It is plain data + a small
build script — **no runtime library, no gem**.

Answers metanorma#346 (central logo store) and relaton-db#132 (abbreviation →
org name); replaces the vCard PoC `relaton/data-sdo-metadata`.

## Layout & the source/artifact split

- `orgs/<slug>/metadata.yaml` — **source**: `abbreviation` + `name` list.
- `orgs/<slug>/logos.yaml` — **source**: `logo` list, each variant with a
  relative `file:`.
- `orgs/<slug>/logos/…` — the versioned binary assets.
- `build_index.rb` — merges all `orgs/*` into `index.yaml`.
- `index.yaml` — **built artifact**. Never hand-edit; run `rake build`.

Only edit the `orgs/<slug>/` source. `index.yaml` is regenerated (locally via
`rake build`, and on `main` by the `build-index` GitHub Action, which commits it
with `[skip ci]`).

## The manifest schema (fixed by the client)

`Relaton::Sdo::Store` reads `data["organizations"]`, keyed by abbreviation
(upcased for case-insensitive lookup). Per org: a `name` list (bare string or
`{content:, language:}`; no language ⇒ default) and a `logo` list of
`{style, format, size, url, applicability}`. `style` is the primary discriminator
between variants; `applicability` is **opaque free text** the client never
parses (metanorma selects on it). Changing these key names breaks the client —
see `Organization.from_hash` / `Name.from_hash` / `Logo.from_hash` in the
relaton gem.

`build_index.rb` rewrites each source `file:` to an absolute `url:` under
`RAW_BASE` (`https://raw.githubusercontent.com/relaton/relaton-data-sdo/main`),
which matches `Relaton::Sdo::Config::DEFAULT_URL`'s host/branch so the client
resolves the index and every logo from the same place with no configuration.

## Adding/updating an org

1. Write `orgs/<slug>/metadata.yaml` (upper-case `abbreviation`, ≥1 name, exactly
   one default/unlanguaged name).
2. Write `orgs/<slug>/logos.yaml` (each logo: `style`, `format`, `file`; `size`
   and `applicability` optional). Metadata-only orgs use `logo: []`.
3. Put binaries under `orgs/<slug>/logos/`; the `file:` suffix must equal `format`.
4. `bundle exec rake` — validates source + build; `rake build` regenerates
   `index.yaml`.

## Tests

`bundle exec rake` (default = `spec`). Three specs, all repo-relative:

- `spec/schema_spec.rb` — per-org source validity + every referenced asset
  exists on disk and is non-empty.
- `spec/build_index_spec.rb` — the merge: upcased keys, `file:`→absolute `url:`
  that resolves to a real file, `applicability` passthrough.
- `spec/index_spec.rb` — the committed `index.yaml` is in sync with a fresh build
  and matches the shape the client parses.

If you change `orgs/*` or `build_index.rb`, re-run `rake build` and commit the
refreshed `index.yaml` (or let CI do it) — `index_spec` fails on drift.

## Assets provenance / gaps

Seeded logos were extracted from metanorma PDF stylesheets: base64
`Image-*-Logo` blocks in `metanorma-{iso,iec,bsi}` XSLTs and NIST's shipped PNGs
under `metanorma-nist/.../html/`. **OGC, IEEE, IHO** have no asset in that tree
and are seeded metadata-only (`logo: []`) until PDF-ready assets are sourced —
the base64 blocks live inside `<xsl:variable name="Image-…-Logo">` (sometimes
wrapped in `<xsl:text>`); match the `<xsl:variable>` element precisely, since a
bare comment mentioning the name can otherwise hijack a naive regex (as with BSI).
