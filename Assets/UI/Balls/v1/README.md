# Ball inventory icons

Ten individual transparent PNG icons, 1254 x 1254, generated with built-in ImageGen from the user's actual Blender models. Final files are in `final/`. Volcano uses the richer second revision based directly on its model render.

- `source-renders/`: isolated Blender captures at 45 degree azimuth and 45 degree elevation; `capture.json` records source objects and successful renders.
- `imagegen-initial/`: first outlined icon generation.
- `previous/`: preserved superseded volcano outline pass.
- `preview.png`: QA contact sheet on alternating light/dark backgrounds; this is not an inventory asset.
- `preview.json`: resolution and alpha spot checks for all ten final files.
- `prompts-and-assets.json`: original generation prompts and source mapping; current upload records are in `roblox-assets.json`.
- `ui-normalized/`: runtime transparent PNGs, 1024 x 1024, uploaded through Studio MCP and used by `Modules/BallCardArt.luau`. `normalization.json` records the exact Euclidean distance transform used to find the largest inscribed circle of the main ball silhouette, center it and scale its diameter to 660 px. Sun's ring and stars do not shrink its main body. Measured body diameters after resampling: 659.32 to 660.63 px.
- `ui-normalized-preview.png`: runtime set on alternating light/dark backgrounds.

The outer stroke was requested at the same 30 px weight for the entire set and reviewed together visually. Generated contour widths are approximate rather than a pixel-exact vector stroke. Original Blender objects, geometry, materials and transforms were not changed; captures used temporary scenes, cameras and lights which were removed after rendering. The source .blend was not overwritten.
