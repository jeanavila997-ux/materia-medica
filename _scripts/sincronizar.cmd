@echo off
rem Clique duas vezes para sincronizar a Materia Medica com o GitHub.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sincronizar.ps1" %*
pause
