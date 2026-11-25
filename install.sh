#!/usr/bin/env bash
# ===================================================================
#  42 VS Code config — installation (Linux, macOS, WSL)
#
#  ./install.sh                 installation complète (interactive)
#  ./install.sh -y              sans questions (login = $USER)
#  ./install.sh --login jdoe --email jdoe@student.42lyon.fr
#  ./install.sh --no-extensions --no-tools --no-aliases
#
#  Ne demande jamais sudo. Sauvegarde vos fichiers VS Code avant de
#  les modifier (~/.42-vscode-config/backups/).
# ===================================================================
set -u

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.42-vscode-config"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
MARK_BEGIN="# >>> 42-vscode-config >>>"
MARK_END="# <<< 42-vscode-config <<<"

DO_EXT=1; DO_TOOLS=1; DO_ALIASES=1; DO_VSCODE=1; ASSUME_YES=0
LOGIN=""; EMAIL=""

if [ -t 1 ]; then
	B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; N=$'\033[0m'
else
	B=""; G=""; Y=""; R=""; C=""; N=""
fi
info()  { printf '%s==>%s %s\n' "$C" "$N" "$*"; }
ok()    { printf '  %s✔%s %s\n' "$G" "$N" "$*"; }
warn()  { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
fail()  { printf '  %s✘%s %s\n' "$R" "$N" "$*"; }

usage() {
	sed -n '3,12p' "$0" | sed 's/^#  \{0,1\}//'
	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		-y|--yes)         ASSUME_YES=1 ;;
		--login)          LOGIN="${2:-}"; shift ;;
		--email)          EMAIL="${2:-}"; shift ;;
		--no-extensions)  DO_EXT=0 ;;
		--no-tools)       DO_TOOLS=0 ;;
		--no-aliases)     DO_ALIASES=0 ;;
		--no-vscode-config) DO_VSCODE=0 ;;
		-h|--help)        usage ;;
		*) fail "Option inconnue : $1"; usage ;;
	esac
	shift
done

ask() { # ask "question" "défaut" -> echo réponse
	local answer
	if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
		printf '%s' "$2"; return
	fi
	read -r -p "  $1 [$2] : " answer
	printf '%s' "${answer:-$2}"
}

printf '\n%s42 VS Code config%s — C (tabulations) & Python (espaces)\n\n' "$B" "$N"

# -------------------------------------------------------------------
#  Détection de VS Code (dossier utilisateur + commande `code`)
# -------------------------------------------------------------------
OS="$(uname -s)"
IS_WSL=0
if [ "$OS" = "Linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=1; fi

CODE_BIN=""
for c in code code-insiders codium; do
	if command -v "$c" >/dev/null 2>&1; then CODE_BIN="$c"; break; fi
done
if [ -z "$CODE_BIN" ] && [ "$OS" = "Darwin" ]; then
	for p in "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
	         "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
		if [ -x "$p" ]; then CODE_BIN="$p"; break; fi
	done
fi

USER_DIR=""
if [ "$IS_WSL" -eq 1 ] && command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
	WIN_APPDATA="$(cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r')"
	[ -n "$WIN_APPDATA" ] && USER_DIR="$(wslpath "$WIN_APPDATA")/Code/User"
elif [ "$OS" = "Darwin" ]; then
	USER_DIR="$HOME/Library/Application Support/Code/User"
	[ "$CODE_BIN" = "codium" ] && USER_DIR="$HOME/Library/Application Support/VSCodium/User"
else
	USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"
	if [ "$CODE_BIN" = "codium" ]; then
		USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"
	elif [ "$CODE_BIN" = "code-insiders" ]; then
		USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User"
	elif [ ! -d "$USER_DIR" ] && [ -d "$HOME/.var/app/com.visualstudio.code/config/Code/User" ]; then
		USER_DIR="$HOME/.var/app/com.visualstudio.code/config/Code/User"   # Flatpak
	fi
fi

info "Environnement"
ok "Système : $OS$([ "$IS_WSL" -eq 1 ] && echo ' (WSL)')"
if [ -n "$CODE_BIN" ]; then ok "Commande VS Code : $CODE_BIN"; else warn "Commande 'code' introuvable (extensions à installer à la main, voir README)"; fi
ok "Dossier de configuration : $USER_DIR"

# -------------------------------------------------------------------
#  Identité 42 (pour le header)
# -------------------------------------------------------------------
if [ "$DO_VSCODE" -eq 1 ]; then
	info "Identité pour le header 42"
	[ -z "$LOGIN" ] && LOGIN="$(ask "Login 42" "${USER:-login}")"
	[ -z "$EMAIL" ] && EMAIL="$(ask "Email 42" "$LOGIN@student.42.fr")"
	ok "$LOGIN <$EMAIL>"
fi

# -------------------------------------------------------------------
#  Extensions
# -------------------------------------------------------------------
if [ "$DO_EXT" -eq 1 ]; then
	info "Extensions VS Code"
	if [ -z "$CODE_BIN" ]; then
		warn "Ignoré : commande 'code' introuvable."
		warn "Dans VS Code : Ctrl+Shift+P > « Shell Command: Install 'code' command in PATH », puis relancez."
	else
		installed="$("$CODE_BIN" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
		while IFS= read -r line; do
			ext="$(printf '%s' "${line%%#*}" | tr -d '[:space:]')"
			[ -z "$ext" ] && continue
			if printf '%s\n' "$installed" | grep -qx "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"; then
				ok "$ext (déjà installée)"
			elif "$CODE_BIN" --install-extension "$ext" >/dev/null 2>&1; then
				ok "$ext"
			else
				fail "$ext (échec — installez-la depuis l'onglet Extensions)"
			fi
		done < "$REPO_DIR/extensions.txt"
	fi
fi

# -------------------------------------------------------------------
#  Outils de norme : norminette, flake8, c_formatter_42 (sans sudo)
# -------------------------------------------------------------------
if [ "$DO_TOOLS" -eq 1 ]; then
	# Délégué à setup/ : même logique (uv, sans sudo) que l'installation complète
	if [ "$OS" = "Darwin" ]; then
		bash "$REPO_DIR/setup/setup-mac.command" --python-tools-only | sed -n '/==>/,$p' | grep -v '^Résumé' || true
	else
		bash "$REPO_DIR/setup/setup-linux.sh" --python-tools-only | sed -n '/==>/,$p' | grep -v '^Résumé' || true
	fi
	echo "  (gcc, make, Python, VS Code… manquants ? lancez le script de setup/ pour votre système)"
fi

# -------------------------------------------------------------------
#  Fichiers VS Code (fusion + sauvegarde)
# -------------------------------------------------------------------
# Deux copies : une sauvegarde horodatée à chaque installation, et la
# config d'origine (avant la toute première installation) pour uninstall.sh
ORIG_DIR="$STATE_DIR/original"
FIRST_INSTALL=0
[ -d "$ORIG_DIR" ] || FIRST_INSTALL=1
backup() {
	local rel="${1#"$USER_DIR"/}"
	if [ -f "$1" ]; then
		mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
		cp "$1" "$BACKUP_DIR/$rel"
	fi
	if [ "$FIRST_INSTALL" -eq 1 ]; then
		mkdir -p "$ORIG_DIR/$(dirname "$rel")"
		if [ -f "$1" ]; then cp "$1" "$ORIG_DIR/$rel"; else printf '%s\n' "$rel" >> "$ORIG_DIR/.absent"; fi
	fi
}

if [ "$DO_VSCODE" -eq 1 ]; then
	info "Paramètres, raccourcis et snippets"
	if ! command -v python3 >/dev/null 2>&1; then
		fail "python3 est nécessaire pour fusionner les paramètres : étape ignorée."
	else
		mkdir -p "$USER_DIR/snippets"
		MERGE="python3 $REPO_DIR/scripts/merge_json.py"
		backup "$USER_DIR/settings.json"
		if $MERGE settings "$REPO_DIR/vscode/settings.json" "$USER_DIR/settings.json" \
			--set "__LOGIN__=$LOGIN" --set "__EMAIL__=$EMAIL"; then ok "settings.json"; else fail "settings.json"; fi
		backup "$USER_DIR/keybindings.json"
		if $MERGE keybindings "$REPO_DIR/vscode/keybindings.json" "$USER_DIR/keybindings.json"; then ok "keybindings.json"; else fail "keybindings.json"; fi
		for f in "$REPO_DIR"/vscode/snippets/*.json; do
			name="$(basename "$f")"
			backup "$USER_DIR/snippets/$name"
			if $MERGE snippets "$f" "$USER_DIR/snippets/$name"; then ok "snippets/$name"; else fail "snippets/$name"; fi
		done
		[ -d "$BACKUP_DIR" ] && ok "Sauvegarde de vos anciens fichiers : $BACKUP_DIR"
	fi
fi

# -------------------------------------------------------------------
#  Alias terminal
# -------------------------------------------------------------------
if [ "$DO_ALIASES" -eq 1 ]; then
	info "Alias terminal"
	mkdir -p "$STATE_DIR"
	cp "$REPO_DIR/shell/42aliases.sh" "$STATE_DIR/42aliases.sh"
	block="$MARK_BEGIN
[ -f \"\$HOME/.42-vscode-config/42aliases.sh\" ] && . \"\$HOME/.42-vscode-config/42aliases.sh\"
$MARK_END"
	rcs=()
	[ -f "$HOME/.zshrc" ] && rcs+=("$HOME/.zshrc")
	[ -f "$HOME/.bashrc" ] && rcs+=("$HOME/.bashrc")
	if [ "${#rcs[@]}" -eq 0 ]; then
		case "${SHELL:-}" in
			*zsh) rcs+=("$HOME/.zshrc") ;;
			*)    rcs+=("$HOME/.bashrc") ;;
		esac
	fi
	for rc in "${rcs[@]}"; do
		if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
			ok "$(basename "$rc") (déjà configuré)"
		else
			printf '\n%s\n' "$block" >> "$rc"
			ok "$(basename "$rc")"
		fi
	done
fi

printf '\n%sTerminé !%s\n' "$G" "$N"
[ "$DO_ALIASES" -eq 1 ] && printf '  • Ouvrez un nouveau terminal (ou : source ~/.zshrc) puis tapez %s42help%s\n' "$B" "$N"
[ "$DO_VSCODE" -eq 1 ] && printf '  • Redémarrez VS Code pour charger les extensions et les paramètres.\n'
printf '  • Désinstaller : %s./uninstall.sh%s\n\n' "$B" "$N"
