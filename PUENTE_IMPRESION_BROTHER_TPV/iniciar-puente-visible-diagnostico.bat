@echo off
title ALBARABA - PUENTE BROTHER DIAGNOSTICO
cd /d "%~dp0"
echo ==========================================
echo  PUENTE BROTHER ALBARABA - MODO VISIBLE
echo ==========================================
echo.
echo Si hay error, esta ventana NO se cerrara.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brother-print-bridge.ps1"
echo.
echo ==========================================
echo El puente se ha cerrado o ha dado error.
echo Haz foto de esta ventana y mandasela a Codex.
echo ==========================================
pause
