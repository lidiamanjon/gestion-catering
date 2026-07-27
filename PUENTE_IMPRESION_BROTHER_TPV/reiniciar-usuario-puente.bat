@echo off
echo Borrando usuario guardado del puente Brother...
del "%APPDATA%\AlbarabaPrintBridge\config.json" /Q 2>nul
echo Listo. Ahora abre iniciar-puente-impresion-brother.bat y te pedira el usuario otra vez.
pause
