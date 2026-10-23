"""Encode Studio MCP timeline captures into local MP4 comparison videos."""
import base64
from pathlib import Path
import subprocess
import sys

project = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project / ".tools/video-runtime"))
import imageio_ffmpeg

encoder = imageio_ffmpeg.get_ffmpeg_exe()
output = project / "assets/ui/hatch-videos"
output.mkdir(parents=True, exist_ok=True)
for variant in (1, 2, 3):
    folder = project / f".tools/hatch-recordings/v{variant}"
    for index in range(44):
        encoded = folder / f"frame-{index:05d}.b64"
        image = folder / f"frame-{index:05d}.jpg"
        if encoded.exists():
            image.write_bytes(base64.b64decode(encoded.read_text(encoding="utf-8").strip(), validate=True))
        assert image.exists(), f"Missing recorded Studio frame: {variant}:{index}"
    video = output / f"variant-{variant}.mp4"
    subprocess.run([
        encoder, "-y", "-v", "error", "-framerate", "12", "-i", str(folder / "frame-%05d.jpg"),
        "-vf", "scale=1280:720:flags=lanczos,minterpolate=fps=30:mi_mode=mci:mc_mode=aobmc:me_mode=bidir",
        "-c:v", "libx264", "-crf", "19", "-preset", "medium", "-pix_fmt", "yuv420p", "-an",
        "-movflags", "+faststart", str(video),
    ], check=True)
    reader = imageio_ffmpeg.read_frames(str(video), pix_fmt="rgb24")
    metadata = next(reader)
    assert metadata["size"] == (1280, 720)
    frames = sum(1 for _ in reader)
    assert frames >= 90, "Video capture incomplete"
    print(f"Variant {variant}: {frames} frames, {video.stat().st_size} bytes, {video}", flush=True)
