param(
  [string]$PrinterName = "Brother QL-820NWB (Copiar 1)"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$doc = New-Object System.Drawing.Printing.PrintDocument
$doc.PrinterSettings.PrinterName = $PrinterName
$doc.DocumentName = "ALBARABA PRUEBA DIRECTA"
$doc.PrintController = New-Object System.Drawing.Printing.StandardPrintController
$doc.DefaultPageSettings.PaperSize = New-Object System.Drawing.Printing.PaperSize("ALBARABA_62x100",244,394)
$doc.DefaultPageSettings.Margins = New-Object System.Drawing.Printing.Margins(0,0,0,0)
$doc.DefaultPageSettings.Landscape = $false
$handler = [System.Drawing.Printing.PrintPageEventHandler]{
  param($sender,$e)
  $g=$e.Graphics
  $g.PageUnit=[System.Drawing.GraphicsUnit]::Millimeter
  $black=[System.Drawing.Brushes]::Black
  $red=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(190,40,40))
  $f1=New-Object System.Drawing.Font('Arial',16,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
  $f2=New-Object System.Drawing.Font('Arial',9,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
  $f3=New-Object System.Drawing.Font('Arial',22,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
  $g.DrawString('PRUEBA ALBARABA',$f1,$black,3,8)
  $g.DrawString('Si sale esta etiqueta, la Brother imprime bien.',$f2,$black,3,25)
  $g.DrawString(('Fecha: '+(Get-Date -Format 'dd/MM/yyyy HH:mm')),$f2,$black,3,38)
  $g.DrawString('OK',$f3,$red,3,55)
  $red.Dispose(); $f1.Dispose(); $f2.Dispose(); $f3.Dispose()
}
$doc.add_PrintPage($handler)
Write-Host "Imprimiendo prueba directa en: $PrinterName" -ForegroundColor Cyan
$doc.Print()
$doc.Dispose()
Write-Host "Enviada prueba directa. Si no sale, es driver/impresora. Si sale, el fallo es app/nube/cola." -ForegroundColor Green
Read-Host "Pulsa ENTER para cerrar"
