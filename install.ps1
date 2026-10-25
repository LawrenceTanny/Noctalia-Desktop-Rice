$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "Windows 3D Spatial Wallpaper Setup" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
Write-Host "==> [1/3] Detected Screen Resolution: ${ScreenWidth}x${ScreenHeight}" -ForegroundColor Blue
Write-Host ""

Write-Host "==> [2/3] Checking Required Dependencies:" -ForegroundColor Blue

$LivelyInstalled = $false
$LivelyPaths = @(
    "$env:LOCALAPPDATA\Programs\Lively Wallpaper\Lively.exe",
    "C:\Program Files\Lively Wallpaper\Lively.exe"
)

foreach ($path in $LivelyPaths) {
    if (Test-Path $path) {
        $LivelyInstalled = $true
        break
    }
}

if (-not $LivelyInstalled -and (Get-Command "Lively.exe" -ErrorAction SilentlyContinue)) {
    $LivelyInstalled = $true
}

if ($LivelyInstalled) {
    Write-Host "  [OK] Lively Wallpaper" -ForegroundColor Green
} else {
    Write-Host "  [MISSING] Lively Wallpaper (3D Wallpaper Engine for Windows)" -ForegroundColor Yellow
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        $installPrompt = Read-Host "Install Lively Wallpaper via winget now? [Y/n]"
        if ($installPrompt -ne "n" -and $installPrompt -ne "N") {
            winget install --id rocksdanister.LivelyWallpaper -e --accept-package-agreements --accept-source-agreements
        }
    }
}

Write-Host ""
Write-Host "==> [3/3] Choose Wallpaper to Install:" -ForegroundColor Blue

$WallpapersDir = Join-Path $ScriptDir "assets\wallpapers"
$Wallpapers = Get-ChildItem -Path $WallpapersDir -File | Where-Object {
    $_.Extension -match "\.(jpg|jpeg|png|webp)$" -and $_.Name -notmatch "\.depth\."
} | Sort-Object Name

if ($Wallpapers.Count -eq 0) {
    Write-Host "  No wallpapers found in $WallpapersDir" -ForegroundColor Red
    exit 1
}

for ($i = 0; $i -lt $Wallpapers.Count; $i++) {
    Write-Host "  $($i + 1)) $($Wallpapers[$i].Name)"
}
Write-Host "  s) Skip wallpaper selection"
Write-Host ""

$choice = Read-Host "Select wallpaper [1-$($Wallpapers.Count), Default: 1]"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

if ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $Wallpapers.Count) {
    $SelectedWP = $Wallpapers[[int]$choice - 1]
    Write-Host ""
    Write-Host "Scaling $($SelectedWP.Name) to ${ScreenWidth}x${ScreenHeight}..." -ForegroundColor Cyan

    $BundleDir = Join-Path $ScriptDir "assets\lively-parallax"
    if (-not (Test-Path $BundleDir)) { New-Item -ItemType Directory -Path $BundleDir | Out-Null }

    function Scale-Image ($srcPath, $dstPath, $tw, $th) {
        $src = [System.Drawing.Image]::FromFile($srcPath)
        $bmp = New-Object System.Drawing.Bitmap $tw, $th
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        
        $scale = [Math]::Max($tw / $src.Width, $th / $src.Height)
        $nw = [int][Math]::Round($src.Width * $scale)
        $nh = [int][Math]::Round($src.Height * $scale)
        $x0 = [int](($tw - $nw) / 2)
        $y0 = [int](($th - $nh) / 2)
        
        $g.DrawImage($src, $x0, $y0, $nw, $nh)
        $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $src.Dispose()
        $g.Dispose()
        $bmp.Dispose()
    }

    $outWallpaper = Join-Path $BundleDir "wallpaper.png"
    Scale-Image $SelectedWP.FullName $outWallpaper $ScreenWidth $ScreenHeight

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SelectedWP.FullName)
    $depthPath = Join-Path $WallpapersDir "$baseName.depth.png"
    if (Test-Path $depthPath) {
        Write-Host "  [OK] Found matching 3D depth map." -ForegroundColor Green
        $outDepth = Join-Path $BundleDir "depth.png"
        Scale-Image $depthPath $outDepth $ScreenWidth $ScreenHeight
    }

    $LivelyLibDir = "$env:LOCALAPPDATA\Lively Wallpaper\Library\wallpapers\3D_Spatial_Wallpaper"
    if (Test-Path "$env:LOCALAPPDATA\Lively Wallpaper") {
        if (-not (Test-Path $LivelyLibDir)) { New-Item -ItemType Directory -Path $LivelyLibDir | Out-Null }
        Copy-Item -Path "$BundleDir\*" -Destination $LivelyLibDir -Recurse -Force
        Write-Host "  [OK] Copied 3D wallpaper bundle to Lively Wallpaper library." -ForegroundColor Green
    }

    $LivelyBin = ""
    foreach ($path in $LivelyPaths) {
        if (Test-Path $path) {
            $LivelyBin = $path
            break
        }
    }

    if ($LivelyBin -ne "") {
        Start-Process -FilePath $LivelyBin -ArgumentList "setwp", "--file", "`"$BundleDir`"" -ErrorAction SilentlyContinue
        Write-Host "  [OK] Dispatched wallpaper to Lively Wallpaper." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  To activate in Lively Wallpaper:"
        Write-Host "  1. Open Lively Wallpaper."
        Write-Host "  2. Drag and drop this folder into Lively:"
        Write-Host "     $BundleDir"
    }
}

Write-Host ""
Write-Host "Windows setup completed." -ForegroundColor Green
Write-Host "Move your cursor across the desktop to view the 3D parallax effect."
Write-Host ""
