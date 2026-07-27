@echo off
title ALBARABA - PRUEBA DIRECTA BROTHER
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0imprimir-prueba-directa.ps1"
