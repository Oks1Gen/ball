$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$output = Split-Path -Parent $PSScriptRoot
$canvas = [Drawing.Bitmap]::new(1040, 750)
$graphics = [Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([Drawing.Color]::FromArgb(38, 48, 66))
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [Drawing.Font]::new('Arial', 19, [Drawing.FontStyle]::Bold)
$names = @('CloverBunny', 'AcornSquirrel', 'BloomFox', 'MoonOwl', 'GroveGuardian')
$labels = @('Clover Bunny', 'Acorn Squirrel', 'Bloom Fox', 'Moon Owl', 'Grove Guardian')
$format = [Drawing.StringFormat]::new()
$format.Alignment = [Drawing.StringAlignment]::Center
for ($i=0; $i -lt 5; $i++) {
    $x = if ($i -lt 3) { 20 + $i * 340 } else { 190 + ($i-3) * 340 }
    $y = if ($i -lt 3) { 12 } else { 380 }
    $image = [Drawing.Image]::FromFile((Join-Path $output ($names[$i] + '.png')))
    $graphics.DrawImage($image, $x, $y, 320, 320)
    $graphics.DrawString($labels[$i], $font, [Drawing.Brushes]::White, [Drawing.RectangleF]::new($x, $y+322, 320, 40), $format)
    $image.Dispose()
}
$canvas.Save((Join-Path $output 'preview.png'), [Drawing.Imaging.ImageFormat]::Png)
$format.Dispose(); $font.Dispose(); $graphics.Dispose(); $canvas.Dispose()
