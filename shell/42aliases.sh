# shellcheck shell=bash
# ===================================================================
#  42 VS Code config — alias terminal (bash / zsh)
#  Chargé depuis ~/.zshrc et ~/.bashrc par install.sh.
#  Tapez `42help` pour la liste.
# ===================================================================

# Outils installés avec pip --user (norminette, flake8, c_formatter_42)
case ":$PATH:" in
	*":$HOME/.local/bin:"*) ;;
	*) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ---- Compilation ----------------------------------------------------
# ccw fichier.c ...      compile avec les flags 42
alias ccw='cc -Wall -Wextra -Werror -g3'
# ccws fichier.c ...     idem + AddressSanitizer (fuites, débordements)
alias ccws='cc -Wall -Wextra -Werror -g3 -fsanitize=address'

# ccr [fichiers.c] [-- args]   compile (tous les .c du dossier par défaut) puis lance ./a.out
ccr() {
	local files=() args=() seen_sep=0 f
	[ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob
	for f in "$@"; do
		if [ "$seen_sep" -eq 1 ]; then args+=("$f")
		elif [ "$f" = "--" ]; then seen_sep=1
		else files+=("$f"); fi
	done
	if [ "${#files[@]}" -eq 0 ]; then
		for f in *.c; do [ -e "$f" ] && files+=("$f"); done
	fi
	if [ "${#files[@]}" -eq 0 ]; then
		echo "ccr: aucun fichier .c ici" >&2
		return 1
	fi
	cc -Wall -Wextra -Werror -g3 "${files[@]}" -o a.out && ./a.out "${args[@]}"
}

# ---- Norme ----------------------------------------------------------
# normc [fichiers]       norminette -R CheckForbiddenSourceHeader
alias normc='norminette -R CheckForbiddenSourceHeader'
# normpy [fichiers]      flake8 (norme Python)
normpy() {
	if [ "$#" -eq 0 ]; then
		set -- --exclude .git,.venv,venv,__pycache__ .
	fi
	if command -v flake8 >/dev/null 2>&1; then
		flake8 "$@" && echo "flake8: OK"
	else
		python3 -m flake8 "$@" && echo "flake8: OK"
	fi
}

# norm [fichiers|dossiers]   choisit tout seul : .c/.h -> norminette, .py -> flake8
# shellcheck disable=SC2120
norm() {
	local rc=0 f has_c has_py
	if [ "$#" -eq 0 ]; then
		has_c=$(find . -path '*/.*' -prune -o \( -name '*.c' -o -name '*.h' \) -print 2>/dev/null | head -n 1)
		has_py=$(find . -path '*/.*' -prune -o -name 'venv' -prune -o -name '*.py' -print 2>/dev/null | head -n 1)
		if [ -z "$has_c" ] && [ -z "$has_py" ]; then
			echo "norm: aucun fichier .c, .h ou .py ici" >&2
			return 1
		fi
		if [ -n "$has_c" ]; then
			norminette -R CheckForbiddenSourceHeader || rc=1
		fi
		if [ -n "$has_py" ]; then
			normpy || rc=1
		fi
		return "$rc"
	fi
	for f in "$@"; do
		case "$f" in
			*.c|*.h) norminette -R CheckForbiddenSourceHeader "$f" || rc=1 ;;
			*.py)    normpy "$f" || rc=1 ;;
			*)
				if [ -d "$f" ]; then
					(cd "$f" && norm) || rc=1
				else
					echo "norm: type de fichier non géré : $f" >&2
					rc=1
				fi
				;;
		esac
	done
	return "$rc"
}

# ---- Git ------------------------------------------------------------
# gpush [message]        git add . && git commit -m "message" && git push
#                        (message par défaut : "added")
gpush() {
	local msg="${*:-added}"
	git add . && git commit -m "$msg" && git push
}
# gst                    git status court
alias gst='git status -sb'
# glog                   historique compact
alias glog='git log --oneline --graph --decorate -n 20'

# ---- Mémoire ----------------------------------------------------------
if command -v valgrind >/dev/null 2>&1; then
	# vg ./a.out           valgrind complet (fuites + origine)
	alias vg='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'
elif [ "$(uname -s)" = "Darwin" ]; then
	# vg ./a.out           équivalent macOS : leaks à la sortie du programme
	alias vg='leaks --atExit --'
fi

# ---- Aide -------------------------------------------------------------
42help() {
	cat <<'EOF'
42 VS Code config — alias
  ccw  fichier.c ...       cc -Wall -Wextra -Werror -g3
  ccws fichier.c ...       idem + -fsanitize=address
  ccr  [fichiers] [-- args] compile (tous les .c par défaut) et lance ./a.out
  norm [fichiers|dossier]  norminette pour .c/.h, flake8 pour .py (auto)
  normc [fichiers]         norminette -R CheckForbiddenSourceHeader
  normpy [fichiers]        flake8
  gpush [message]          git add . + commit -m (défaut "added") + push
  gst / glog               git status court / historique compact
  vg ./a.out               valgrind (Linux) ou leaks (macOS)
Raccourcis VS Code : Ctrl+Alt+H header · Ctrl+Alt+N norme · Ctrl+Alt+M compiler/lancer · Ctrl+Alt+G gpush
EOF
}
