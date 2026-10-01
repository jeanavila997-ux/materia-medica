@echo off
rem Clique duas vezes para (re)configurar esta pasta como clone do GitHub + vault do Obsidian.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar-pasta.ps1" -Destino "%~dp0.." %*
pause
