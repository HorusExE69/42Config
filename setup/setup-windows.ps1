<#
.SYNOPSIS
  42 VS Code config - installe les outils manquants (Windows 10 / 11).

.DESCRIPTION
  Double-cliquez sur setup-windows.bat, ou dans PowerShell :
    .\setup\setup-windows.ps1                  menu interactif
    .\setup\setup-windows.ps1 -Mode WSL        WSL + Ubuntu (recommandé pour le C de 42)
    .\setup\setup-windows.ps1 -Mode Native     outils Windows natifs
    .\setup\setup-windows.ps1 -Mode Both       les deux
    .\setup\setup-windows.ps1 -DryRun          montre ce qui serait installé

  Toujours : VS Code et Git.
  WSL      : extension VS Code « WSL », Ubuntu, puis setup-linux.sh dans Ubuntu
             (cc, make, gdb, valgrind, python3, norminette, flake8…).
  Native   : Python 3, gcc + gdb (WinLibs), make, norminette, flake8,
             c_formatter_42 (via uv, sans droits administrateur).
  Rien n'est réinstallé s'il est déjà présent. Les installations passent
  par winget (le gestionnaire de paquets de Windows).
#>
[CmdletBinding()]
param(
  [ValidateSet('', 'WSL', 'Native', 'Both')]
  [string]$Mode = '',
  [switch]$DryRun,
  [switch]$NoVSCode
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}

$Summary = @{ ok = 0; installed = 0; skipped = 0; failed = 0 }
function Write-Info($msg)    { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Present($name, $detail = 'déjà installé') { Write-Host ('  ✔ {0,-16} ' -f $name) -ForegroundColor Green -NoNewline; Write-Host $detail -ForegroundColor DarkGray; $Summary.ok++ }
function Write-Missing($name) { Write-Host ('  • {0,-16} à installer' -f $name) -ForegroundColor Yellow }
function Write-Done($name)    { Write-Host ('  ✔ {0,-16} installé' -f $name) -ForegroundColor Green; $Summary.installed++ }
function Write-Failed($name, $detail = 'échec') { Write-Host ('  ✘ {0,-16} {1}' -f $name, $detail) -ForegroundColor Red; $Summary.failed++ }
function Write-Skipped($name, $detail = 'ignoré') { Write-Host ('  - {0,-16} {1}' -f $name, $detail) -ForegroundColor Yellow; $Summary.skipped++ }

function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $extra = @("$env:USERPROFILE\.local\bin", "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
             "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin")
  $env:Path = (@($machine, $user) + $extra | Where-Object { $_ }) -join ';'
}

function Test-Command($name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
  # Ignore les faux python.exe de WindowsApps (ils ouvrent le Microsoft Store)
  return [bool]($cmd -and $cmd.Source -notlike '*\WindowsApps\*')
}

function Test-Python {
  foreach ($exe in @('py', 'python', 'python3')) {
    if (Test-Command $exe) {
      $code = 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'
      if ($exe -eq 'py') { & py -3 -c $code 2>$null } else { & $exe -c $code 2>$null }
      if ($LASTEXITCODE -eq 0) { return $true }
    }
  }
  return $false
}

function Test-VSCode {
  return (Test-Command 'code') -or (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") `
    -or (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe")
}

# Installe un paquet winget si le test échoue
function Install-Tool($name, $wingetId, [scriptblock]$test) {
  if (& $test) { Write-Present $name; return }
  if ($DryRun) { Write-Missing $name; return }
  if (-not $script:HasWinget) { Write-Failed $name 'winget introuvable'; return }
  Write-Host ('  … {0,-16} installation ({1})' -f $name, $wingetId) -ForegroundColor DarkGray
  & winget install --id $wingetId --exact --source winget --silent `
    --accept-package-agreements --accept-source-agreements | Out-Null
  Update-SessionPath
  if (& $test) { Write-Done $name } else { Write-Failed $name "winget install --id $wingetId" }
}

Update-SessionPath
Write-Host ''
Write-Host ('42 — installation des outils (Windows)' + $(if ($DryRun) { '  [simulation]' } else { '' })) -ForegroundColor White
Write-Host ''

$script:HasWinget = Test-Command 'winget'
if (-not $script:HasWinget -and -not $DryRun) {
  Write-Host "winget est introuvable. Installez « App Installer » depuis le Microsoft Store, puis relancez." -ForegroundColor Red
  Start-Process 'ms-windows-store://pdp/?productid=9NBLGGH4NNS1' -ErrorAction SilentlyContinue
  exit 1
}

# -------------------------------------------------------------------
#  Choix du mode
# -------------------------------------------------------------------
if (-not $Mode) {
  Write-Host 'Comment voulez-vous coder ?'
  Write-Host '  [1] WSL + Ubuntu  (recommandé : le C de 42 utilise des fonctions Linux/POSIX)'
  Write-Host '  [2] Windows natif (gcc, make, Python, norminette directement sous Windows)'
  Write-Host '  [3] Les deux'
  $choice = Read-Host 'Votre choix [1]'
  switch ($choice) { '2' { $Mode = 'Native' } '3' { $Mode = 'Both' } default { $Mode = 'WSL' } }
  Write-Host ''
}

# -------------------------------------------------------------------
#  Commun : VS Code + Git
# -------------------------------------------------------------------
Write-Info 'Commun'
if (-not $NoVSCode) { Install-Tool 'VS Code' 'Microsoft.VisualStudioCode' { Test-VSCode } }
Install-Tool 'git' 'Git.Git' { Test-Command 'git' }
Write-Host ''

# -------------------------------------------------------------------
#  Natif
# -------------------------------------------------------------------
if ($Mode -in @('Native', 'Both')) {
  Write-Info 'Outils Windows natifs'
  Install-Tool 'python3'  'Python.Python.3.13'               { Test-Python }
  Install-Tool 'gcc'      'BrechtSanders.WinLibs.POSIX.UCRT' { Test-Command 'gcc' }
  if (Test-Command 'gdb') { Write-Present 'gdb' } elseif (-not $DryRun) { Write-Skipped 'gdb' 'fourni avec WinLibs (rouvrez le terminal)' } else { Write-Missing 'gdb' }
  Install-Tool 'make'     'ezwinports.make'                  { Test-Command 'make' }
  Install-Tool 'uv'       'astral-sh.uv'                     { Test-Command 'uv' }

  foreach ($t in @(@('norminette', 'norminette'), @('flake8', 'flake8'), @('c_formatter_42', 'c-formatter-42'))) {
    $cmd, $pkg = $t
    if (Test-Command $cmd) { Write-Present $cmd; continue }
    if ($DryRun) { Write-Missing $cmd; continue }
    if (-not (Test-Command 'uv')) { Write-Failed $cmd 'uv introuvable'; continue }
    & uv tool install --quiet $pkg 2>$null | Out-Null
    Update-SessionPath
    if (Test-Command $cmd) { Write-Done $cmd } else { Write-Failed $cmd "uv tool install $pkg" }
  }
  if (-not $DryRun -and (Test-Command 'uv')) { & uv tool update-shell 2>$null | Out-Null }
  Write-Host '  Note : sous Windows, compilez avec « gcc » (la commande « cc » n''existe pas).' -ForegroundColor DarkGray
  Write-Host ''
}

# -------------------------------------------------------------------
#  WSL
# -------------------------------------------------------------------
if ($Mode -in @('WSL', 'Both')) {
  Write-Info 'WSL + Ubuntu'
  if (-not $NoVSCode -and (Test-Command 'code')) {
    $exts = (& code --list-extensions 2>$null) -join "`n"
    if ($exts -match '(?im)^ms-vscode-remote\.remote-wsl$') { Write-Present 'extension WSL' }
    elseif ($DryRun) { Write-Missing 'extension WSL' }
    else {
      & code --install-extension ms-vscode-remote.remote-wsl 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { Write-Done 'extension WSL' } else { Write-Failed 'extension WSL' }
    }
  }

  $distros = @()
  if (Test-Command 'wsl') {
    $distros = @((& wsl.exe -l -q 2>$null) | ForEach-Object { ($_ -replace "`0", '').Trim() } |
      Where-Object { $_ -and $_ -notmatch '^docker-desktop' })
  }

  if ($distros.Count -eq 0) {
    if ($DryRun) {
      Write-Missing 'Ubuntu (WSL)'
    } else {
      Write-Host '  Installation de WSL + Ubuntu (droits administrateur demandés)…' -ForegroundColor DarkGray
      try {
        $p = Start-Process powershell.exe -Verb RunAs -Wait -PassThru `
          -ArgumentList '-NoProfile', '-Command', 'wsl.exe --install -d Ubuntu; Read-Host "Appuyez sur Entrée"'
        if ($p.ExitCode -eq 0) { Write-Done 'Ubuntu (WSL)' } else { Write-Failed 'Ubuntu (WSL)' 'wsl --install -d Ubuntu' }
      } catch {
        Write-Failed 'Ubuntu (WSL)' 'autorisation refusée'
      }
      Write-Host ''
      Write-Host '  Étapes suivantes :' -ForegroundColor White
      Write-Host '   1. Redémarrez le PC si Windows le demande.'
      Write-Host '   2. Ouvrez « Ubuntu » depuis le menu Démarrer et créez votre utilisateur.'
      Write-Host '   3. Relancez setup-windows.bat : les outils seront installés dans Ubuntu.'
    }
  } else {
    Write-Present 'WSL' ($distros -join ', ')
    $linuxScript = Join-Path $PSScriptRoot 'setup-linux.sh'
    if (-not (Test-Path $linuxScript)) {
      Write-Failed 'outils Linux' 'setup-linux.sh introuvable à côté de ce script'
    } else {
      $wslPath = (& wsl.exe wslpath -a ($linuxScript -replace '\\', '/') 2>$null | Select-Object -First 1)
      Write-Host ''
      Write-Info "Outils dans $($distros[0]) (setup-linux.sh)"
      $linuxArgs = @('--no-vscode')
      if ($DryRun) { $linuxArgs += '--dry-run' }
      & wsl.exe -- bash $wslPath @linuxArgs
      if ($LASTEXITCODE -eq 0) { Write-Present 'outils Linux' 'à jour dans WSL' }
      else { Write-Failed 'outils Linux' "dans Ubuntu : bash $wslPath" }
    }
  }
  Write-Host ''
}

# -------------------------------------------------------------------
#  Résumé
# -------------------------------------------------------------------
Write-Host ("Résumé : {0} déjà présents, {1} installés, {2} ignorés, {3} échecs" -f `
  $Summary.ok, $Summary.installed, $Summary.skipped, $Summary.failed) -ForegroundColor White
if (-not $DryRun) {
  Write-Host 'Fermez et rouvrez vos terminaux / VS Code pour prendre en compte les nouveaux outils.'
  if ($Mode -in @('WSL', 'Both')) {
    Write-Host 'Puis, dans Ubuntu : ./install.sh (extensions, paramètres VS Code et alias).'
  }
}
if ($Summary.failed -gt 0) { exit 1 } else { exit 0 }
