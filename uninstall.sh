#!/usr/bin/env bash
# ===================================================================
#  42 VS Code config — désinstallation
#
#  ./uninstall.sh                 retire les alias et restaure vos
#                                 fichiers VS Code d'avant l'installation
#  ./uninstall.sh --extensions    désinstalle aussi les extensions
#  ./uninstall.sh --keep-vscode   ne touche pas aux fichiers VS Code
# ===================================================================
set -u

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.42-vscode-config"
MARK_BEGIN="# >>> 42-vscode-config >>>"
MARK_END="# <<< 42-vscode-config <<<"
DO_EXT=0; DO_VSCODE=1

while [ $# -gt 0 ]; do
	case "$1" in
		--extensions)  DO_EXT=1 ;;
		--keep-vscode) DO_VSCODE=0 ;;
		-h|--help)     sed -n '3,9p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
		*) echo "Option inconnue : $1"; exit 1 ;;
	esac
	shift
done

echo "==> Alias terminal"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
	if [ -f "$rc" ] && grep -qF "$MARK_BEGIN" "$rc"; then
		tmp="$(mktemp)"
		awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
			$0 == b { skip = 1; next }
			$0 == e { skip = 0; next }
			!skip' "$rc" > "$tmp" && cat "$tmp" > "$rc"
		rm -f "$tmp"
		echo "  ✔ $(basename "$rc") nettoyé"
	fi
done
rm -f "$STATE_DIR/42aliases.sh"

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then USER_DIR="$HOME/Library/Application Support/Code/User"
elif grep -qi microsoft /proc/version 2>/dev/null && command -v cmd.exe >/dev/null 2>&1; then
	USER_DIR="$(wslpath "$(cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r')")/Code/User"
else USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"; fi

if [ "$DO_VSCODE" -eq 1 ]; then
	echo "==> Fichiers VS Code"
	ORIG_DIR="$STATE_DIR/original"
	if [ -d "$ORIG_DIR" ]; then
		# Restaure vos fichiers d'avant la première installation
		(cd "$ORIG_DIR" && find . -type f ! -name .absent) | while IFS= read -r f; do
			mkdir -p "$USER_DIR/$(dirname "$f")"
			cp "$ORIG_DIR/$f" "$USER_DIR/$f"
			echo "  ✔ restauré : ${f#./}"
		done
		# Supprime ceux qui n'existaient pas avant
		if [ -f "$ORIG_DIR/.absent" ]; then
			while IFS= read -r f; do
				[ -n "$f" ] && [ -f "$USER_DIR/$f" ] && rm -f "$USER_DIR/$f" && echo "  ✔ supprimé : $f"
			done < "$ORIG_DIR/.absent"
		fi
		rm -rf "$ORIG_DIR"
	else
		echo "  ! aucune configuration d'origine enregistrée : fichiers VS Code laissés tels quels"
	fi
fi

if [ "$DO_EXT" -eq 1 ]; then
	echo "==> Extensions"
	CODE_BIN="$(command -v code || command -v codium || true)"
	if [ -n "$CODE_BIN" ]; then
		while IFS= read -r line; do
			ext="$(printf '%s' "${line%%#*}" | tr -d '[:space:]')"
			[ -z "$ext" ] && continue
			"$CODE_BIN" --uninstall-extension "$ext" >/dev/null 2>&1 && echo "  ✔ $ext"
		done < "$REPO_DIR/extensions.txt"
	else
		echo "  ! commande 'code' introuvable"
	fi
fi

echo "Terminé. Ouvrez un nouveau terminal et redémarrez VS Code."
