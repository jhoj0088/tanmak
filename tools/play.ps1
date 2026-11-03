# 탄막 RPG: 융합 프로토콜 실행기 (PLAY.cmd 가 부른다)
# 1) Godot 4.3 을 찾는다: GODOT_PATH → 전에 받아 둔 것 → PATH → 다운로드/바탕화면/Program Files
#    (이 게임은 4.3 으로 만들었다. 4.4 이상으로 열면 .uid 파일이 잔뜩 생긴다)
# 2) 없으면 물어보고 공식 Godot 4.3 을 %LOCALAPPDATA%\TanmakRPG\godot 에 받는다 (약 60MB, 한 번만)
# 3) 처음 한 번 리소스를 불러온 뒤(import) 게임을 띄운다
param([string]$Godot = '', [switch]$Editor)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$cacheDir = Join-Path $env:LOCALAPPDATA 'TanmakRPG\godot'
$version = '4.3-stable'

function Find-Godot([string]$ver) {
    if ($env:GODOT_PATH -and (Test-Path -LiteralPath $env:GODOT_PATH)) { return $env:GODOT_PATH }
    $command = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command -and ($command.Source -like "*$ver*" -or $ver -eq '4')) { return $command.Source }
    $patterns = @(
        (Join-Path $cacheDir "Godot_v$ver*_win64.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot*\Godot_v$ver*_win64.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot_v$ver*_win64.exe"),
        (Join-Path $env:USERPROFILE "Desktop\Godot*\Godot_v$ver*_win64.exe"),
        (Join-Path $env:USERPROFILE "Desktop\Godot_v$ver*_win64.exe"),
        (Join-Path $env:ProgramFiles "Godot*\Godot_v$ver*_win64.exe")
    )
    foreach ($p in $patterns) {
        # 콘솔 창이 같이 뜨는 *_console.exe 는 건너뛴다
        $found = Get-ChildItem -Path $p -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*console*' } | Sort-Object Name -Descending | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return ''
}

if (-not $Godot) { $Godot = Find-Godot '4.3' }
if (-not $Godot) {
    $other = Find-Godot '4'
    Write-Host '이 컴퓨터에서 Godot 4.3 을 찾지 못했습니다.'
    if ($other) { Write-Host "다른 버전은 있습니다: $other  (N 을 고르면 이걸로 실행)" }
    $answer = Read-Host "공식 Godot $version (약 60MB)을 받아서 실행할까요? (Y/N)"
    if ($answer -notmatch '^[Yy]') {
        if ($other) { $Godot = $other } else { throw 'Godot 4.3 을 설치하거나 GODOT_PATH 에 Godot.exe 경로를 넣은 뒤 다시 실행하세요.' }
    }
}
if (-not $Godot) {
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    $zip = Join-Path $cacheDir 'godot.zip'
    $url = "https://github.com/godotengine/godot/releases/download/$version/Godot_v$version`_win64.exe.zip"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "받는 중: $url"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $cacheDir -Force
    Remove-Item -LiteralPath $zip
    $Godot = Find-Godot '4.3'
    if (-not $Godot) { throw "받은 파일에서 Godot.exe 를 찾지 못했습니다: $cacheDir" }
}
Write-Host "Godot: $Godot"

$quoted = '"' + $projectRoot + '"'
if (-not $Editor) {
    # 새로 받은 그림·소리·글꼴을 게임이 읽을 수 있게 먼저 불러온다 (처음엔 조금 걸린다)
    $importRun = Start-Process -FilePath $Godot -ArgumentList '--headless','--path',$quoted,'--editor','--import','--quit' -Wait -PassThru -WindowStyle Hidden
    if ($importRun.ExitCode -ne 0) { throw "리소스 불러오기(import) 실패: 종료 코드 $($importRun.ExitCode)" }
    Start-Process -FilePath $Godot -ArgumentList '--path',$quoted
} else {
    Start-Process -FilePath $Godot -ArgumentList '--path',$quoted,'--editor'
}
