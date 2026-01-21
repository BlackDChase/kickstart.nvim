# kickstart.nvim

## Introduction

A starting point for Neovim that is:

* Small
* Single-file
* Completely Documented

**NOT** a Neovim distribution, but instead a starting point for your configuration.

## Keybindings

Leader: `<Space>` (`vim.g.mapleader`), LocalLeader: `\` (`vim.g.maplocalleader`).

This config also has `which-key.nvim` enabled, so many mappings are discoverable by pausing after `<leader>` / `<localleader>`.

### General

| Shortcut | Mode | Action |
| --- | --- | --- |
| `S` | n/v | Save (`:update`) |
| `\|` | n/v | Quit (`:q`) |
| `Q` | n | Disabled |
| `<Esc>` | n | Clear search highlight (`:noh`) |
| `<leader>p` | n/v/x | Paste without yanking (blackhole) |
| `<leader>y`, `<leader>Y` | n/v | Yank to system clipboard |
| `<leader>e` | n | Diagnostic float |
| `<leader>q` | n | Diagnostics to loclist |
| `<leader>x` | n | `chmod +x %` |
| `<leader>pdf` | n | `pdflatex %` |
| `<leader>json` | n | Format buffer via `jq` |

### Movement / View

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<C-u>`, `<C-d>` | n | Page up/down, keep cursor centered |
| `n`, `N` | n | Next/prev search result, keep cursor centered |

### Buffers / Tabs

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<A-[>`, `<A-]>` | n | Next/prev buffer |
| `<A-BS>` | n | Delete buffer |
| `<leader>tn` | n | New tab |
| `<Tab>`, `<S-Tab>` | n | Next/prev tab |
| `<leader><Tab>`, `<leader><S-Tab>` | n | Next/prev loclist entry |

### Windows / Terminal

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | n | Move focus between splits |
| `zH`, `zJ`, `zK`, `zL` | n/t | Move current window (wincmd H/J/K/L) |
| `<A-h>`, `<A-j>`, `<A-k>`, `<A-l>` | n/t | Resize splits |
| `<Esc><Esc>` | t | Exit terminal-mode |
| `<leader>ct` | n | Open small terminal below (channel) |
| `<leader>cs` | n | Send command to that terminal |

### Treesitter

| Shortcut | Mode | Action |
| --- | --- | --- |
| `gnn` | n | Start incremental selection |
| `grn`, `grm`, `grc` | n | Expand / shrink / scope selection |
| `[f`, `]f` | n | Prev/next function start |
| `[F`, `]F` | n | Prev/next function end |
| `[a`, `]a` | n | Swap parameter with prev/next |

### Telescope

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<leader>sh` | n | Help tags |
| `<leader>sk` | n | Keymaps |
| `<leader>sf` | n | Find files |
| `<leader>sg` | n | Live grep |
| `<leader>sw` | n | Grep string under cursor |
| `<leader>sd` | n | Diagnostics picker |
| `<leader>sr` | n | Resume last picker |
| `<leader>s.` | n | Recent files |
| `<leader><leader>` | n | Buffers |
| `<leader>sn` | n | Search Neovim config files |
| `<leader>/` | n | Fuzzy find in current buffer |
| `<leader>s/` | n | Live grep in open files |
| `<C-f>` | n | Prompted grep string |
| `<C-o>` | n | Git files |
| `<leader>sp`, `<leader>sP` | n | Projects (minimal/full) |
| `<leader>spa` | n | Add current cwd as project |
| `<leader>spg` | n | Add project from current buffer location |
| `<leader>gdb` | n | Diff current file vs branch (pick branch) |
| `<leader>gsm` | n | Git submodules picker |
| `<leader>gco` | n | Git branches picker |

### LSP (buffer-local on attach)

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<localleader>n` | n | Rename |
| `<localleader>a` | n/x | Code action |
| `<localleader>h` | n | Hover |
| `<localleader>s` | i | Signature help |
| `<localleader>r` | n | References (Telescope) |
| `<localleader>i` | n | Implementations (Telescope) |
| `<localleader>d` | n | Definitions (Telescope) |
| `<localleader>e` | n | Declaration |
| `<localleader>o` | n | Document symbols (Telescope) |
| `<localleader>w` | n | Workspace symbols (Telescope) |
| `<localleader>t` | n | Type definition (Telescope) |
| `<localleader>[`, `<localleader>]` | n | Prev/next diagnostic + code action |
| `<leader>th` | n | Toggle inlay hints (if supported) |

### Git

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<leader>gs` | n | Fugitive status (tab) |
| `<leader>gc` | n | Fugitive commit |
| `<leader>gb` | n | Fugitive blame |
| `<leader>g1`, `<leader>g2`, `<leader>g3` | n | `diffget` LO/BA/RE |
| `<leader>gh`, `<leader>gl` | n | `diffget` //2 and //3 |
| `dt` | n | FugitiveIndex: open diff in tab |
| `[c`, `]c` | n | Prev/next hunk |
| `<leader>hs`, `<leader>hr` | n/v | Stage/reset hunk |
| `<leader>hbs`, `<leader>hbr` | n | Stage/reset buffer |
| `<leader>hu` | n | Undo stage hunk |
| `<leader>hp` | n | Preview hunk |
| `<leader>hb`, `<leader>hfb` | n | Blame line (normal/full) |
| `<leader>hd`, `<leader>hdc` | n | Diff (index / last commit) |
| `<leader>htb`, `<leader>htD` | n | Toggle blame / preview deleted |
| `hs` | o/x | Select hunk textobject |

### Debug (DAP)

| Shortcut | Mode | Action |
| --- | --- | --- |
| `<F5>` | n | Continue |
| `<F1>`, `<F2>`, `<F3>` | n | Step into/over/out |
| `<leader>b`, `<leader>B` | n | Toggle/set breakpoint |
| `<F7>` | n | Toggle DAP UI |

### Notes (Obsidian)

| Shortcut | Mode | Action |
| --- | --- | --- |
| `;d` | n | Follow link (Obsidian markdown only) |
| `<leader>ch` | n | Toggle checkbox (Obsidian markdown only) |

For a longer, more free-form reference, see `CHEATS.md`.

## Installation

### Install Neovim

Kickstart.nvim targets *only* the latest
['stable'](https://github.com/neovim/neovim/releases/tag/stable) and latest
['nightly'](https://github.com/neovim/neovim/releases/tag/nightly) of Neovim.
If you are experiencing issues, please make sure you have the latest versions.

### Install External Dependencies

External Requirements:
- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation),
  [fd-find](https://github.com/sharkdp/fd#installation)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Emoji fonts (Ubuntu only, and only if you want emoji!) `sudo apt install fonts-noto-color-emoji`
- Language Setup:
  - If you want to write Typescript, you need `npm`
  - If you want to write Golang, you will need `go`
  - etc.

> [!NOTE]
> See [Install Recipes](#Install-Recipes) for additional Windows and Linux specific notes
> and quick install snippets

### Install Kickstart

> [!NOTE]
> [Backup](#FAQ) your previous configuration (if any exists)

Neovim's configurations are located under the following paths, depending on your OS:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)| `%localappdata%\nvim\` |
| Windows (powershell)| `$env:LOCALAPPDATA\nvim\` |

#### Recommended Step

[Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repo
so that you have your own copy that you can modify, then install by cloning the
fork to your machine using one of the commands below, depending on your OS.

> [!NOTE]
> Your fork's URL will be something like this:
> `https://github.com/<your_github_username>/kickstart.nvim.git`

You likely want to remove `lazy-lock.json` from your fork's `.gitignore` file
too - it's ignored in the kickstart repo to make maintenance easier, but it's
[recommended to track it in version control](https://lazy.folke.io/usage/lockfile).

#### Clone kickstart.nvim

> [!NOTE]
> If following the recommended step above (i.e., forking the repo), replace
> `nvim-lua` with `<your_github_username>` in the commands below

<details><summary> Linux and Mac </summary>

```sh
git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>

If you're using `cmd.exe`:

```
git clone https://github.com/nvim-lua/kickstart.nvim.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```
git clone https://github.com/nvim-lua/kickstart.nvim.git "${env:LOCALAPPDATA}\nvim"
```

</details>

### Post Installation

Start Neovim

```sh
nvim
```

That's it! Lazy will install all the plugins you have. Use `:Lazy` to view
the current plugin status. Hit `q` to close the window.

#### Read The Friendly Documentation

Read through the `init.lua` file in your configuration folder for more
information about extending and exploring Neovim. That also includes
examples of adding popularly requested plugins.

> [!NOTE]
> For more information about a particular plugin check its repository's documentation.


### Getting Started

[The Only Video You Need to Get Started with Neovim](https://youtu.be/m8C0Cq9Uv9o)

### FAQ

* What should I do if I already have a pre-existing Neovim configuration?
  * You should back it up and then delete all associated files.
  * This includes your existing init.lua and the Neovim files in `~/.local`
    which can be deleted with `rm -rf ~/.local/share/nvim/`
* Can I keep my existing configuration in parallel to kickstart?
  * Yes! You can use [NVIM_APPNAME](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)`=nvim-NAME`
    to maintain multiple configurations. For example, you can install the kickstart
    configuration in `~/.config/nvim-kickstart` and create an alias:
    ```
    alias nvim-kickstart='NVIM_APPNAME="nvim-kickstart" nvim'
    ```
    When you run Neovim using `nvim-kickstart` alias it will use the alternative
    config directory and the matching local directory
    `~/.local/share/nvim-kickstart`. You can apply this approach to any Neovim
    distribution that you would like to try out.
* What if I want to "uninstall" this configuration:
  * See [lazy.nvim uninstall](https://lazy.folke.io/usage#-uninstalling) information
* Why is the kickstart `init.lua` a single file? Wouldn't it make sense to split it into multiple files?
  * The main purpose of kickstart is to serve as a teaching tool and a reference
    configuration that someone can easily use to `git clone` as a basis for their own.
    As you progress in learning Neovim and Lua, you might consider splitting `init.lua`
    into smaller parts. A fork of kickstart that does this while maintaining the
    same functionality is available here:
    * [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
  * Discussions on this topic can be found here:
    * [Restructure the configuration](https://github.com/nvim-lua/kickstart.nvim/issues/218)
    * [Reorganize init.lua into a multi-file setup](https://github.com/nvim-lua/kickstart.nvim/pull/473)

### Install Recipes

Below you can find OS specific install instructions for Neovim and dependencies.

After installing all the dependencies continue with the [Install Kickstart](#Install-Kickstart) step.

#### Windows Installation

<details><summary>Windows with Microsoft C++ Build Tools and CMake</summary>
Installation may require installing build tools and updating the run command for `telescope-fzf-native`

See `telescope-fzf-native` documentation for [more details](https://github.com/nvim-telescope/telescope-fzf-native.nvim#installation)

This requires:

- Install CMake and the Microsoft C++ Build Tools on Windows

```lua
{'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
```
</details>
<details><summary>Windows with gcc/make using chocolatey</summary>
Alternatively, one can install gcc and make which don't require changing the config,
the easiest way is to use choco:

1. install [chocolatey](https://chocolatey.org/install)
either follow the instructions on the page or use winget,
run in cmd as **admin**:
```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. install all requirements using choco, exit the previous cmd and
open a new one so that choco path is set, and run in cmd as **admin**:
```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make
```
</details>
<details><summary>WSL (Windows Subsystem for Linux)</summary>

```
wsl --install
wsl
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep unzip git xclip neovim
```
</details>

#### Linux Install
<details><summary>Ubuntu Install Steps</summary>

```
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep unzip git xclip neovim
```
</details>
<details><summary>Debian Install Steps</summary>

```
sudo apt update
sudo apt install make gcc ripgrep unzip git xclip curl

# Now we install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo mkdir -p /opt/nvim-linux-x86_64
sudo chmod a+rX /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# make it available in /usr/local/bin, distro installs to /usr/bin
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
```
</details>
<details><summary>Fedora Install Steps</summary>

```
sudo dnf install -y gcc make git ripgrep fd-find unzip neovim
```
</details>

<details><summary>Arch Install Steps</summary>

```
sudo pacman -S --noconfirm --needed gcc make git ripgrep fd unzip neovim
```
</details>
