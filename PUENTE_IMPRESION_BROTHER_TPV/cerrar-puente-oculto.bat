@echo off
echo Cerrando puente Brother oculto...
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*brother-print-bridge.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo Listo.
pause
