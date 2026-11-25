# 42 VS Code config

[🇫🇷 Français](README.md) · 🇬🇧 English

**The ready-to-use VS Code setup for 42 students, for C and Python alike.**

Two commands give you the tools (compiler, `make`, Python, norminette…), the useful extensions, indentation that adapts to the language, the Axiom theme, shortcuts, snippets and terminal aliases for the norm, compiling and git.

```bash
git clone https://github.com/HorusExE69/42Config.git
cd 42Config
./setup/setup-linux.sh     # 1. missing tools (or setup-mac.command / setup-windows.bat)
./install.sh               # 2. extensions, VS Code settings and aliases
```

---

## Contents

- [C or Python: indentation adapts by itself](#-c-or-python-indentation-adapts-by-itself)
- [Step 1: install the tools](#️-step-1-install-the-tools)
- [Step 2: install the config](#-step-2-install-the-config)
- [Look](#-look)
- [Extensions](#-extensions)
- [Shortcuts](#️-shortcuts)
- [Terminal aliases](#️-terminal-aliases)
- [Snippets](#️-snippets)
- [Repository layout](#-repository-layout)
- [Uninstall](#️-uninstall)
- [FAQ](#-faq)

## ✨ C or Python: indentation adapts by itself

The C norm (norminette) requires **tabs**; the Python norm (flake8) requires **4 spaces**. VS Code automatically applies the settings of the open file's language: nothing to switch by hand.

| | C (`.c`, `.h`) | Python (`.py`) | Makefile |
|---|---|---|---|
| Indentation | Tabs | 4 spaces | Tabs |
| Ruler | 80 columns | 79 columns | — |
| Norm | norminette (highlighted in the editor) | flake8 (underlined in the editor) | — |
| Formatter | 42 C-Format (`c_formatter_42`) | autopep8 (on save) | — |
| Snippets | `main`, `func`, `wh`, `hguard`… | `main`, `def`, `class`… | `make42` |

Auto-indent (Enter key), completion and snippets follow these settings. Indentation auto-detection is turned off so a badly indented file cannot "contaminate" the editor. Spaces and tabs are made visible, and trailing whitespace is removed on save.

## 🛠️ Step 1: install the tools

Personal computers often lack the compiler, `make`, Python or norminette. The [`setup/`](setup) folder holds one script per OS that **checks every tool and only installs what is missing**. School computers already have everything: go straight to step 2.

| OS | Run | Checked / installed |
|---|---|---|
| Linux / WSL | `./setup/setup-linux.sh` | git, cc (gcc), make, gdb, valgrind, python3 ≥ 3.10, pip, venv, norminette, flake8, c_formatter_42, VS Code |
| macOS | Double-click `setup/setup-mac.command` | Apple command line tools (cc, make, git, lldb), python3 ≥ 3.10, norminette, flake8, c_formatter_42, VS Code |
| Windows | Double-click `setup/setup-windows.bat` | VS Code, Git, then your choice: **WSL + Ubuntu** (recommended) or native tools (Python, gcc + gdb, make, norminette, flake8) |

| Option (Linux / macOS) | Effect |
|---|---|
| `--dry-run` | Shows what would be installed, installs nothing |
| `--extras` | (Linux) adds readline and the MiniLibX dependencies (minishell, so_long, fdf, cub3D…) |
| `--no-vscode` | Does not install VS Code |
| `-y` | (Linux) no confirmation prompt |

On Windows: `setup-windows.ps1 -Mode WSL|Native|Both -DryRun`.

- **Linux**: packages go through `apt`, `dnf`, `pacman` or `zypper` (asks for your `sudo` password). Without admin rights, that part is skipped cleanly.
- **Norm tools** (norminette, flake8, c_formatter_42): installed in `~/.local/bin` with [uv](https://docs.astral.sh/uv/), **no sudo**. uv fetches a compatible Python by itself (norminette needs Python 3.10+, while Apple's Python is 3.9).
- **macOS**: no administrator password needed. Without Homebrew, VS Code goes to `~/Applications`. valgrind does not exist on Mac: use `leaks` (alias `vg`) or `-fsanitize=address` (alias `ccws`).
- **Windows**: installs go through `winget`. 42's C uses Linux functions (`unistd.h`, `fork`…): **WSL is recommended**. If Ubuntu is already installed, the script runs `setup-linux.sh` inside it.

## 🚀 Step 2: install the config

On Linux (school computers), macOS or WSL:

```bash
./install.sh
```

The script asks for your 42 login and email (for the header), then:

1. installs the VS Code extensions;
2. installs `norminette`, `flake8` and `c_formatter_42` if missing (**no sudo**);
3. merges settings, shortcuts and snippets into your VS Code config (your existing settings are kept and **backed up** in `~/.42-vscode-config/backups/`);
4. adds the aliases to `~/.zshrc` and `~/.bashrc`.

Then open a new terminal and restart VS Code.

| Option | Effect |
|---|---|
| `-y` | No questions (login = `$USER`) |
| `--login jdoe --email jdoe@student.42lyon.fr` | Identity for the header |
| `--no-extensions` | Do not install extensions |
| `--no-tools` | Do not install norminette / flake8 / c_formatter_42 |
| `--no-aliases` | Do not touch `~/.zshrc` / `~/.bashrc` |
| `--no-vscode-config` | Do not touch VS Code settings |

> **macOS:** if the `code` command is missing, in VS Code press `Cmd+Shift+P` › *Shell Command: Install 'code' command in PATH*, then run `./install.sh` again.

## 🎨 Look

| Setting | Value | Effect |
|---|---|---|
| `workbench.colorTheme` | `Axiom Dark` | [Axiom](https://marketplace.visualstudio.com/items?itemName=p47hf1nd3r.axiom-theme) theme, clean and monochrome |
| `editor.cursorSmoothCaretAnimation` | `on` | The cursor glides between positions instead of jumping |
| `editor.cursorBlinking` | `smooth` | The cursor fades in and out |

For the light variant: `Ctrl+K` then `Ctrl+T` › *Axiom Light*. To keep your current theme, delete the `workbench.colorTheme` line from [`vscode/settings.json`](vscode/settings.json) before installing.

## 🧩 Extensions

| Extension | Purpose |
|---|---|
| [42 Header](https://marketplace.visualstudio.com/items?itemName=kube.42header) | 42 header (`Ctrl+Alt+H`), updated on save |
| [42 Norminette Highlighter](https://marketplace.visualstudio.com/items?itemName=MariusvanWijk-JoppeKoers.codam-norminette-3) | Norminette errors highlighted in your code |
| [42 Ft Count Line](https://marketplace.visualstudio.com/items?itemName=DoKca.42-ft-count-line) | Line count of each function (25 max) |
| [42 C-Format](https://marketplace.visualstudio.com/items?itemName=keyhr.42-c-format) | Norm-compliant C formatter |
| [C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) | IntelliSense and debugger (with `-g3`) |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Python + Pylance |
| [Flake8](https://marketplace.visualstudio.com/items?itemName=ms-python.flake8) | Python norm in the editor |
| [autopep8](https://marketplace.visualstudio.com/items?itemName=ms-python.autopep8) | flake8-compatible Python formatter |
| [Mypy Type Checker](https://marketplace.visualstudio.com/items?itemName=ms-python.mypy-type-checker) | Type annotation checking |
| [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) | Errors shown at the end of the line |
| [Axiom Theme](https://marketplace.visualstudio.com/items?itemName=p47hf1nd3r.axiom-theme) | Color theme |
| [Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph) | Visual git history |

The list lives in [`extensions.txt`](extensions.txt): add or remove a line to customize it.

## ⌨️ Shortcuts

On macOS, `Ctrl+Alt` means `Ctrl+Option`.

| Shortcut | In C | In Python |
|---|---|---|
| `Ctrl+Alt+H` | Inserts the 42 header | Inserts the 42 header |
| `Ctrl+Alt+N` | Saves, then `norminette -R CheckForbiddenSourceHeader` on the file | Saves, then `flake8` on the file |
| `Ctrl+Alt+M` | Saves, compiles **every `.c` in the folder** with `-Wall -Wextra -Werror -g3` and runs `./a.out` | Saves, then runs `python3 file.py` |
| `Ctrl+Alt+G` | Opens the terminal with `gpush ` ready: type your message, press Enter | same |
| `Shift+Alt+F` (`Ctrl+Shift+I` on Linux) | Formats the file (42 C-Format) | Formats the file (autopep8) |

Commands run in VS Code's integrated terminal. To change them: `Ctrl+Shift+P` › *Preferences: Open Keyboard Shortcuts (JSON)*.

## 🖥️ Terminal aliases

Type `42help` to list them.

| Alias | Command |
|---|---|
| `ccw file.c …` | `cc -Wall -Wextra -Werror -g3 file.c …` |
| `ccws file.c …` | same + `-fsanitize=address` (leaks, overflows) |
| `ccr [files] [-- args]` | Compiles (every `.c` in the folder by default), then runs `./a.out args` |
| `norm [files\|folder]` | Picks by itself: `.c`/`.h` → norminette, `.py` → flake8. No argument: the whole folder |
| `normc [files]` | `norminette -R CheckForbiddenSourceHeader` |
| `normpy [files]` | `flake8` |
| `gpush [message]` | `git add .` + `git commit -m "message"` + `git push` (default message: `added`) |
| `gst` / `glog` | Short `git status` / compact history |
| `vg ./a.out` | `valgrind --leak-check=full …` (Linux) or `leaks --atExit` (macOS) |

The aliases live in `~/.42-vscode-config/42aliases.sh` (copied from [`shell/42aliases.sh`](shell/42aliases.sh)).

> ⚠️ `gpush` adds **the whole folder** (`git add .`). Use a `.gitignore` so you never push `a.out`, `.o` files or a test `main`.

## ✂️ Snippets

Type the prefix, then `Tab`.

**C** (norm-compliant: tab between type and name, `return (0);`, no `for`)

| Prefix | Content |
|---|---|
| `main` / `mainv` | `int main(int argc, char **argv)` / `int main(void)` |
| `maint` | Test `main` with `printf` (do not turn it in) |
| `func` | Function skeleton |
| `wh` | `while` loop with a counter |
| `ifel` | `if` / `else` |
| `hguard` | `#ifndef NAME_H` guard based on the file name |
| `inc` | `#include <unistd.h>` + `<stdlib.h>` |
| `struct` | `typedef struct s_name { … } t_name;` |
| `malloc` | `malloc` + return check |
| `wr` | `write(fd, buf, len);` |

**Python** (flake8-compliant)

| Prefix | Content |
|---|---|
| `main` | `def main() -> None:` + `if __name__ == "__main__":` |
| `ifmain` | `if __name__ == "__main__":` block |
| `def` | Function with type annotations and a docstring |
| `class` | Class with typed `__init__` and `__str__` |
| `try` | `try` / `except` |
| `shebang` | `#!/usr/bin/env python3` |

**Makefile**: `make42` generates a full Makefile (`all`, `clean`, `fclean`, `re`, no relink).

## 📁 Repository layout

```
42Config/
├── setup/
│   ├── setup-linux.sh         # missing tools — Linux / WSL
│   ├── setup-mac.command      # missing tools — macOS (double-click)
│   ├── setup-windows.bat      # missing tools — Windows (double-click)
│   └── setup-windows.ps1      #   (script run by the .bat)
├── vscode/
│   ├── settings.json          # settings (per-language indentation, theme, cursor…)
│   ├── keybindings.json       # shortcuts
│   └── snippets/              # c.json, python.json, makefile.json
├── shell/42aliases.sh         # terminal aliases (bash / zsh)
├── scripts/merge_json.py      # merges with your existing VS Code config
├── extensions.txt             # extension list
├── install.sh                 # installs the config
└── uninstall.sh               # removes it
```

## 🗑️ Uninstall

```bash
./uninstall.sh                 # removes the aliases, restores your previous VS Code files
./uninstall.sh --extensions    # also uninstalls the extensions
./uninstall.sh --keep-vscode   # keeps the VS Code settings
```

Tools installed by `setup/` (gcc, Python, norminette…) stay in place.

## ❓ FAQ

**I have no admin rights at school.** Nothing needs `sudo`: school computers already have the system tools, and norminette, flake8 and c_formatter_42 go to `~/.local/bin`, which the aliases add to your `PATH`.

**What about my existing VS Code settings?** They are merged, not overwritten. Only this config's keys are replaced (including the theme). A copy is made on every install in `~/.42-vscode-config/backups/`. Comments in your old `settings.json` are dropped from the merged file (they remain in the backup).

**Does the C formatter change my code?** C formatting is not run on save: trigger it with `Shift+Alt+F` and review. To enable it on save, set `"editor.formatOnSave": true` in the `"[c]"` block.

**The 42 header in Python triggers flake8 (E501).** The header is 80 columns wide; flake8 allows 79. Check whether your Python subject requires a header; most do not.

**Windows without WSL?** `setup-windows.bat` (native mode) installs gcc, make, Python and norminette, and settings, shortcuts and snippets work. However `install.sh` and the aliases need a Unix shell, and 42's C uses Linux functions: WSL is still recommended.

**VSCodium?** The script detects it, but some Microsoft extensions (C/C++) are not available on Open VSX.

## 📄 License

[MIT](LICENSE)
