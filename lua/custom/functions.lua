local function defineMacro(fileType, group, key, macro, desc)
    vim.api.nvim_create_autocmd({'FileType'}, {
      pattern = fileType,
      group = group,
      callback = function()
        vim.cmd('let @' .. key .. '="' .. macro .. '"')
      end,
      desc = desc,
    })
end

-- Latex
local latex_macros = vim.api.nvim_create_augroup('latex', { clear = true })

defineMacro("tex", latex_macros, "b" , 'c\\\\textbf{}\\<ESC>P', "[B]old selected text")
defineMacro("tex", latex_macros, "s" , 'c\\\\secret{}\\<ESC>P', "[S]ecretize selected text")
defineMacro("tex", latex_macros, "i" , 'c\\\\textit{}\\<ESC>P', "[I]talic selected text")

function ExtractJavaResourceFile()
    vim.cmd [[
        %s/"\(.*\)"\n\s*+\s*"\(.*\)"/"\1\2"/
        %s/"\(.*\)"\n\s*+\s*"\(.*\)"/"\1\2"/
        v/\(public class\|public response\|@path(\|@apioperation(\|^\s*value\s*=\s*"\w*\)/d
        %s/\"\(.*\)"/\r"\1"\r
        %s/ *public class \(\w*\).*/*\1*\r----
        %s/ *public \w* \(\w*\).*/**\1**\r----
        %s/@.*\| *)\| *,/
        %s/[value =]*\s*//
        %s/"\/\([a-zA-Z0-9_/]*\)"/`\/\1`
        %s/[ ]{2,}\|\s$\|\s^//g
        %s/\n\+/\r/g
        %s/\n\+/\r/g
        " %s/\%(\(`.*`\)\=\n\=\(".*"\)\=\n\=\(\*.*\*\)\)/{"type":"text":"\3\\n\1\\n\2"},
        " %s/\(\\n\|"\)"/\1/g
    ]]
end

function ExtractAllJavaResourceFile()
    vim.cmd [[ silent! argdo lua ExtractJavaResourceFile {} ]]
end


-- FIX ME: Does not work
-- TODO: Optimize
-- --- Opens a side-by-side diff for every changed file between two Git references.
-- --- Uses Fugitive's Gedit/Gdiffsplit commands for optimal path handling.
-- --- @param ref_a string The first Git reference.
-- --- @param ref_b string The second Git reference.
-- function GitBranchDiff(ref_a, ref_b)
--     -- ... function body remains the same
--     -- Use --name-only to get the list of files. We'll rely on Fugitive to handle missing paths.
--     local diff_command = string.format("git diff --name-only %s %s", ref_a, ref_b)
--
--     local output = vim.fn.system(diff_command)
--     local files = vim.split(output, "\n", { plain = true, trimempty = true })
--
--     if #files == 0 then
--         vim.notify(
--             string.format("No differing files found between %s and %s.", ref_a, ref_b),
--             vim.log.levels.INFO,
--             { title = "Git Diff" }
--         )
--         return
--     end
--
--     vim.notify(
--         string.format("Opening %d diff tabs between %s and %s...", #files, ref_a, ref_b),
--         vim.log.levels.INFO,
--         { title = "Git Diff" }
--     )
--
--     -- 1. Store the current buffer number to return after the diffing
--     local current_bufnr = vim.api.nvim_get_current_buf()
--
--     -- 2. Iterate over the files and open diff tabs.
--     for i, file in ipairs(files) do
--         if file == "" then goto continue end
--
--         -- Open a new tab for each file pair.
--         vim.cmd("tabnew")
--
--         -- A. Open the version of the file from ref_a.
--         -- :Gedit is Fugitive's way to open a file from a reference.
--         vim.cmd(string.format("Gedit %s:%s", ref_a, file))
--
--         -- B. Use Fugitive to split and diff against ref_b.
--         -- Fugitive handles the creation of a blank buffer automatically
--         -- if the file does not exist in the current working copy or the given reference.
--         vim.cmd(string.format("Gdiffsplit %s", ref_b))
--
--         -- C. Set the buffer names clearly for context
--         -- Left: :Gedit places us in the first buffer.
--         vim.cmd(string.format("file %s:%s", ref_a, file))
--         -- Right: Gdiffsplit moves us to the next buffer.
--         vim.cmd(string.format("bnext | file %s:%s", ref_b, file))
--
--         ::continue::
--     end
--
--     -- 3. Return to the original tab and buffer (optional but good UX)
--     vim.cmd(string.format("tabfirst | buffer %d", current_bufnr))
-- end
--
--
-- -- Define the completion function
-- local function git_branch_complete(ArgLead, CmdLine, CursorPos)
--     -- Execute git command to get local and remote branches
--     -- --format='%(refname:short)' is concise for branch names
--     local branches = vim.fn.systemlist("git for-each-ref --format='%(refname:short)' refs/heads refs/remotes")
--
--     local completions = {}
--
--     -- Filter branches based on the user's current input (ArgLead)
--     for _, branch in ipairs(branches) do
--         -- Trim any potential whitespace/quotes and check if the branch starts with the input
--         local clean_branch = branch:gsub("^%s*(.-)%s*$", "%1")
--         if clean_branch:find(ArgLead, 1, true) == 1 then
--             table.insert(completions, clean_branch)
--         end
--     end
--
--     -- Add common references like HEAD, MERGE_HEAD, etc.
--     local common_refs = { "HEAD", "MERGE_HEAD", "ORIG_HEAD", "FETCH_HEAD", "@" }
--     for _, ref in ipairs(common_refs) do
--         if ref:find(ArgLead, 1, true) == 1 then
--             table.insert(completions, ref)
--         end
--     end
--
--     -- Return the list of matches
--     return completions
-- end
--
--
-- -- Create the user command using the new completion function
-- vim.api.nvim_create_user_command(
--     'GdiffTabs',
--     function(opts)
--         -- Split args by whitespace
--         local args = opts.fargs
--         vim.print(vim.inspect(args))
--         vim.print(#args)
--
--         if #args < 2 then
--             vim.notify("Usage: :GdiffTabs <ref_a> <ref_b>", vim.log.levels.ERROR)
--             return
--         end
--
--         GitBranchDiff(args[1], args[2])
--     end,
--     -- CRITICAL FIX: Reference the Lua function instead of a string
--     { nargs = '*', complete = git_branch_complete, desc = 'Open side-by-side diff for all changed files between two git refs in separate tabs.' }
-- )
