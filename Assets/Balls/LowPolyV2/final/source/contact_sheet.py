"""Build comparison sheets: reference row above render row, five balls per sheet (runs inside Blender)."""
import os

import bpy
import numpy as np

REF = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\References\2026-10-31-low-poly-v2"
OUT = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\LowPolyV2\previews"
SIZE = 360
SHEETS = globals().get("SHEETS") or [["01", "02", "03", "04", "05"], ["06", "07", "08", "09", "10"]]
# Newer references that replace a pack image: path and the front-view crop (x0, y0, x1, y1), top-left origin.
REF_CROPS = {
    "08": (os.path.join(os.path.dirname(OUT), "references", "08-storm-views.webp"), (33, 0, 483, 450)),
}


def load_px(path, crop=None):
    img = bpy.data.images.load(path, check_existing=False)
    if crop is None:
        img.scale(SIZE, SIZE)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, img.channels)
    bpy.data.images.remove(img)
    if crop is not None:
        x0, y0, x1, y1 = crop
        # Pixel rows go bottom-up; nearest-neighbour resample of the crop to SIZE x SIZE.
        rows = (h - y1 + (np.arange(SIZE) + 0.5) * (y1 - y0) / SIZE).astype(int)
        cols = (x0 + (np.arange(SIZE) + 0.5) * (x1 - x0) / SIZE).astype(int)
        px = px[rows][:, cols]
    if px.shape[2] == 3:
        px = np.concatenate([px, np.ones((SIZE, SIZE, 1), np.float32)], axis=2)
    return px[:, :, :4]


refs = {f[:2]: (os.path.join(REF, f), None) for f in os.listdir(REF) if f.endswith(".png")}
refs.update(REF_CROPS)
written = []
for n, codes in enumerate(SHEETS):
    sheet = np.ones((SIZE * 2, SIZE * len(codes), 4), np.float32)
    for i, code in enumerate(codes):
        # Blender pixel rows go bottom-up: top row of the sheet is the reference.
        sheet[SIZE:, i * SIZE:(i + 1) * SIZE] = load_px(*refs[code])
        sheet[:SIZE, i * SIZE:(i + 1) * SIZE] = load_px(os.path.join(OUT, "review_%s.png" % code))
    name = "compare_%s.png" % "-".join((codes[0], codes[-1]))
    out = bpy.data.images.new(name, SIZE * len(codes), SIZE * 2, alpha=True)
    out.pixels.foreach_set(sheet.ravel())
    out.filepath_raw = os.path.join(OUT, name)
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    written.append(os.path.join(OUT, name))

result = {"sheets": written}
