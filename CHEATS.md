# NeoVim `H`
Numeber of times a particular action was refered back here is added as a counter.
- References:
    - Youtube:
        1. [Vim Motions for absolute beginners!!!](https://www.youtube.com/watch?v=lWTzqPfy1gE&ab_channel=Dispatch)
        2. [Intermediate Vim Motions and Pro Tips!!!](https://www.youtube.com/watch?v=nBjEzQlJLHE&t=15s&ab_channel=Dispatch)
    - Wiki:
        1. [vim Help](https://vimhelp.org/pattern.txt.html)

## Other marks
- Help: `'H`
- Remaps: `'R`
- Configurations: `'C`
- LSP: `'L`
1 A crazy set on instruction:
```vim
:redir! > vim_keys.txt
:silent verbose map
:redir END
```

## General
1 To Know all mappings `:map` / `:{mode}map`
1 To Know all registers `:reg`
1 To Know all marks `:marks`
1 To format file `<> gq`
3 Copy filename to register 
    - mac `let @*=expand("%")`
    - linux `let @+=expand("%")`
1 Know value of field `:=field.value`

- Sort:
1 Normal: `:sort`
2 Unique: `:sort u`
0 Reverse: `:sort!`
1 Revers lines: 
> 1. mark 1 line above as `mt`
> 2. go to the line untli which lines have to be reversed
> 3. Execute: `:'t+1,.g/^/m 't`

- Read file:
0 Normal `:read path/to/the/file`

- Execute command:
0 Normal: `:!shel_comand`
1 Fetch value from json: `:<,'> !jq ...command`
0 Command: `:<C-f>` command history
1 Delete current file `:call delete(expand('%')) | bdelete!`

- Regsitars:
2 Check `:reg`                                                              
2 Paste from a registar `v "<registar name>y`
2 Copy to a registar `n "<registar name>p`
0 Save a command to a register `:redir @* | command | redir END` (*/+ is clipboard default register)

## Search
2 Remove pattern `:g/pattern/d`
2 Remove everything but the pattern `:v/pattern/d`
1 Clear highlight `<leader>gq`

### Telescopic search
2 Live Grep `<leader>fg`
2 Search Buffers `<leader>fb`
2 Search help tags `<leader>fh`
2 Search find in files `<leader>ff`
1 Search a term `<c-f>`
1 Search git files `<C-o>`
1 Open in search functions `<C-h>`
2 Add all to quick fix list `<C-q>` (While in telescope page)
1 Open file in new tab `<C-t>`

## Quick fix
- `<C-j/k>` move through quick fix list
- `:cdo s/<a>/<b>` Do for all items in quick fix

## Folding
- All code blocks:
0 Fold: `n zM`
0 Open: `n zR`
- Individual:
0 Fold: `n zc`
0 Open: `n zo`
- Within Braces
0 Fold `n zfa<bracket>`

## Indentation
- Auto
0 single line: `n ==`
0 selected: `v =`
1 Change indentation: `v </>`

## Marking
1 Mark: `n m<alphabet>`
    - small for local marks, Capital for global marks)
1 go to Mark line: `n '<alphabet>`
1 go to exact Mark: `n `<alphabet>`

## Actions
### Simple
0 Record: `n q<alphabet>`
0 Replay recording: `n @<alphabet>`
0 Repeat last action: `n .`
4 Increase/Decrease a number: `n <C-a/>`
1 Find regex of a line `n<leader>r`
1 Surroud Quotation `ciw{'/"}<C-r>"{'/"}`

- Upper/Lowercase:
0 Single charecter: `n ~`
0 Word: `n gU/uw`
0 Entire line: `g UU/uu`

### Complicated
1 [Multifile regex](https://stackoverflow.com/questions/49568322/how-to-apply-gvim-regular-expressions-to-multiple-files)
```vim
:argdo v/\(public \(class\|.*(\)\|@Path(\|@ApiOperation\|@RolesAllowed\)/d | %s/\(@Path(\|@RolesAllowed\|value =\|public \|Response \|{\|}\|(\|)\|@ApiOperation\|class \| \{2,\}\)//g | w
```
```vim
:bufdo execute "normal @a" | write
```
1 Write a-z
`:r !printf '\%s' {a..z}`

## Screen Play

- Opening Split screen
2 Open folder `<leader>vs`
2 Open folder containg this file `<leader>vl`
1 Open terminal vertical `<leader>tv`
1 Open terminal below `<leader>tb`
3 Check buffer `:ls`
3 Reopen Split `:vs#<n>` (n-number of the buffer)
3 Diff b/w buffer `:windo diffthis`

- Moving b/w splits
1 Normal/Terminal `v<h/j/k/l>`

- Tabs
2 Move b/w tabs `<C-j/k>`

## LSP `L`
- Actions
1 `;d` defination
1 `;i` implementation
1 `;rf` references
1 `;o` open float
1 `;ws` workspace sympbols
1 `;a` code actions
1 `;rn` rename
1 `;q` set to local list
1 `n <c-h>` hover
1 `i <c-h>` signature help
1 `[/]d` previous/next daignostics

## Git
3 `<leader>gs` Open fugitive in tab mode
1 `dt` in Git mode opens diff in tab
2 `[c` `]c` go to prev/next hunk
0 `<leader>hs`, stage_hunk
0 `<leader>hr`, reset_hunk
0 `<leader>hs`, stage_hunk
0 `<leader>hr`, reset_hunk
0 `<leader>hS`, stage_buffer
0 `<leader>hu`, undo_stage_hunk
0 `<leader>hR`, reset_buffer
0 `<leader>hp`, preview_hunk
0 `<leader>hb`, blame_line
0 `<leader>hd`, diffthis
0 `<leader>hD`, diffthis
0 `<leader>td`, toggle_deleted
0 `<leader>htb`, toggle_current_line_blame
0 (mode `o` `x`), `ih`, select_hunk

