# LSP TODOs

Last updated: 2026-03-28

## Current status (done)
- Workspace folder mappings added. ✅
- Call hierarchy mappings added. ✅
- CodeLens mappings added. ✅
- Diagnostics quickfix/loclist + Telescope mappings added. ✅
- `ts_ls` formatting disabled in favor of Conform. ✅
- LSP attach timing notice for slow servers/projects. ✅
- Per-server formatting policy baseline + overrides. ✅
- `pyright` defaults (`typeCheckingMode=basic`, `diagnosticMode=openFilesOnly`). ✅
- Semantic tokens opt-out + large project gates. ✅
- Manual diagnostics refresh command + mapping. ✅
- Pause + edit-mode toggles for large refactors. ✅
- JDTLS defaults: `autobuild.enabled=false`, `importOnFirstTimeStartup=interactive`, `downloadSources=false`, `includeDecompiledSources=false`, `import.exclusions`. ✅
- JDTLS CodeLens auto-refresh made opt-in. ✅
- JDTLS JVM args toggles + project info command. ✅
- LSP health snapshot + attach counters. ✅
- Mason `automatic_enable` excludes `jdtls` so only the custom `ftplugin/java.lua` client starts. ✅

## Goals
- Avoid JDTLS workspace reloads during big edits (regex refactors, multi-file changes).
- Reduce time-to-ready for large Java workspaces.
- Make LSP performance tuning predictable and reversible.

## Plan (next iteration)
1. Instrument reload/reimport causes for JDTLS and identify top triggers.
2. Add a “hard pause” workflow for bulk edits (detach/stop + manual resume).
3. Add debounce and feature gating based on large-project detection.
4. Expand JDTLS tuning options (safe defaults + optional heavier knobs).
5. Document a recommended workflow for big changes (regex refactors).

## Detailed TODOs

### A) Measure + diagnose reloads
- Add counters for workspace reload/reimport signals:
  - Track `workspace/executeCommand`, `workspace/didChangeWatchedFiles`, and `$/progress` events by client.
  - Log last trigger + timestamp for JDTLS.
- Add a `LspPerfSnapshot` command:
  - Show current client, root, attach counts, last reload trigger, and debounce setting.
- Confirm reload trigger path in large Java repos (save vs. edit vs. periodic).
- If Java startup shows both “jdtls quit unexpectedly” and later “service ready”, run `:LspHealthSnapshot`:
  - Expected single client: `jdtls | cmd=env | ...`
  - Bad duplicate client: `jdtls | cmd=jdtls | ...`

### B) Bulk edit guardrails (regex refactors)
- Add `LspHardPause` command:
  - Stops or detaches LSP clients for current buffer (prefer JDTLS stop for Java).
  - Provide a paired `LspHardResume` to reattach/restart.
- Added `LspHardPause` and `LspHardResume` commands. ✅
- Add an explicit “bulk edit” workflow note:
  - `LspHardPause` → run regex changes → `:wa` → `LspHardResume` → `LspDiagnosticsRefresh`.
- Add a toggle to suppress document highlights and CodeLens while in edit mode.
- Document highlights + CodeLens auto-refresh already check edit mode. ✅

### C) Debounce + large-project gating
- Add global and per-server debounce control:
  - `vim.g.lsp_debounce_ms` (default)
  - `vim.g.lsp_debounce_ms_by_server` (override)
- Implemented debounce controls + large-project debounce (`vim.g.lsp_debounce_ms_large`). ✅
- Increase debounce for JDTLS when a root is classified as large.
- JDTLS uses large-project debounce automatically. ✅
- Gate the following features for large projects:
  - document highlights
  - CodeLens auto-refresh
  - semantic tokens (already gated, keep)
- Document highlights gated via `vim.g.lsp_disable_document_highlight_large` (default on). ✅
- JDTLS CodeLens auto-refresh disabled for large projects. ✅

### D) JDTLS performance tuning (verify support)
- Validate availability of these JDTLS settings and make them opt-in:
  - `java.project.importOnFirstTimeStartup = "disabled"` for manual-only import
  - `java.project.importHint` or similar prompt controls (if available)
  - Gradle import limits (if supported by current JDTLS version)
- Add “manual refresh” commands:
  - `JdtlsRefreshWorkspace` (if supported)
  - `JdtlsReimportProject` (if supported)
- Add a per-project “skip source downloads” toggle:
  - Keep global default off in huge repos but allow per-project override.

### E) Large project detection
- Expand large-project detection to include:
  - presence of `gradlew`, `mvnw`, `settings.gradle`, `pom.xml` + large module counts
  - optional manual root list (`vim.g.lsp_large_project_roots`)
- Add a hard threshold for “large” based on file count (optional, cached).

### F) Documentation + workflow notes
- Add a `:LspPerfHelp` command that prints:
  - current performance toggles
  - recommended workflow for bulk edits
  - how to override per-project settings

## Performance ideas to consider
- Increase `flags.debounce_text_changes` for JDTLS (e.g. 300–600ms in large repos).
- Provide a “diagnostics-on-save-only” mode for JDTLS in huge workspaces.
- Avoid automatic CodeLens refresh in large projects (already opt-in, keep).
- Prefer manual workspace refresh over automatic reimport in large repos.
- Consider lowering `-Xmx` on memory-constrained machines or raising it on large monorepos (per-project toggles).
- Keep `java.maven.downloadSources=false` for big repos; enable only when actively reading library code.
