param(
  [string]$PrinterName = "Brother QL-820NWB (Copiar 1)",
  [int]$IntervalSeconds = 3
)

$ErrorActionPreference = "Stop"
$ApiKey = "AIzaSyCKCSg5n6cBVikz1NSYdxI2y5GiD2yqaqk"
$DbUrl = "https://albaraba-gestion-2026-default-rtdb.firebaseio.com"
$ConfigDir = Join-Path $env:APPDATA "AlbarabaPrintBridge"
$ConfigFile = Join-Path $ConfigDir "config.json"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
$BridgeVersion = "20260729-etiqueta-62x42-qr-cad3"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
try { Add-Type -AssemblyName System.Web } catch {}

function Save-BridgeConfig {
  Write-Host "Primer arranque del puente Brother ALBARABA." -ForegroundColor Cyan
  Write-Host "Introduce un usuario de la app ALBARABA creado en Firebase Authentication." -ForegroundColor Yellow
  $email = Read-Host "Email de la app"
  $secure = Read-Host "Contrasena" -AsSecureString
  $enc = ConvertFrom-SecureString $secure
  @{ mode="password"; email=$email; password=$enc; printer=$PrinterName; created_at=(Get-Date).ToString("o") } |
    ConvertTo-Json |
    Set-Content -LiteralPath $ConfigFile -Encoding UTF8
  Write-Host "Configuracion guardada en $ConfigFile" -ForegroundColor Green
}

function Load-BridgeConfig {
  if (!(Test-Path -LiteralPath $ConfigFile)) { Save-BridgeConfig }
  $cfg = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
  if (!$cfg.email -or !$cfg.password) {
    Write-Host "No hay usuario/clave guardados. Creo configuracion nueva." -ForegroundColor Yellow
    Remove-Item -LiteralPath $ConfigFile -Force -ErrorAction SilentlyContinue
    Save-BridgeConfig
    $cfg = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
  }
  return $cfg
}

function Get-PlainPassword($encrypted) {
  $secure = ConvertTo-SecureString $encrypted
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Get-FirebaseErrorDetail($Exception) {
  $detail = $Exception.Message
  try {
    $stream = $Exception.Response.GetResponseStream()
    if ($stream) {
      $reader = New-Object System.IO.StreamReader($stream)
      $raw = $reader.ReadToEnd()
      if ($raw) {
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.error.message) { $detail = $parsed.error.message }
      }
    }
  } catch {}
  return $detail
}

function Login-Firebase($cfg) {
  $password = Get-PlainPassword $cfg.password
  $body = @{ email=$cfg.email; password=$password; returnSecureToken=$true } | ConvertTo-Json
  $url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey"
  try { return Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Body $body }
  catch {
    $detail = Get-FirebaseErrorDetail $_.Exception
    throw "Firebase no acepta el inicio de sesion de '$($cfg.email)': $detail. Ejecuta reiniciar-usuario-puente.bat si quieres cambiarlo."
  }
}

function Invoke-FirebasePatch($path,$token,$obj) {
  $json = $obj | ConvertTo-Json -Depth 20
  Invoke-RestMethod -Method Patch -Uri "$DbUrl/$path.json?auth=$token" -ContentType "application/json" -Body $json | Out-Null
}

function Get-PendingJobs($token) {
  $url = "$DbUrl/print_jobs.json?auth=$token"
  try { $data = Invoke-RestMethod -Method Get -Uri $url }
  catch {
    $detail = Get-FirebaseErrorDetail $_.Exception
    throw "No puedo leer la cola de impresion en Firebase: $detail"
  }
  if ($null -eq $data) { return @() }
  $jobs = @()
  $data.PSObject.Properties | ForEach-Object {
    if ($_.Value.status -eq "pending") { $jobs += [pscustomobject]@{ id=$_.Name; data=$_.Value } }
  }
  return $jobs | Sort-Object { $_.data.created_at }
}

function Get-PrintQueueStats($token) {
  $url = "$DbUrl/print_jobs.json?auth=$token"
  try { $data = Invoke-RestMethod -Method Get -Uri $url } catch { return [pscustomobject]@{ total=0; pending=0; printing=0; done=0; error=0 } }
  if ($null -eq $data) { return [pscustomobject]@{ total=0; pending=0; printing=0; done=0; error=0 } }
  $total=0;$pending=0;$printing=0;$done=0;$errorCount=0
  $data.PSObject.Properties | ForEach-Object {
    $total++
    switch ($_.Value.status) { "pending"{$pending++} "printing"{$printing++} "done"{$done++} "error"{$errorCount++} }
  }
  return [pscustomobject]@{ total=$total; pending=$pending; printing=$printing; done=$done; error=$errorCount }
}

function Resolve-BrotherPrinterName($preferred) {
  $printers = @(Get-CimInstance Win32_Printer | Select-Object Name,Default,PortName)
  if ($preferred -and ($printers | Where-Object { $_.Name -eq $preferred })) { return $preferred }
  $brw = $printers | Where-Object { ($_.Name -like "*QL-820*" -or $_.Name -like "*Brother*") -and $_.PortName -notlike "WSD-*" } | Select-Object -First 1
  if ($brw) { return $brw.Name }
  $any = $printers | Where-Object { $_.Name -like "*QL-820*" -or $_.Name -like "*Brother*" } | Select-Object -First 1
  if ($any) { return $any.Name }
  return $preferred
}

function Get-QueueIds($printerName) {
  try {
    if (Get-Command Get-PrintJob -ErrorAction SilentlyContinue) {
      return @(Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.ID })
    }
  } catch {}
  return @()
}

function Wait-QueueCleared($printerName,$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $now = @(Get-QueueIds $printerName)
    if ($now.Count -eq 0) { return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}
function Clear-StuckJobsForDocument($printerName,$docName) {
  try {
    if (Get-Command Get-PrintJob -ErrorAction SilentlyContinue) {
      Get-PrintJob -PrinterName $printerName -ErrorAction SilentlyContinue |
        Where-Object { $_.DocumentName -eq $docName -or $_.DocumentName -like "ALBARABA etiquetas*" } |
        ForEach-Object { Remove-PrintJob -PrinterName $printerName -ID $_.ID -ErrorAction SilentlyContinue }
    }
  } catch {}
  try {
    Get-CimInstance Win32_PrintJob -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like ("*" + $printerName + "*") -and ($_.Document -eq $docName -or $_.Document -like "ALBARABA etiquetas*") } |
      Remove-CimInstance -ErrorAction SilentlyContinue
  } catch {}
}

function Clean-Text($s) {
  if($null -eq $s){ return "" }
  $t = [string]$s
  try { $t = [System.Web.HttpUtility]::HtmlDecode($t) } catch {}
  $t = [regex]::Replace($t,'<[^>]+>',' ')
  $t = [regex]::Replace($t,'\s+',' ').Trim()
  return $t
}

function Parse-LabelsFromHtml($html) {
  $labels = @()
  if(!$html){ return $labels }
  $text = [string]$html
  $parts = [regex]::Split($text,'<div class="label[^"]*"[^>]*>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if($parts.Count -le 1){
    $parts = [regex]::Split($text,'<div[^>]+class="[^"]*\blabel\b[^"]*"[^>]*>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  }
  for($idx=1; $idx -lt $parts.Count; $idx++){
    $block = $parts[$idx]
    $next = [regex]::Match($block,'<div class="label|<div class="no-print"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if($next.Success){ $block = $block.Substring(0,$next.Index) }
    $producto = Clean-Text(([regex]::Match($block,'<div[^>]+class="[^"]*\btitle\b[^"]*"[^>]*>([\s\S]*?)</div>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $destino = Clean-Text(([regex]::Match($block,'<div[^>]+class="[^"]*\bdest\b[^"]*"[^>]*>([\s\S]*?)</div>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $lote = Clean-Text(([regex]::Match($block,'LOTE:\s*([\s\S]*?)</div>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $cad = Clean-Text(([regex]::Match($block,'<div[^>]+class="[^"]*\bcad\b[^"]*"[^>]*>([\s\S]*?)</div>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $creada = Clean-Text(([regex]::Match($block,'CREADA:\s*([^<]+)',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $hecha = Clean-Text(([regex]::Match($block,'HECHA POR:\s*([^<]+)',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value)
    $qr = ([regex]::Match($block,'<img[^>]+src="(data:image\/[^"]+)"',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value
    if(!$qr){ $qr = ([regex]::Match($block,'data-qr="([^"]*)"',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value }
    if(!$cad){ $cad = Clean-Text(([regex]::Match($block,'data-cad="([^"]*)"',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Groups[1].Value) }
    if(!$producto){ $producto='Etiqueta' }
    if(!$destino){ $destino='NEVERA' }
    if(!$cad){ $cad=(Get-Date).AddDays(5).ToString('dd/MM/yy') }
    if(!$creada){ $creada=(Get-Date).ToString('dd/MM/yyyy') }
    $labels += [pscustomobject]@{ producto=$producto; destino=$destino; lote=$lote; cad=$cad; creada=$creada; hecha=$hecha; qr=$qr }
  }
  return $labels
}

function Labels-FromJob($job) {
  $out = @()
  try {
    if($job.data.labels) {
      foreach($x in @($job.data.labels)) {
        $producto = Clean-Text $x.producto
        if(!$producto){ $producto='Etiqueta' }
        $destino = Clean-Text $x.destino
        if(!$destino){ $destino='NEVERA' }
        $cad = Clean-Text $x.cad
        if(!$cad){ $cad=(Get-Date).AddDays(5).ToString('dd/MM/yy') }
        $creada = Clean-Text $x.creada
        if(!$creada){ $creada=(Get-Date).ToString('dd/MM/yyyy') }
        $out += [pscustomobject]@{
          producto=$producto
          destino=$destino
          lote=(Clean-Text $x.lote)
          cad=$cad
          creada=$creada
          hecha=(Clean-Text $x.hecha)
          qr=([string]$x.qr)
        }
      }
    }
  } catch {}
  if($out.Count -gt 0){ return $out }
  return @(Parse-LabelsFromHtml $job.data.html)
}

function Fit-Font($g,$text,$maxPt,$minPt,$style,$maxWidthMm) {
  for($pt=$maxPt; $pt -ge $minPt; $pt--) {
    $f = New-Object System.Drawing.Font('Arial',$pt,$style,[System.Drawing.GraphicsUnit]::Point)
    $w = $g.MeasureString($text,$f).Width
    if($w -le $maxWidthMm) { return $f }
    $f.Dispose()
  }
  return New-Object System.Drawing.Font('Arial',$minPt,$style,[System.Drawing.GraphicsUnit]::Point)
}

function Print-LabelsDirect($job,$token,$printerName) {
  $id = $job.id
  $labels = @(Labels-FromJob $job)
  if(!$labels -or $labels.Count -eq 0) {
    Invoke-FirebasePatch "print_jobs/$id" $token @{ status="error"; error="No pude leer etiquetas del HTML para impresion directa"; error_at=(Get-Date).ToString("o"); printer=$printerName }
    Write-Host "ERROR: no pude leer etiquetas del trabajo $id" -ForegroundColor Red
    return
  }

  Invoke-FirebasePatch "print_jobs/$id" $token @{ status="printing"; started_at=(Get-Date).ToString("o"); bridge=$env:COMPUTERNAME; method="direct-dotnet"; printer=$printerName }

  $doc = New-Object System.Drawing.Printing.PrintDocument
  $doc.PrinterSettings.PrinterName = $printerName
  $doc.DocumentName = "ALBARABA etiquetas $id"
  $doc.PrintController = New-Object System.Drawing.Printing.StandardPrintController
  $doc.DefaultPageSettings.PaperSize = New-Object System.Drawing.Printing.PaperSize("ALBARABA_62x42",244,165)
  $doc.DefaultPageSettings.Margins = New-Object System.Drawing.Printing.Margins(0,0,0,0)
  $doc.DefaultPageSettings.Landscape = $false
  $script:LabelIndex = 0

  $handler = [System.Drawing.Printing.PrintPageEventHandler]{
    param($sender,$e)
    $g = $e.Graphics
    $g.PageUnit = [System.Drawing.GraphicsUnit]::Millimeter
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $black = [System.Drawing.Brushes]::Black
    $gray = [System.Drawing.Brushes]::DimGray
    $red = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(190,40,40))
    $blue = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28,70,140))
    $small = New-Object System.Drawing.Font('Arial',4.4,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
    $mid = New-Object System.Drawing.Font('Arial',6.2,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
    $cadFont = New-Object System.Drawing.Font('Arial',12,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
    $l = $labels[$script:LabelIndex]
    $hasQr = -not [string]::IsNullOrWhiteSpace($l.qr)
    $textWidth = $(if($hasQr){ 43 } else { 56 })
    $titleFont = Fit-Font $g $l.producto 11 7 ([System.Drawing.FontStyle]::Bold) $textWidth
    $g.DrawString('ALBARABA SL',$small,$gray,2.5,1.5)
    $g.DrawString($l.producto,$titleFont,$black,2.5,4.4)
    $g.DrawString(($l.destino).ToUpper(),$mid,$blue,2.5,13.2)
    if($l.lote){ $g.DrawString(('LOTE: ' + $l.lote),$mid,$black,2.5,18.2) }
    $g.DrawString(('CREADA: ' + $l.creada),$small,$gray,2.5,23.2)
    if($l.hecha){ $g.DrawString(('HECHA POR: ' + $l.hecha),$small,$gray,2.5,26.2) }
    $g.DrawString('CONSUMIR ANTES:',$small,$gray,2.5,30.2)
    $g.DrawString($l.cad,$cadFont,$red,24,28.4)
    if($hasQr){
      try{
        $b64 = [regex]::Replace([string]$l.qr,'^data:image\/[^;]+;base64,','')
        $bytes = [Convert]::FromBase64String($b64)
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $img = [System.Drawing.Image]::FromStream($ms)
        $g.DrawImage($img,48,4,11.5,11.5)
        $img.Dispose(); $ms.Dispose()
        $g.DrawString('TRAZA',$small,$gray,48.2,16.2)
      } catch {
        $g.DrawString('QR',$mid,$black,50,8)
      }
    }
    $titleFont.Dispose(); $red.Dispose(); $blue.Dispose(); $small.Dispose(); $mid.Dispose(); $cadFont.Dispose()
    $script:LabelIndex++
    $e.HasMorePages = ($script:LabelIndex -lt $labels.Count)
  }
  $doc.add_PrintPage($handler)

  try {
    Write-Host ("Imprimiendo directo sin navegador: " + $labels.Count + " etiqueta(s) en " + $printerName) -ForegroundColor Yellow
    $doc.Print()
    $cleared = Wait-QueueCleared $printerName 35
    if(!$cleared){
      Clear-StuckJobsForDocument $printerName $doc.DocumentName
      Invoke-FirebasePatch "print_jobs/$id" $token @{ status="done"; done_at=(Get-Date).ToString("o"); printer=$printerName; method="direct-dotnet"; warning="La Brother imprimio o recibio el trabajo, pero Windows dejo aviso/cola atascada; el puente la limpio para no bloquear siguientes etiquetas." }
      Write-Host "AVISO: Windows dejo la cola/aviso atascado. Lo he limpiado para seguir imprimiendo." -ForegroundColor Yellow
      return
    }
    Invoke-FirebasePatch "print_jobs/$id" $token @{ status="done"; done_at=(Get-Date).ToString("o"); printer=$printerName; method="direct-dotnet" }
    Write-Host "Trabajo terminado correctamente." -ForegroundColor Green
  } catch {
    Invoke-FirebasePatch "print_jobs/$id" $token @{ status="error"; error=("Fallo impresion directa: " + $_.Exception.Message); error_at=(Get-Date).ToString("o"); printer=$printerName; method="direct-dotnet" }
    Write-Host ("ERROR impresion directa: " + $_.Exception.Message) -ForegroundColor Red
  } finally {
    $doc.Dispose()
  }
}

$cfg = Load-BridgeConfig
if ($cfg.printer) { $PrinterName = $cfg.printer }
$PrinterName = Resolve-BrotherPrinterName $PrinterName
Write-Host "=== Puente impresion ALBARABA -> Brother ===" -ForegroundColor Cyan
Write-Host "Version puente: $BridgeVersion" -ForegroundColor DarkGray
Write-Host "Modo: IMPRESION DIRECTA, SIN EDGE, SIN NAVEGADOR." -ForegroundColor Green
Write-Host "Usuario guardado: $($cfg.email)" -ForegroundColor Green
Write-Host "Archivo de configuracion: $ConfigFile" -ForegroundColor DarkGray
Write-Host "Impresora esperada/predeterminada: $PrinterName" -ForegroundColor Yellow
try {
  $printers = Get-CimInstance Win32_Printer | Where-Object { $_.Name -like '*Brother*' -or $_.Name -like '*QL*' } | Select-Object Name,Default,WorkOffline,PrinterStatus,PortName,DriverName
  $printers | Format-Table -AutoSize
} catch {}

Write-Host ""
Write-Host "Probando inicio de sesion en Firebase..." -ForegroundColor Cyan
try {
  $auth = Login-Firebase $cfg
  Write-Host "CONECTADO A FIREBASE. Puente escuchando etiquetas pendientes." -ForegroundColor Green
  Write-Host "Deja esta ventana abierta. Si la cierras, no imprime automaticamente." -ForegroundColor Yellow
} catch {
  Write-Host ("ERROR DE INICIO: " + $_.Exception.Message) -ForegroundColor Red
  Write-Host "Para cambiar usuario/contrasena, ejecuta reiniciar-usuario-puente.bat y despues vuelve a abrir este puente." -ForegroundColor Yellow
  Read-Host "Pulsa ENTER para cerrar"
  exit 1
}

$loopCount = 0
while ($true) {
  try {
    if ($null -eq $auth) { $auth = Login-Firebase $cfg }
    $loopCount++
    if ($loopCount -eq 1 -or ($loopCount % 5) -eq 0) {
      $stats = Get-PrintQueueStats $auth.idToken
      Write-Host ("[" + (Get-Date -Format "HH:mm:ss") + "] Cola Brother: " + $stats.pending + " pendiente(s), " + $stats.printing + " imprimiendo, " + $stats.done + " hecha(s), " + $stats.error + " error(es), " + $stats.total + " total.") -ForegroundColor Cyan
    }
    $jobs = Get-PendingJobs $auth.idToken
    foreach($job in $jobs){
      Write-Host ("Trabajo pendiente encontrado: " + $job.id) -ForegroundColor Yellow
      Print-LabelsDirect $job $auth.idToken $PrinterName
    }
  } catch {
    Write-Host ("Error puente: " + $_.Exception.Message) -ForegroundColor Red
    $auth = $null
    Start-Sleep -Seconds 8
  }
  Start-Sleep -Seconds $IntervalSeconds
}
