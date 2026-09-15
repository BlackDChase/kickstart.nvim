local M = {}

function M.get(overrides)
  local completion_capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = false,
          documentationFormat = { 'markdown', 'plaintext' },
          deprecatedSupport = true,
          preselectSupport = false,
          tagSupport = { valueSet = { 1 } },
          insertReplaceSupport = true,
          resolveSupport = {
            properties = { 'documentation', 'detail', 'additionalTextEdits', 'command', 'data' },
          },
          insertTextModeSupport = { valueSet = { 1 } },
          labelDetailsSupport = true,
        },
        completionList = {
          itemDefaults = { 'commitCharacters', 'editRange', 'insertTextFormat', 'insertTextMode', 'data' },
        },
        contextSupport = true,
        insertTextMode = 1,
      },
    },
  }

  return vim.tbl_deep_extend('force', completion_capabilities, overrides or {})
end

return M
