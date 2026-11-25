# 42 VS Code config

🇫🇷 Français · [🇬🇧 English](README.en.md)

**La configuration VS Code prête à l'emploi pour les étudiants de 42, en C comme en Python.**

En deux commandes : les outils (compilateur, `make`, Python, norminette…), les extensions utiles, une indentation qui s'adapte au langage, le thème Axiom, des raccourcis, des snippets et des alias terminal pour la norme, la compilation et git.

```bash
git clone https://github.com/HorusExE69/42Config.git
cd 42Config
./setup/setup-linux.sh     # 1. outils manquants (ou setup-mac.command / setup-windows.bat)
./install.sh               # 2. extensions, paramètres VS Code et alias
```

---

## Sommaire

- [C ou Python : l'indentation s'adapte toute seule](#-c-ou-python--lindentation-sadapte-toute-seule)
- [Étape 1 : installer les outils](#️-étape-1--installer-les-outils)
- [Étape 2 : installer la configuration](#-étape-2--installer-la-configuration)
- [Apparence](#-apparence)
- [Extensions](#-extensions)
- [Raccourcis](#️-raccourcis)
- [Alias terminal](#️-alias-terminal)
- [Snippets](#️-snippets)
- [Contenu du dépôt](#-contenu-du-dépôt)
- [Désinstallation](#️-désinstallation)
- [FAQ](#-faq)

## ✨ C ou Python : l'indentation s'adapte toute seule

La norme C (norminette) impose des **tabulations**, la norme Python (flake8) impose **4 espaces**. VS Code applique automatiquement les réglages du langage du fichier ouvert : rien à changer à la main.

| | C (`.c`, `.h`) | Python (`.py`) | Makefile |
|---|---|---|---|
| Indentation | Tabulations | 4 espaces | Tabulations |
| Règle verticale | 80 colonnes | 79 colonnes | — |
| Norme | norminette (surlignée dans l'éditeur) | flake8 (soulignée dans l'éditeur) | — |
| Formateur | 42 C-Format (`c_formatter_42`) | autopep8 (à l'enregistrement) | — |
| Snippets | `main`, `func`, `wh`, `hguard`… | `main`, `def`, `class`… | `make42` |

L'indentation automatique (touche Entrée), la complétion et les snippets suivent ces réglages. La détection automatique d'indentation est désactivée pour qu'un fichier mal indenté ne « contamine » pas l'éditeur. Les espaces et tabulations sont rendus visibles, les espaces en fin de ligne supprimés à l'enregistrement.

## 🛠️ Étape 1 : installer les outils

Sur un ordinateur perso, il manque souvent le compilateur, `make`, Python ou la norminette. Le dossier [`setup/`](setup) contient un script par système qui **vérifie chaque outil et n'installe que ce qui manque**. Sur les postes de 42, tout est déjà là : passez à l'étape 2.

| Système | Lancer | Ce qui est vérifié / installé |
|---|---|---|
| Linux / WSL | `./setup/setup-linux.sh` | git, cc (gcc), make, gdb, valgrind, python3 ≥ 3.10, pip, venv, norminette, flake8, c_formatter_42, VS Code |
| macOS | Double-clic sur `setup/setup-mac.command` | Outils de ligne de commande Apple (cc, make, git, lldb), python3 ≥ 3.10, norminette, flake8, c_formatter_42, VS Code |
| Windows | Double-clic sur `setup/setup-windows.bat` | VS Code, Git, puis au choix : **WSL + Ubuntu** (recommandé) ou outils natifs (Python, gcc + gdb, make, norminette, flake8) |

| Option (Linux / macOS) | Effet |
|---|---|
| `--dry-run` | Montre ce qui serait installé, sans rien installer |
| `--extras` | (Linux) ajoute readline et les dépendances de la MiniLibX (minishell, so_long, fdf, cub3D…) |
| `--no-vscode` | N'installe pas VS Code |
| `-y` | (Linux) ne demande pas de confirmation |

Sous Windows : `setup-windows.ps1 -Mode WSL|Native|Both -DryRun`.

- **Linux** : les paquets passent par `apt`, `dnf`, `pacman` ou `zypper` (mot de passe `sudo` demandé). Sans droits admin, cette partie est ignorée proprement.
- **Outils de norme** (norminette, flake8, c_formatter_42) : installés dans `~/.local/bin` avec [uv](https://docs.astral.sh/uv/), **sans sudo**. uv récupère tout seul un Python compatible (norminette demande Python 3.10 ou plus, alors que le Python d'Apple est en 3.9).
- **macOS** : aucun mot de passe administrateur nécessaire. Sans Homebrew, VS Code est installé dans `~/Applications`. valgrind n'existe pas sur Mac : utilisez `leaks` (alias `vg`) ou `-fsanitize=address` (alias `ccws`).
- **Windows** : les installations passent par `winget`. Le C de 42 utilise des fonctions Linux (`unistd.h`, `fork`…) : **WSL est recommandé**. Si Ubuntu est déjà installé, le script lance `setup-linux.sh` directement dedans.

## 🚀 Étape 2 : installer la configuration

Sous Linux (postes de l'école), macOS ou WSL :

```bash
./install.sh
```

Le script demande votre login 42 et votre email (pour le header), puis :

1. installe les extensions VS Code ;
2. installe `norminette`, `flake8` et `c_formatter_42` s'ils manquent (**sans sudo**) ;
3. fusionne les paramètres, raccourcis et snippets dans votre configuration VS Code (vos réglages existants sont conservés et **sauvegardés** dans `~/.42-vscode-config/backups/`) ;
4. ajoute les alias à `~/.zshrc` et `~/.bashrc`.

Ouvrez ensuite un nouveau terminal et redémarrez VS Code.

| Option | Effet |
|---|---|
| `-y` | Aucune question (login = `$USER`) |
| `--login jdoe --email jdoe@student.42lyon.fr` | Identité pour le header |
| `--no-extensions` | N'installe pas les extensions |
| `--no-tools` | N'installe pas norminette / flake8 / c_formatter_42 |
| `--no-aliases` | Ne touche pas à `~/.zshrc` / `~/.bashrc` |
| `--no-vscode-config` | Ne touche pas aux paramètres VS Code |

> **macOS :** si la commande `code` est introuvable, dans VS Code faites `Cmd+Shift+P` › *Shell Command: Install 'code' command in PATH*, puis relancez `./install.sh`.

## 🎨 Apparence

| Réglage | Valeur | Effet |
|---|---|---|
| `workbench.colorTheme` | `Axiom Dark` | Thème [Axiom](https://marketplace.visualstudio.com/items?itemName=p47hf1nd3r.axiom-theme), monochrome et sobre |
| `editor.cursorSmoothCaretAnimation` | `on` | Le curseur glisse d'une position à l'autre au lieu de sauter |
| `editor.cursorBlinking` | `smooth` | Le curseur clignote en fondu |

Pour la version claire : `Ctrl+K` puis `Ctrl+T` › *Axiom Light*. Pour garder votre thème actuel, supprimez la ligne `workbench.colorTheme` de [`vscode/settings.json`](vscode/settings.json) avant d'installer.

## 🧩 Extensions

| Extension | Rôle |
|---|---|
| [42 Header](https://marketplace.visualstudio.com/items?itemName=kube.42header) | Header 42 (`Ctrl+Alt+H`), mis à jour à l'enregistrement |
| [42 Norminette Highlighter](https://marketplace.visualstudio.com/items?itemName=MariusvanWijk-JoppeKoers.codam-norminette-3) | Erreurs de norminette surlignées dans le code |
| [42 Ft Count Line](https://marketplace.visualstudio.com/items?itemName=DoKca.42-ft-count-line) | Nombre de lignes de chaque fonction (25 max) |
| [42 C-Format](https://marketplace.visualstudio.com/items?itemName=keyhr.42-c-format) | Formateur C conforme à la norme |
| [C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) | IntelliSense et débogueur (avec `-g3`) |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Python + Pylance |
| [Flake8](https://marketplace.visualstudio.com/items?itemName=ms-python.flake8) | Norme Python dans l'éditeur |
| [autopep8](https://marketplace.visualstudio.com/items?itemName=ms-python.autopep8) | Formateur Python compatible flake8 |
| [Mypy Type Checker](https://marketplace.visualstudio.com/items?itemName=ms-python.mypy-type-checker) | Vérification des annotations de type |
| [Error Lens](https://marketplace.visualstudio.com/items?itemName=usernamehw.errorlens) | Erreurs affichées en bout de ligne |
| [Axiom Theme](https://marketplace.visualstudio.com/items?itemName=p47hf1nd3r.axiom-theme) | Thème de couleurs |
| [Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph) | Historique git visuel |

La liste est dans [`extensions.txt`](extensions.txt) : ajoutez ou retirez une ligne pour l'adapter.

## ⌨️ Raccourcis

Sur macOS, `Ctrl+Alt` correspond à `Ctrl+Option`.

| Raccourci | En C | En Python |
|---|---|---|
| `Ctrl+Alt+H` | Insère le header 42 | Insère le header 42 |
| `Ctrl+Alt+N` | Enregistre puis `norminette -R CheckForbiddenSourceHeader` sur le fichier | Enregistre puis `flake8` sur le fichier |
| `Ctrl+Alt+M` | Enregistre puis compile **tous les `.c` du dossier** avec `-Wall -Wextra -Werror -g3` et lance `./a.out` | Enregistre puis lance `python3 fichier.py` |
| `Ctrl+Alt+G` | Ouvre le terminal et prépare `gpush ` : tapez votre message, Entrée | idem |
| `Shift+Alt+F` (`Ctrl+Shift+I` sous Linux) | Formate le fichier (42 C-Format) | Formate le fichier (autopep8) |

Les commandes s'exécutent dans le terminal intégré de VS Code. Pour les modifier : `Ctrl+Shift+P` › *Preferences: Open Keyboard Shortcuts (JSON)*.

## 🖥️ Alias terminal

Tapez `42help` pour les afficher.

| Alias | Commande |
|---|---|
| `ccw fichier.c …` | `cc -Wall -Wextra -Werror -g3 fichier.c …` |
| `ccws fichier.c …` | idem + `-fsanitize=address` (fuites, débordements) |
| `ccr [fichiers] [-- args]` | Compile (tous les `.c` du dossier par défaut) puis lance `./a.out args` |
| `norm [fichiers\|dossier]` | Choisit tout seul : `.c`/`.h` → norminette, `.py` → flake8. Sans argument : tout le dossier |
| `normc [fichiers]` | `norminette -R CheckForbiddenSourceHeader` |
| `normpy [fichiers]` | `flake8` |
| `gpush [message]` | `git add .` + `git commit -m "message"` + `git push` (message par défaut : `added`) |
| `gst` / `glog` | `git status` court / historique compact |
| `vg ./a.out` | `valgrind --leak-check=full …` (Linux) ou `leaks --atExit` (macOS) |

Les alias sont dans `~/.42-vscode-config/42aliases.sh` (copié depuis [`shell/42aliases.sh`](shell/42aliases.sh)).

> ⚠️ `gpush` ajoute **tout** le dossier (`git add .`). Pensez à un `.gitignore` pour ne pas rendre `a.out`, les `.o` ou un `main` de test.

## ✂️ Snippets

Tapez le préfixe puis `Tab`.

**C** (respectent la norme : tabulation entre type et nom, `return (0);`, pas de `for`)

| Préfixe | Contenu |
|---|---|
| `main` / `mainv` | `int main(int argc, char **argv)` / `int main(void)` |
| `maint` | `main` de test avec `printf` (à ne pas rendre) |
| `func` | Squelette de fonction |
| `wh` | Boucle `while` avec compteur |
| `ifel` | `if` / `else` |
| `hguard` | Protection `#ifndef NOM_H` d'après le nom du fichier |
| `inc` | `#include <unistd.h>` + `<stdlib.h>` |
| `struct` | `typedef struct s_nom { … } t_nom;` |
| `malloc` | `malloc` + vérification du retour |
| `wr` | `write(fd, buf, len);` |

**Python** (conformes à flake8)

| Préfixe | Contenu |
|---|---|
| `main` | `def main() -> None:` + `if __name__ == "__main__":` |
| `ifmain` | Bloc `if __name__ == "__main__":` |
| `def` | Fonction avec annotations de type et docstring |
| `class` | Classe avec `__init__` et `__str__` typés |
| `try` | `try` / `except` |
| `shebang` | `#!/usr/bin/env python3` |

**Makefile** : `make42` génère un Makefile complet (`all`, `clean`, `fclean`, `re`, sans relink).

## 📁 Contenu du dépôt

```
42Config/
├── setup/
│   ├── setup-linux.sh         # outils manquants — Linux / WSL
│   ├── setup-mac.command      # outils manquants — macOS (double-clic)
│   ├── setup-windows.bat      # outils manquants — Windows (double-clic)
│   └── setup-windows.ps1      #   (script appelé par le .bat)
├── vscode/
│   ├── settings.json          # paramètres (indentation par langage, thème, curseur…)
│   ├── keybindings.json       # raccourcis
│   └── snippets/              # c.json, python.json, makefile.json
├── shell/42aliases.sh         # alias terminal (bash / zsh)
├── scripts/merge_json.py      # fusion avec votre config VS Code existante
├── extensions.txt             # liste des extensions
├── install.sh                 # installe la configuration
└── uninstall.sh               # la retire
```

## 🗑️ Désinstallation

```bash
./uninstall.sh                 # retire les alias, restaure vos fichiers VS Code d'avant
./uninstall.sh --extensions    # désinstalle aussi les extensions
./uninstall.sh --keep-vscode   # garde les paramètres VS Code
```

Les outils installés par `setup/` (gcc, Python, norminette…) restent en place.

## ❓ FAQ

**Je n'ai pas les droits administrateur à l'école.** Rien ne nécessite `sudo` : les postes ont déjà les outils système, et norminette, flake8 et c_formatter_42 s'installent dans `~/.local/bin`, ajouté au `PATH` par les alias.

**Mes anciens paramètres VS Code ?** Ils sont fusionnés, pas écrasés. Seules les clés de cette config sont remplacées (dont le thème). Une copie est faite à chaque installation dans `~/.42-vscode-config/backups/`. Les commentaires de votre ancien `settings.json` disparaissent du fichier fusionné (ils restent dans la sauvegarde).

**Le formateur C change mon code ?** Le formatage C n'est pas automatique à l'enregistrement : lancez-le avec `Shift+Alt+F` et relisez. Pour l'activer à l'enregistrement, mettez `"editor.formatOnSave": true` dans le bloc `"[c]"`.

**Le header 42 en Python déclenche flake8 (E501).** Le header fait 80 colonnes, flake8 en autorise 79. Vérifiez si votre sujet Python demande un header ; la plupart ne le demandent pas.

**Windows sans WSL ?** `setup-windows.bat` (mode natif) installe gcc, make, Python et la norminette, et les paramètres, raccourcis et snippets fonctionnent. En revanche `install.sh` et les alias nécessitent un shell Unix, et le C de 42 utilise des fonctions Linux : WSL reste recommandé.

**VSCodium ?** Le script le détecte, mais certaines extensions Microsoft (C/C++) ne sont pas disponibles sur Open VSX.

## 📄 Licence

[MIT](LICENSE)
