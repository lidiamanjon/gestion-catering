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
$BridgeVersion = "20260727-cola-windows-segura"

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

function Get-FirebaseErrorDetail {
  param($Exception)
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
  try {
    return Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Body $body
  } catch {
    $detail = Get-FirebaseErrorDetail $_.Exception
    throw "Firebase no acepta el inicio de sesion de '$($cfg.email)': $detail. Revisa que el usuario exista en Authentication y que tenga Email/Password."
  }
}

function Invoke-FirebasePatch($path,$token,$obj) {
  $json = $obj | ConvertTo-Json -Depth 20
  Invoke-RestMethod -Method Patch -Uri "$DbUrl/$path.json?auth=$token" -ContentType "application/json" -Body $json | Out-Null
}

function Get-PendingJobs($token) {
  # Leemos la cola completa y filtramos aqui.
  # Evita errores 400 de Firebase cuando no hay indice .indexOn para "status".
  $url = "$DbUrl/print_jobs.json?auth=$token"
  try {
    $data = Invoke-RestMethod -Method Get -Uri $url
  } catch {
    $detail = Get-FirebaseErrorDetail $_.Exception
    throw "No puedo leer la cola de impresion en Firebase: $detail"
  }
  if ($null -eq $data) { return @() }
  $jobs = @()
  $data.PSObject.Properties | ForEach-Object {
    if ($_.Value.status -eq "pending") {
      $jobs += [pscustomobject]@{ id=$_.Name; data=$_.Value }
    }
  }
  return $jobs | Sort-Object { $_.data.created_at }
}

function Get-PrintQueueStats($token) {
  $url = "$DbUrl/print_jobs.json?auth=$token"
  try {
    $data = Invoke-RestMethod -Method Get -Uri $url
  } catch {
    $detail = Get-FirebaseErrorDetail $_.Exception
    throw "No puedo revisar la cola de impresion en Firebase: $detail"
  }
  if ($null -eq $data) {
    return [pscustomobject]@{ total=0; pending=0; printing=0; done=0; error=0 }
  }
  $total = 0
  $pending = 0
  $printing = 0
  $done = 0
  $errorCount = 0
  $data.PSObject.Properties | ForEach-Object {
    $total++
    switch ($_.Value.status) {
      "pending" { $pending++ }
      "printing" { $printing++ }
      "done" { $done++ }
      "error" { $errorCount++ }
    }
  }
  return [pscustomobject]@{ total=$total; pending=$pending; printing=$printing; done=$done; error=$errorCount }
}
function Get-EdgePath {
  $paths = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  foreach($p in $paths){ if(Test-Path -LiteralPath $p){ return $p } }
  throw "No encuentro Microsoft Edge. Instalalo o cambia el script para usar Chrome."
}

function Resolve-BrotherPrinterName($preferred) {
  try {
    $printers = @(Get-CimInstance Win32_Printer | Select-Object Name,Default)
    if ($preferred -and ($printers | Where-Object { $_.Name -eq $preferred })) { return $preferred }
    $defaultBrother = $printers | Where-Object { $_.Default -and $_.Name -like "*Brother*" } | Select-Object -First 1
    if ($defaultBrother) { return $defaultBrother.Name }
    $anyBrother = $printers | Where-Object { $_.Name -like "*QL-820*" -or $_.Name -like "*Brother*" } | Select-Object -First 1
    if ($anyBrother) { return $anyBrother.Name }
  } catch {}
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

function Wait-JobInWindowsQueue($printerName,$beforeIds,$timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $now = @(Get-QueueIds $printerName)
    $new = @($now | Where-Object { $beforeIds -notcontains $_ })
    if ($new.Count -gt 0) { return $true }
    Start-Sleep -Seconds 1
  }
  return $false
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

function Print-HtmlJob($job,$token,$printerName) {
  $id = $job.id
  Invoke-FirebasePatch "print_jobs/$id" $token @{ status="printing"; started_at=(Get-Date).ToString("o"); bridge=$env:COMPUTERNAME }
  $file = Join-Path $env:TEMP ("albaraba-label-" + $id + ".html")
  [IO.File]::WriteAllText($file, [string]$job.data.html, [Text.UTF8Encoding]::new($false))
  $edge = Get-EdgePath
  $uri = (New-Object System.Uri($file)).AbsoluteUri
  $profileDir = Join-Path $env:TEMP "albaraba-edge-print-profile"
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
  $beforeQueue = @(Get-QueueIds $printerName)
  $args = @(
    "--kiosk-printing",
    "--disable-print-preview",
    "--no-first-run",
    "--disable-features=PrintCompositorLPAC",
    "--user-data-dir=$profileDir",
    "--new-window",
    $uri
  )
  $proc = Start-Process -FilePath $edge -ArgumentList $args -PassThru -WindowStyle Minimized
  $queued = Wait-JobInWindowsQueue $printerName $beforeQueue 25
  if (-not $queued) {
    Invoke-FirebasePatch "print_jobs/$id" $token @{ status="error"; error="No entro ningun trabajo en la cola real de Windows. Revisa impresora predeterminada, dialogos de Edge y controlador Brother."; error_at=(Get-Date).ToString("o"); printer=$printerName }
    Write-Host ("NO IMPRESA " + $id + ": no entro en la cola real de Windows.") -ForegroundColor Red
    try {
      if(!$proc.HasExited){ $proc.CloseMainWindow() | Out-Null }
    } catch {}
    return
  }
  Write-Host ("Trabajo " + $id + " detectado en cola Windows de " + $printerName + ". Esperando salida...") -ForegroundColor Yellow
  $cleared = Wait-QueueCleared $printerName 120
  try {
    if(!$proc.HasExited){
      $proc.CloseMainWindow() | Out-Null
      Start-Sleep -Seconds 1
      if(!$proc.HasExited){ $proc.Kill() }
    }
  } catch {}
  if (-not $cleared) {
    Invoke-FirebasePatch "print_jobs/$id" $token @{ status="error"; error="El trabajo entro en cola Windows pero no salio en 120 segundos. Revisa comunicacion PC-Brother, rollo y errores del controlador."; error_at=(Get-Date).ToString("o"); printer=$printerName }
    Write-Host ("ERROR IMPRESION " + $id + ": quedo atascado en cola Windows.") -ForegroundColor Red
    return
  }
  Invoke-FirebasePatch "print_jobs/$id" $token @{ status="done"; done_at=(Get-Date).ToString("o"); printer=$printerName }
  Write-Host ("Trabajo terminado en cola Windows " + $id) -ForegroundColor Green
}

$cfg = Load-BridgeConfig
if ($cfg.printer) { $PrinterName = $cfg.printer }
$PrinterName = Resolve-BrotherPrinterName $PrinterName
Write-Host "=== Puente impresion ALBARABA -> Brother ===" -ForegroundColor Cyan
Write-Host "Version puente: $BridgeVersion" -ForegroundColor DarkGray
Write-Host "Modo: usuario y contrasena de la app." -ForegroundColor Green
Write-Host "Usuario guardado: $($cfg.email)" -ForegroundColor Green
Write-Host "Archivo de configuracion: $ConfigFile" -ForegroundColor DarkGray
Write-Host "Impresora esperada/predeterminada: $PrinterName" -ForegroundColor Yellow
Write-Host "IMPORTANTE: pon esa Brother como impresora predeterminada en Windows." -ForegroundColor Yellow
try {
  $defaultPrinter = Get-CimInstance Win32_Printer | Where-Object { $_.Default } | Select-Object -First 1 -ExpandProperty Name
  if ($defaultPrinter) { Write-Host "Impresora predeterminada real de Windows: $defaultPrinter" -ForegroundColor Yellow }
} catch {}

Write-Host ""
Write-Host "Probando inicio de sesion en Firebase..." -ForegroundColor Cyan
try {
  $auth = Login-Firebase $cfg
  Write-Host "CONECTADO A FIREBASE. Puente escuchando etiquetas pendientes." -ForegroundColor Green
  Write-Host "Deja esta ventana abierta. Si la cierras, no imprime automaticamente." -ForegroundColor Yellow
} catch {
  Write-Host ("ERROR DE INICIO: " + $_.Exception.Message) -ForegroundColor Red
  Write-Host ""
  Write-Host "No voy a pedirte el email en bucle." -ForegroundColor Yellow
  Write-Host "Para cambiar usuario/contrasena, ejecuta primero reiniciar-usuario-puente.bat y despues vuelve a abrir este puente." -ForegroundColor Yellow
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
      Print-HtmlJob $job $auth.idToken $PrinterName
    }
  } catch {
    Write-Host ("Error puente: " + $_.Exception.Message) -ForegroundColor Red
    $auth = $null
    Start-Sleep -Seconds 8
  }
  Start-Sleep -Seconds $IntervalSeconds
}



