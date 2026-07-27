@echo off
echo Iniciando puente Brother en segundo plano...
wscript.exe "%~dp0iniciar-puente-oculto.vbs"
echo Listo. Puedes cerrar esta ventana.
timeout /t 2 >nul
