param([string]$View='front-three-quarter', [switch]$Roundtrips)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$models=Split-Path -Parent $PSScriptRoot
$pets=@('CoalMole','CinderGecko','EmberRam','BlazeBat','InfernoPhoenix')
$width=if($Roundtrips){1500}else{1500}
$height=if($Roundtrips){940}else{660}
$bitmap=[Drawing.Bitmap]::new($width,$height)
$g=[Drawing.Graphics]::FromImage($bitmap)
$g.Clear([Drawing.Color]::FromArgb(36,42,58))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=[Drawing.Font]::new('Arial',15,[Drawing.FontStyle]::Bold)
$f=[Drawing.StringFormat]::new();$f.Alignment=[Drawing.StringAlignment]::Center
for($i=0;$i -lt 5;$i++){
  $views=@(if($Roundtrips){'roundtrip-blend';'roundtrip-glb';'roundtrip-fbx'}else{$View})
  for($j=0;$j -lt $views.Count;$j++){
    $x=if($Roundtrips){$i*300}else{if($i -lt 3){225+$i*350}else{400+($i-3)*350}}
    $y=if($Roundtrips){$j*310}else{if($i -lt 3){0}else{330}}
    $image=[Drawing.Image]::FromFile((Join-Path $models ($pets[$i]+'/v1/work/'+$views[$j]+'.png')))
    $g.DrawImage($image,$x,$y,300,300);$image.Dispose()
    if(-not $Roundtrips){$g.DrawString($pets[$i],$font,[Drawing.Brushes]::White,[Drawing.RectangleF]::new($x,$y+302,300,28),$f)}
  }
}
$file=if($Roundtrips){'roundtrip-contact.png'}else{$View+'-contact.png'}
$bitmap.Save((Join-Path $PSScriptRoot $file),[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bitmap.Dispose();$font.Dispose();$f.Dispose()
