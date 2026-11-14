# Package the selected imagegen masters into native icon sizes. Windows/.NET only.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskApp = Join-Path $taskRoot 'myhome_flutter'
$taskMaster = [System.Drawing.Image]::FromFile((Join-Path $taskRoot 'design/branding/selected/app-icon-master.png'))
$taskWordmark = [System.Drawing.Image]::FromFile((Join-Path $taskRoot 'design/branding/selected/wordmark-master.png'))

function New-BrandBitmap($source, [int]$size, [int]$height = $size, [double]$inset = 0) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#07565B'))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $margin = [int]($size * $inset)
        $graphics.DrawImage($source, $margin, $margin, $size - 2 * $margin, $height - 2 * $margin)
    } finally { $graphics.Dispose() }
    return ,$bitmap
}

function Save-BrandPng($source, [int]$size, [string]$relativePath, [int]$height = $size, [double]$inset = 0) {
    $path = Join-Path $taskApp $relativePath
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    $bitmap = New-BrandBitmap $source $size $height $inset
    try { $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png) }
    finally { $bitmap.Dispose() }
}

try {
    Save-BrandPng $taskMaster 256 'assets/branding/app-icon.png'
    Save-BrandPng $taskWordmark 768 'assets/branding/wordmark.png' 512
    Save-BrandPng $taskWordmark 240 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png' 160
    Save-BrandPng $taskWordmark 480 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png' 320
    Save-BrandPng $taskWordmark 720 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png' 480
    foreach ($entry in @(@('mdpi',48), @('hdpi',72), @('xhdpi',96), @('xxhdpi',144), @('xxxhdpi',192))) {
        Save-BrandPng $taskMaster $entry[1] "android/app/src/main/res/mipmap-$($entry[0])/ic_launcher.png"
    }
    # Additional padding keeps the mark inside Android adaptive-icon masks.
    Save-BrandPng $taskMaster 432 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png' 432 .10
    foreach ($platform in @('ios','macos')) {
        $folder = "$platform/Runner/Assets.xcassets/AppIcon.appiconset"
        $manifest = Get-Content (Join-Path $taskApp "$folder/Contents.json") -Raw | ConvertFrom-Json
        foreach ($image in $manifest.images) {
            if ($image.filename) {
                $size = [int]([double]($image.size -split 'x')[0] * [double]($image.scale -replace 'x',''))
                Save-BrandPng $taskMaster $size "$folder/$($image.filename)"
            }
        }
    }
    Save-BrandPng $taskMaster 32 'web/favicon.png'
    foreach ($size in @(192,512)) {
        Save-BrandPng $taskMaster $size "web/icons/Icon-$size.png"
        Save-BrandPng $taskMaster $size "web/icons/Icon-maskable-$size.png"
    }
    # ICO supports PNG-compressed frames; include small and HiDPI resolutions.
    $sizes = @(16,24,32,48,64,128,256)
    $frames = @()
    foreach ($size in $sizes) {
        $bitmap = New-BrandBitmap $taskMaster $size
        $stream = [System.IO.MemoryStream]::new()
        try {
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $frames += ,$stream.ToArray()
        } finally { $bitmap.Dispose(); $stream.Dispose() }
    }
    $file = [System.IO.File]::Create((Join-Path $taskApp 'windows/runner/resources/app_icon.ico'))
    $writer = [System.IO.BinaryWriter]::new($file)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {
            $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
            $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
            $offset += $frames[$i].Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame) }
    } finally { $writer.Dispose(); $file.Dispose() }
} finally { $taskMaster.Dispose(); $taskWordmark.Dispose() }
Write-Output 'Selected brand assets and Android/iOS/Web/macOS/Windows icons generated.'
