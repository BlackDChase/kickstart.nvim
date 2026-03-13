# LSP TODOs

## Navigation & UX
- Add workspace folder management mappings (`add/list/remove`). ✅
- Add call hierarchy mappings (incoming/outgoing), where supported. ✅
- Add CodeLens mappings (`refresh`/`run`), where supported. ✅
- Decide on LSP formatting policy per server (use Conform vs `vim.lsp.buf.format`).

## Diagnostics workflow
- Add “send diagnostics to quickfix/loclist” mappings. ✅
- Add Telescope shortcuts for buffer vs workspace diagnostics. ✅

## Server tuning
- Review `pyright` settings (type checking strictness, diagnostics behavior).
- Ensure `tsserver/ts_ls` formatting is disabled if Conform is preferred. ✅
- Consider semantic tokens toggles per server if performance becomes an issue.

## Performance & logging
- Confirm LSP log level stays at `ERROR` unless overridden.
- Add a lightweight “LSP startup timing” notification for slow servers/projects. ✅
