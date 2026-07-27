@echo off
echo Estado del puente Brother ALBARABA
echo.
powershell.exe -NoProfile -Command "$p=Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*brother-print-bridge.ps1*' -and $_.CommandLine -notlike '*Get-CimInstance*' }; if($p){'PUENTE ABIERTO:'; $p|Select-Object ProcessId,CommandLine|Format-List}else{'PUENTE NO ABIERTO'}; 'COLA BROTHER:'; Get-CimInstance Win32_PrintJob -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Brother*' -or $_.Document -like '*ALBARABA*' } | Select Name,JobId,JobStatus,Document | Format-List; 'IMPRESORA PREDETERMINADA:'; Get-CimInstance Win32_Printer | Where-Object Default | Select Name,PortName,WorkOffline,PrinterStatus | Format-List"
pause
