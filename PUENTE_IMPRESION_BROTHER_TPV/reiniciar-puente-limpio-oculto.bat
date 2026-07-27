@echo off
echo Reiniciando puente Brother limpio...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*brother-print-bridge.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; Get-CimInstance Win32_PrintJob -ErrorAction SilentlyContinue | Where-Object { $_.Document -like 'ALBARABA etiquetas*' -or $_.Document -eq 'document' } | Remove-CimInstance -ErrorAction SilentlyContinue"
wscript.exe "%~dp0iniciar-puente-oculto.vbs"
echo Puente Brother reiniciado limpio. Puedes cerrar esta ventana.
timeout /t 2 >nul
