# Hand-off: source PDF-ready logo assets for OGC, IEEE, IHO

**Target project:** this repo, `relaton/relaton-data-sdo`.

## Why

The initial seed of this store covers the 7 organizations named in the founding
hand-off (ISO, IEC, IEEE, IHO, NIST, OGC, BSI). Real logo assets were extracted
for **4 of them** — ISO, IEC, NIST, BSI — from the metanorma PDF stylesheets
(base64 `Image-*-Logo` blocks in `metanorma-{iso,iec,bsi}`; NIST's shipped PNGs).

The remaining **3 have no logo asset anywhere in the local metanorma tree**, so
they were seeded **metadata-only** (`orgs/<slug>/metadata.yaml` with names, and
`orgs/<slug>/logos.yaml` = `logo: []`):

- **OGC** — Open Geospatial Consortium
- **IEEE** — Institute of Electrical and Electronics Engineers
- **IHO** — International Hydrographic Organization

These are exactly the orgs whose PDF-ready logos live in **mn-native-pdf** and/or
the metanorma#346 thread, which are **not checked out** in this environment.

## What to do

For each of OGC, IEEE, IHO:

1. Obtain the PDF-ready logo asset(s) from the source of record:
   - the **mn-native-pdf** repository XSLTs (base64 `Image-*-Logo` variables), or
   - the **metanorma#346** thread attachments from @Intelligent2013, or
   - the flavor gem once `metanorma-ieee` / an OGC flavor ships an embedded logo.
2. Decode/save the binary into `orgs/<slug>/logos/<style>-<WxH>.<ext>` (follow the
   existing naming: `default-<WxH>.png`, plus any additional `style` variants the
   XSLT comments describe — e.g. `red`, `grey`, year- or doctype-specific lockups).
3. Replace the placeholder `logo: []` in `orgs/<slug>/logos.yaml` with the real
   variants:

   ```yaml
   logo:
     - style: default
       format: png
       size: <WxH>
       file: default-<WxH>.png
   ```

4. Add `applicability:` free text where a variant is doctype/stage/year-specific
   (opaque guidance — metanorma selects on it; this repo never parses it).
5. `bundle exec rake` (validates + rebuilds) and commit; the GitHub Action
   republishes `index.yaml`.

## Notes

- The extraction approach used for the seeded orgs is captured in this repo's git
  history / `CLAUDE.md` ("Assets provenance"). The base64 blocks are inside
  `<xsl:variable name="Image-…-Logo">` (sometimes wrapped in `<xsl:text>`); match
  the `<xsl:variable>` element precisely (a bare comment mentioning the name can
  otherwise hijack a naive regex, as it does for BSI).
- Prefer the **highest-resolution** source available; PDF covers need crisp logos.
- Confirm trademark/usage terms per organization before publishing.
