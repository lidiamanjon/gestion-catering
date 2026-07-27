param(
  [string]$PrinterName = "Brother QL-820NWB Printer",
  [int]$IntervalSeconds = 3
)

$ErrorActionPreference = "Stop"
$ApiKey = "AIzaSyCKCSg5n6cBVikz1NSYdxI2y5GiD2yqaqk"
$DbUrl = "https://albaraba-gestion-2026-default-rtdb.firebaseio.com"
$ConfigDir = Join-Path $env:APPDATA "AlbarabaPrintBridge"
$ConfigFile = Join-Path $ConfigDir "config.json"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

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
  $order = [uri]::EscapeDataString('"status"')
  $equal = [uri]::EscapeDataString('"pending"')
  $url = "$DbUrl/print_jobs.json?orderBy=$order&equalTo=$equal&auth=$token"
  $data = Invoke-RestMethod -Method Get -Uri $url
  if ($null -eq $data) { return @() }
  $jobs = @()
  $data.PSObject.Properties | ForEach-Object {
    $jobs += [pscustomobject]@{ id=$_.Name; data=$_.Value }
  }
  return $jobs | Sort-Object { $_.data.created_at }
}

function Get-EdgePath {
  $paths = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  foreach($p in $paths){ if(Test-Path -LiteralPath $p){ return $p } }
  throw "No encuentro Microsoft Edge. Instalalo o cambia el script para usar Chrome."
}

function Print-HtmlJob($job,$token,$printerName) {
  $id = $job.id
  Invoke-FirebasePatch "print_jobs/$id" $token @{ status="printing"; started_at=(Get-Date).ToString("o"); bridge=$env:COMPUTERNAME }
  $file = Join-Path $env:TEMP ("albaraba-label-" + $id + ".html")
  [IO.File]::WriteAllText($file, [string]$job.data.html, [Text.UTF8Encoding]::new($false))
  $edge = Get-EdgePath
  $uri = (New-Object System.Uri($file)).AbsoluteUri
  $proc = Start-Process -FilePath $edge -ArgumentList @("--kiosk-printing","--new-window",$uri) -PassThru -WindowStyle Minimized
  Start-Sleep -Seconds 8
  try {
    if(!$proc.HasExited){
      $proc.CloseMainWindow() | Out-Null
      Start-Sleep -Seconds 1
      if(!$proc.HasExited){ $proc.Kill() }
    }
  } catch {}
  Invoke-FirebasePatch "print_jobs/$id" $token @{ status="done"; done_at=(Get-Date).ToString("o"); printer=$printerName }
  Write-Host ("Impresa etiqueta/trabajo " + $id) -ForegroundColor Green
}

$cfg = Load-BridgeConfig
if ($cfg.printer) { $PrinterName = $cfg.printer }
Write-Host "=== Puente impresion ALBARABA -> Brother ===" -ForegroundColor Cyan
Write-Host "Modo: usuario y contrasena de la app." -ForegroundColor Green
Write-Host "Impresora esperada/predeterminada: $PrinterName" -ForegroundColor Yellow
Write-Host "IMPORTANTE: pon esa Brother como impresora predeterminada en Windows." -ForegroundColor Yellow

$auth = $null
while ($true) {
  try {
    if ($null -eq $auth) { $auth = Login-Firebase $cfg }
    $jobs = Get-PendingJobs $auth.idToken
    foreach($job in $jobs){ Print-HtmlJob $job $auth.idToken $PrinterName }
  } catch {
    Write-Host ("Error puente: " + $_.Exception.Message) -ForegroundColor Red
    if ($_.Exception.Message -like "*Firebase no acepta el inicio de sesion*") {
      Write-Host "Si escribiste mal el usuario o contrasena, cierra esta ventana, borra este archivo y abre el puente otra vez:" -ForegroundColor Yellow
      Write-Host $ConfigFile -ForegroundColor Yellow
    }
    $auth = $null
    Start-Sleep -Seconds 8
  }
  Start-Sleep -Seconds $IntervalSeconds
}
