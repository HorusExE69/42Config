#!/usr/bin/env bash
# ===================================================================
#  42 VS Code config — installe les outils manquants (Linux / WSL)
#
#  ./setup/setup-linux.sh               installe ce qui manque
#  ./setup/setup-linux.sh --dry-run     montre ce qui serait installé
#  ./setup/setup-linux.sh --extras      + readline, MiniLibX (minishell, so_long, fdf…)
#  ./setup/setup-linux.sh --no-vscode   n'installe pas VS Code
#  ./setup/setup-linux.sh -y            ne pose aucune question
#
#  Outils : git, cc (gcc), make, gdb, valgrind, python3 (>= 3.10), pip,
#  venv, curl, norminette, flake8, c_formatter_42, VS Code.
#  Rien n'est réinstallé s'il est déjà présent.
# ===================================================================
set -u

DRY_RUN=0; EXTRAS=0; WITH_VSCODE=1; ASSUME_YES=0; PY_TOOLS_ONLY=0
for arg in "$@"; do
	case "$arg" in
		--dry-run)    DRY_RUN=1 ;;
		--extras)     EXTRAS=1 ;;
		--no-vscode)  WITH_VSCODE=0 ;;
		--python-tools-only) PY_TOOLS_ONLY=1; WITH_VSCODE=0 ;;
		-y|--yes)     ASSUME_YES=1 ;;
		-h|--help)    sed -n '3,14p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
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
present()  { printf '  %s✔%s %-16s %s\n' "$G" "$N" "$1" "${D}${2:-déjà installé}${N}"; SUMMARY+=("$1|ok"); }
missing()  { printf '  %s•%s %-16s %s\n' "$Y" "$N" "$1" "à installer"; }
done_()    { printf '  %s✔%s %-16s installé\n' "$G" "$N" "$1"; SUMMARY+=("$1|installed"); }
failed()   { printf '  %s✘%s %-16s %s\n' "$R" "$N" "$1" "${2:-échec}"; SUMMARY+=("$1|failed"); }
skipped()  { printf '  %s-%s %-16s %s\n' "$Y" "$N" "$1" "${D}${2:-ignoré}${N}"; SUMMARY+=("$1|skipped"); }

export PATH="$HOME/.local/bin:$PATH"
has() { command -v "$1" >/dev/null 2>&1; }

# En-têtes de la MiniLibX (X11, Xext, libbsd), y compris chemins multiarch
mlx_ok() {
	local f bsd=0
	for f in /usr/include/bsd/string.h /usr/include/*/bsd/string.h; do
		[ -f "$f" ] && bsd=1
	done
	[ "$bsd" -eq 1 ] && [ -f /usr/include/X11/Xlib.h ] && [ -f /usr/include/X11/extensions/XShm.h ]
}

# Version de python3 >= 3.10 ?
py_ok() {
	has python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null
}

printf '\n%s42 — installation des outils (Linux)%s%s\n\n' "$B" "$N" "$([ "$DRY_RUN" -eq 1 ] && echo '  [simulation]')"

# -------------------------------------------------------------------
#  Gestionnaire de paquets
# -------------------------------------------------------------------
PM=""
for p in apt-get dnf pacman zypper; do
	if has "$p"; then PM="$p"; break; fi
done

# pkg <outil> -> nom du paquet pour ce gestionnaire
pkg() {
	case "$PM:$1" in
		*:git) echo git ;;
		*:curl) echo curl ;;
		apt-get:cc) echo build-essential ;;
		*:cc) echo gcc ;;
		*:make) echo make ;;
		*:gdb) echo gdb ;;
		*:valgrind) echo valgrind ;;
		pacman:python3) echo python ;;
		*:python3) echo python3 ;;
		pacman:pip) echo python-pip ;;
		*:pip) echo python3-pip ;;
		apt-get:venv) echo python3-venv ;;
		apt-get:readline) echo libreadline-dev ;;
		dnf:readline|zypper:readline) echo readline-devel ;;
		pacman:readline) echo readline ;;
		apt-get:mlx) echo "libx11-dev libxext-dev libbsd-dev zlib1g-dev" ;;
		dnf:mlx) echo "libX11-devel libXext-devel libbsd-devel zlib-devel" ;;
		zypper:mlx) echo "libX11-devel libXext-devel libbsd-devel zlib-devel" ;;
		pacman:mlx) echo "libx11 libxext libbsd zlib" ;;
		*) echo "" ;;
	esac
}

# -------------------------------------------------------------------
#  1. Outils système (paquets)
# -------------------------------------------------------------------
TO_INSTALL=()   # noms d'outils
PKGS=()         # paquets correspondants

need() { # need <outil> <test...>
	local tool="$1"; shift
	if "$@" >/dev/null 2>&1; then
		present "$tool"
	else
		local p; p="$(pkg "$tool")"
		if [ -z "$p" ]; then
			skipped "$tool" "non disponible avec $PM"
		else
			missing "$tool"
			TO_INSTALL+=("$tool")
			# shellcheck disable=SC2206
			PKGS+=($p)
		fi
	fi
}

if [ "$PY_TOOLS_ONLY" -eq 0 ]; then
	info "Outils système"
	if [ -z "$PM" ]; then
		skipped "paquets" "gestionnaire de paquets non reconnu (apt, dnf, pacman, zypper)"
	else
		need git      has git
		need curl     has curl
		need cc       has cc
		need make     has make
		need gdb      has gdb
		need valgrind has valgrind
		need python3  py_ok
		need pip      python3 -m pip --version
		[ "$PM" = "apt-get" ] && need venv python3 -c 'import ensurepip, venv'
		if [ "$EXTRAS" -eq 1 ]; then
			need readline test -f /usr/include/readline/readline.h
			need mlx      mlx_ok
		fi

		if [ "${#PKGS[@]}" -gt 0 ]; then
			if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
			case "$PM" in
				apt-get) CMD_UPDATE="$SUDO apt-get update -qq"; CMD_INSTALL="$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold" ;;
				dnf)     CMD_UPDATE=":"; CMD_INSTALL="$SUDO dnf install -y -q" ;;
				pacman)  CMD_UPDATE=":"; CMD_INSTALL="$SUDO pacman -S --needed --noconfirm" ;;
				zypper)  CMD_UPDATE=":"; CMD_INSTALL="$SUDO zypper --non-interactive install" ;;
			esac
			echo
			echo "  Paquets à installer : ${PKGS[*]}"
			CONFIRM="o"
			if [ "$DRY_RUN" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ]; then
				read -r -p "  Installer ces paquets ? [O/n] " CONFIRM
				CONFIRM="${CONFIRM:-o}"
			fi
			if [ "$DRY_RUN" -eq 1 ]; then
				echo "  ${D}(simulation) $CMD_INSTALL ${PKGS[*]}${N}"
			elif [ "${CONFIRM#[oOyY]}" = "$CONFIRM" ]; then
				for t in "${TO_INSTALL[@]}"; do skipped "$t" "refusé"; done
			elif [ -n "$SUDO" ] && ! has sudo; then
				for t in "${TO_INSTALL[@]}"; do skipped "$t" "sudo introuvable"; done
			elif [ -n "$SUDO" ] && ! sudo -v; then
				echo "  ${Y}Pas de droits administrateur (normal sur les postes de 42 : ces outils y sont déjà installés).${N}"
				for t in "${TO_INSTALL[@]}"; do skipped "$t" "droits admin nécessaires"; done
			else
				# shellcheck disable=SC2086
				$CMD_UPDATE >/dev/null 2>&1
				# shellcheck disable=SC2086
				if $CMD_INSTALL "${PKGS[@]}"; then
					for t in "${TO_INSTALL[@]}"; do done_ "$t"; done
				else
					for t in "${TO_INSTALL[@]}"; do failed "$t" "échec du gestionnaire de paquets"; done
				fi
			fi
		fi
	fi
	echo
fi

# -------------------------------------------------------------------
#  2. Outils Python de 42 (sans sudo, dans ~/.local/bin)
#     uv choisit tout seul un Python compatible (norminette : >= 3.10)
# -------------------------------------------------------------------
info "Outils de norme et de formatage"

ensure_uv() {
	has uv && return 0
	[ "$DRY_RUN" -eq 1 ] && return 0
	if has curl; then
		curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1
	elif has wget; then
		wget -qO- https://astral.sh/uv/install.sh 2>/dev/null | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1
	fi
	has uv || { python3 -m pip install --user --quiet uv >/dev/null 2>&1 \
		|| python3 -m pip install --user --quiet --break-system-packages uv >/dev/null 2>&1; }
	has uv
}

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
	if py_ok && { python3 -m pip install --user --quiet "$pkgname" >/dev/null 2>&1 \
		|| python3 -m pip install --user --quiet --break-system-packages "$pkgname" >/dev/null 2>&1; } && has "$cmd"; then
		done_ "$cmd"; return
	fi
	failed "$cmd" "essayez : uv tool install $pkgname"
}

py_tool norminette norminette
py_tool flake8 flake8
py_tool c_formatter_42 c-formatter-42

# Python >= 3.10 introuvable et pas installable par paquets : version utilisateur
if [ "$PY_TOOLS_ONLY" -eq 0 ] && ! py_ok; then
	if [ "$DRY_RUN" -eq 1 ]; then
		missing "python3.12"
	elif ensure_uv && uv python install 3.12 >/dev/null 2>&1; then
		done_ "python3.12" ; echo "    ${D}(dans ~/.local/bin : lancez vos scripts avec python3.12)${N}"
	else
		failed "python3.12"
	fi
fi
echo

# -------------------------------------------------------------------
#  3. VS Code
# -------------------------------------------------------------------
if [ "$WITH_VSCODE" -eq 1 ]; then
	info "VS Code"
	if has code || has codium; then
		present "VS Code"
	elif grep -qi microsoft /proc/version 2>/dev/null; then
		skipped "VS Code" "WSL : installez VS Code côté Windows (setup-windows.bat)"
	elif [ "$DRY_RUN" -eq 1 ]; then
		missing "VS Code"
	elif has snap && if [ "$(id -u)" -eq 0 ]; then snap install code --classic >/dev/null 2>&1; \
		else has sudo && sudo -v && sudo snap install code --classic >/dev/null 2>&1; fi; then
		done_ "VS Code"
	elif has flatpak && flatpak install --user -y flathub com.visualstudio.code >/dev/null 2>&1; then
		done_ "VS Code" ; echo "    ${D}(Flatpak : lancez-le avec « flatpak run com.visualstudio.code »)${N}"
	else
		skipped "VS Code" "à télécharger : https://code.visualstudio.com/download"
	fi
	echo
fi

# -------------------------------------------------------------------
#  Résumé
# -------------------------------------------------------------------
n_ok=0; n_inst=0; n_fail=0; n_skip=0
for s in "${SUMMARY[@]}"; do
	case "${s#*|}" in
		ok) n_ok=$((n_ok + 1)) ;; installed) n_inst=$((n_inst + 1)) ;;
		failed) n_fail=$((n_fail + 1)) ;; skipped) n_skip=$((n_skip + 1)) ;;
	esac
done
printf '%sRésumé :%s %d déjà présents, %d installés, %d ignorés, %d échecs\n' "$B" "$N" "$n_ok" "$n_inst" "$n_skip" "$n_fail"
if [ "$DRY_RUN" -eq 0 ] && [ "$PY_TOOLS_ONLY" -eq 0 ]; then
	echo "Étape suivante : ./install.sh (extensions, paramètres VS Code et alias)"
fi
[ "$n_fail" -eq 0 ]
