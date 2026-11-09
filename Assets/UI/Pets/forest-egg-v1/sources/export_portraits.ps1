# Package the ImageGen portraits at a common scale and outer stroke width.
param(
    [string] $SourceDir = $PSScriptRoot,
    [string[]] $Pets = @('BloomFox','MoonOwl','GroveGuardian'),
    [ValidateRange(1, 24)] [int] $Stroke = 18
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$references = @([Drawing.Bitmap].Assembly.Location, [Drawing.Rectangle].Assembly.Location, [Runtime.InteropServices.Marshal].Assembly.Location)
foreach ($name in @('System.Private.Windows.GdiPlus.dll', 'System.Private.Windows.Core.dll')) {
    $dependency = Join-Path $PSHOME $name
    if (Test-Path -LiteralPath $dependency) { $references += $dependency }
}
Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class PortraitExport {
    const int Canvas = 512;
    const int ArtSpan = 432;

    static byte[] Read(Bitmap image) {
        var rect = new Rectangle(0, 0, image.Width, image.Height);
        var bits = image.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var bytes = new byte[image.Width * image.Height * 4];
        try {
            for (int y = 0; y < image.Height; y++)
                Marshal.Copy(IntPtr.Add(bits.Scan0, y * bits.Stride), bytes, y * image.Width * 4, image.Width * 4);
        } finally { image.UnlockBits(bits); }
        return bytes;
    }

    static bool Artwork(byte[] bytes, int i) {
        return bytes[i + 3] >= 128 && Math.Max(bytes[i], Math.Max(bytes[i + 1], bytes[i + 2])) > 35;
    }

    static Rectangle Bounds(byte[] bytes, int width, int height, bool onlyArtwork) {
        int left = width, top = height, right = -1, bottom = -1;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int i = (y * width + x) * 4;
                if (onlyArtwork ? !Artwork(bytes, i) : bytes[i + 3] < 128) continue;
                left = Math.Min(left, x);
                right = Math.Max(right, x);
                top = Math.Min(top, y);
                bottom = Math.Max(bottom, y);
            }
        }
        if (right < left || bottom < top) throw new InvalidOperationException("Empty portrait");
        return Rectangle.FromLTRB(left, top, right + 1, bottom + 1);
    }

    public static string Save(string source, string target, int stroke) {
        using (var input = new Bitmap(source))
        using (var resized = new Bitmap(Canvas, Canvas, PixelFormat.Format32bppArgb))
        using (var final = new Bitmap(Canvas, Canvas, PixelFormat.Format32bppArgb)) {
            Rectangle crop = Bounds(Read(input), input.Width, input.Height, true);
            float scale = ArtSpan / (float)Math.Max(crop.Width, crop.Height);
            float x = (Canvas - scale * crop.Width) / 2 - scale * crop.Left;
            float y = (Canvas - scale * crop.Height) / 2 - scale * crop.Top;
            using (var g = Graphics.FromImage(resized)) {
                g.CompositingMode = CompositingMode.SourceCopy;
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(input, new RectangleF(x, y, scale * input.Width, scale * input.Height));
            }

            byte[] art = Read(resized);
            byte[] rgba = new byte[art.Length];
            var mask = new bool[Canvas * Canvas];
            for (int i = 0; i < mask.Length; i++) mask[i] = Artwork(art, i * 4);

            // Rebuild the outside of the generated contour at a fixed radius.
            // The interior retains the generated RGB pixels.
            for (int row = 1; row < Canvas - 1; row++) {
                for (int col = 1; col < Canvas - 1; col++) {
                    int i = row * Canvas + col;
                    if (!mask[i]) continue;
                    Buffer.BlockCopy(art, i * 4, rgba, i * 4, 4);
                    if (mask[i - 1] && mask[i + 1] && mask[i - Canvas] && mask[i + Canvas]) continue;
                    for (int dy = -stroke; dy <= stroke; dy++) {
                        for (int dx = -stroke; dx <= stroke; dx++) {
                            int px = col + dx, py = row + dy;
                            if (px < 0 || px >= Canvas || py < 0 || py >= Canvas) continue;
                            int j = py * Canvas + px;
                            if (mask[j]) continue;
                            double coverage = stroke + .5 - Math.Sqrt(dx * dx + dy * dy);
                            byte opacity = (byte)Math.Round(255 * Math.Max(0, Math.Min(1, coverage)));
                            rgba[j * 4 + 3] = Math.Max(rgba[j * 4 + 3], opacity);
                        }
                    }
                }
            }

            Rectangle body = Bounds(art, Canvas, Canvas, true);
            Rectangle ink = Bounds(rgba, Canvas, Canvas, false);
            if (body.Left - ink.Left != stroke || body.Top - ink.Top != stroke ||
                ink.Right - body.Right != stroke || ink.Bottom - body.Bottom != stroke ||
                ink.Left < 15 || ink.Top < 15 || Canvas - ink.Right < 15 || Canvas - ink.Bottom < 15)
                throw new InvalidOperationException("Stroke width or transparency margin failed");
            var bits = final.LockBits(new Rectangle(0, 0, Canvas, Canvas), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            try {
                for (int row = 0; row < Canvas; row++)
                    Marshal.Copy(rgba, row * Canvas * 4, IntPtr.Add(bits.Scan0, row * bits.Stride), Canvas * 4);
            } finally { final.UnlockBits(bits); }
            final.Save(target, ImageFormat.Png);
            return String.Format("{0}x{0} RGBA, outline {1}px, alpha bounds {2}", Canvas, stroke, ink);
        }
    }
}
'@

$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
$output = Split-Path -Parent $SourceDir
foreach ($pet in $Pets) {
    $result = [PortraitExport]::Save((Join-Path $SourceDir "$pet-imagegen.png"), (Join-Path $output "$pet.png"), $Stroke)
    Write-Output "$pet $result"
}
