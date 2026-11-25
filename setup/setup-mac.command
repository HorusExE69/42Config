#!/usr/bin/env bash
# ===================================================================
#  42 VS Code config — installe les outils manquants (macOS)
#
#  Double-cliquez sur ce fichier dans le Finder
#  (1re fois : clic droit > Ouvrir si macOS bloque le fichier),
#  ou dans le Terminal :
#  ./setup/setup-mac.command               installe ce qui manque
#  ./setup/setup-mac.command --dry-run     montre ce qui serait installé
#  ./setup/setup-mac.command --no-vscode   n'installe pas VS Code
#
#  Outils : outils de ligne de commande Apple (cc/clang, make, git,
#  lldb), python3 (>= 3.10), norminette, flake8, c_formatter_42, VS Code.
#  Aucun mot de passe administrateur n'est nécessaire.
#  Rien n'est réinstallé s'il est déjà présent.
# ===================================================================
set -u

DRY_RUN=0; WITH_VSCODE=1; PY_TOOLS_ONLY=0
for arg in "$@"; do
	case "$arg" in
		--dry-run)   DRY_RUN=1 ;;
		--no-vscode) WITH_VSCODE=0 ;;
		--python-tools-only) PY_TOOLS_ONLY=1; WITH_VSCODE=0 ;;
		-y|--yes)    ;;
		-h|--help)   sed -n '3,16p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
		*) echo "Option inconnue : $arg (voir --help)"; exit 1 ;;
	esac
done

if [ -t 1 ]; then
	B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; D=$'\033[2m'; N=$'\033[0m'
else
	B=""; G=""; Y=""; R=""; C=""; D=""; N=""
fi
info() { printf '%s==>%s %s\n' "$C" "$N" "$*"; }
SUMMARY=()
present()  { printf '  %s✔%s %-16s %s\n' "$G" "$N" "$1" "${D}${2:-déjà installé}${N}"; SUMMARY+=("ok"); }
missing()  { printf '  %s•%s %-16s %s\n' "$Y" "$N" "$1" "à installer"; }
done_()    { printf '  %s✔%s %-16s installé\n' "$G" "$N" "$1"; SUMMARY+=("installed"); }
failed()   { printf '  %s✘%s %-16s %s\n' "$R" "$N" "$1" "${2:-échec}"; SUMMARY+=("failed"); }
skipped()  { printf '  %s-%s %-16s %s\n' "$Y" "$N" "$1" "${D}${2:-ignoré}${N}"; SUMMARY+=("skipped"); }

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
has() { command -v "$1" >/dev/null 2>&1; }
py_ok() {
	has python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null
}

if [ "$(uname -s)" != "Darwin" ]; then
	echo "Ce script est pour macOS. Sous Linux : ./setup/setup-linux.sh"
	exit 1
fi

printf '\n%s42 — installation des outils (macOS %s)%s%s\n\n' "$B" "$(sw_vers -productVersion 2>/dev/null)" "$N" \
	"$([ "$DRY_RUN" -eq 1 ] && echo '  [simulation]')"

# -------------------------------------------------------------------
#  1. Outils de ligne de commande Apple : cc, make, git, lldb, python3
# -------------------------------------------------------------------
if [ "$PY_TOOLS_ONLY" -eq 0 ]; then
	info "Outils de ligne de commande Apple"
	if xcode-select -p >/dev/null 2>&1; then
		present "Command Line Tools" "$(xcode-select -p)"
	elif [ "$DRY_RUN" -eq 1 ]; then
		missing "Command Line Tools"
	else
		missing "Command Line Tools"
		echo "    Une fenêtre macOS va s'ouvrir : cliquez sur « Installer » (quelques minutes)."
		xcode-select --install >/dev/null 2>&1
		waited=0
		until xcode-select -p >/dev/null 2>&1; do
			if [ "$waited" -ge 1800 ]; then break; fi
			sleep 10; waited=$((waited + 10))
			printf '\r    En attente de la fin de l'\''installation... %d min' $((waited / 60))
		done
		echo
		if xcode-select -p >/dev/null 2>&1; then done_ "Command Line Tools"
		else failed "Command Line Tools" "relancez ce script une fois l'installation terminée"; fi
	fi
	for t in cc make git lldb; do
		if has "$t"; then present "$t"; else skipped "$t" "fourni par les Command Line Tools"; fi
	done
	skipped "valgrind" "indisponible sur Mac : utilisez « leaks » ou -fsanitize=address"
	echo
fi

# -------------------------------------------------------------------
#  2. Python >= 3.10 et outils de 42 (sans mot de passe, ~/.local/bin)
# -------------------------------------------------------------------
info "Python et outils de norme"

ensure_uv() {
	has uv && return 0
	[ "$DRY_RUN" -eq 1 ] && return 0
	curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1
	has uv
}

if [ "$PY_TOOLS_ONLY" -eq 0 ]; then
	if py_ok; then
		present "python3" "$(python3 --version 2>&1)"
	elif [ "$DRY_RUN" -eq 1 ]; then
		missing "python3 >= 3.10"
	elif has brew && brew install python@3.12 >/dev/null 2>&1 && py_ok; then
		done_ "python3 (Homebrew)"
	elif ensure_uv && uv python install 3.12 >/dev/null 2>&1; then
		done_ "python3.12"
		echo "    ${D}(dans ~/.local/bin : le python3 d'Apple reste en $(python3 --version 2>&1 | cut -d' ' -f2) ; utilisez python3.12)${N}"
	else
		failed "python3 >= 3.10" "à télécharger : https://www.python.org/downloads/macos/"
	fi
fi

py_tool() { # py_tool <commande> <paquet pip>
	local cmd="$1" pkgname="$2"
	if has "$cmd"; then present "$cmd"; return; fi
	if [ "$DRY_RUN" -eq 1 ]; then missing "$cmd"; return; fi
	if ensure_uv && uv tool install --quiet "$pkgname" >/dev/null 2>&1 && has "$cmd"; then
		done_ "$cmd"; return
	fi
	if has pipx && pipx install "$pkgname" >/dev/null 2>&1 && has "$cmd"; then
		done_ "$cmd"; return
	fi
	failed "$cmd" "essayez : uv tool install $pkgname"
}
py_tool norminette norminette
py_tool flake8 flake8
py_tool c_formatter_42 c-formatter-42
echo

# -------------------------------------------------------------------
#  3. VS Code (dans ~/Applications si pas de droits admin)
# -------------------------------------------------------------------
if [ "$WITH_VSCODE" -eq 1 ]; then
	info "VS Code"
	if has code || [ -d "/Applications/Visual Studio Code.app" ] || [ -d "$HOME/Applications/Visual Studio Code.app" ]; then
		present "VS Code"
	elif [ "$DRY_RUN" -eq 1 ]; then
		missing "VS Code"
	elif has brew && brew install --cask visual-studio-code >/dev/null 2>&1; then
		done_ "VS Code (Homebrew)"
	else
		tmp="$(mktemp -d)"
		if curl -fLs -o "$tmp/vscode.zip" "https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal" \
			&& mkdir -p "$HOME/Applications" && ditto -x -k "$tmp/vscode.zip" "$HOME/Applications"; then
			done_ "VS Code" ; echo "    ${D}(dans ~/Applications)${N}"
		else
			failed "VS Code" "à télécharger : https://code.visualstudio.com/download"
		fi
		rm -rf "$tmp"
	fi
	echo
fi

# -------------------------------------------------------------------
#  Résumé
# -------------------------------------------------------------------
n_ok=0; n_inst=0; n_fail=0; n_skip=0
for s in "${SUMMARY[@]}"; do
	case "$s" in
		ok) n_ok=$((n_ok + 1)) ;; installed) n_inst=$((n_inst + 1)) ;;
		failed) n_fail=$((n_fail + 1)) ;; skipped) n_skip=$((n_skip + 1)) ;;
	esac
done
printf '%sRésumé :%s %d déjà présents, %d installés, %d ignorés, %d échecs\n' "$B" "$N" "$n_ok" "$n_inst" "$n_skip" "$n_fail"
if [ "$DRY_RUN" -eq 0 ] && [ "$PY_TOOLS_ONLY" -eq 0 ]; then
	echo "Étape suivante : ./install.sh (extensions, paramètres VS Code et alias)"
fi
[ "$n_fail" -eq 0 ]
