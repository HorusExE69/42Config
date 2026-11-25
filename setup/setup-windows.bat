@echo off
rem 42 VS Code config - double-cliquez pour installer les outils manquants.
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1" %*
echo.
pause
