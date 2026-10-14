# SOUL ASCENSION — Neon District source panels v2

This ZIP contains all **15 original, unscaled RGBA PNG source panels**, not finished game plates. The file bytes match manifest.json. Do not use chat-image renditions: attach this ZIP directly. Existing approved sky remains in the repo.

Assembly order: far_left + far_right; mid_left + mid_center + mid_right; near_left + near_center + near_right; street_left + street_center + street_right; foreground_1 + foreground_2 + foreground_3; tram alone. The three added transition panels give mid, near and street sufficient horizontal source width for uniform downscaling and blending at the target sizes. Avoid repeated architecture.

Targets (w×h): far 2550×720; mid 2700×615; near 3450×690; street 3750×630; foreground 4200×210; stalled tram 1050×234. Use native source pixels: stitch, crop, paint seams, and reduce uniformly where needed; never upscale/stretch. The validator currently enforces a 3% crop ceiling for native outputs. The source images may need substantial *component* cropping during the artwork assembly; document component crop rectangles and the final mosaic size honestly. Do not say that a stitched plate was generated in one pass.

Street-left has RAMEN and platform; street-center is a calm service corridor; street-right has relay wall and dark plaza. The street_center (alpha 222–250) and street_right (alpha 3–252) outputs need intentional opacity cleanup for the final world plate. The tram has transparent margins and should be framed within the target canvas. Foreground is painted mist source artwork; no code effect or contract exception requested.

For provenance, record each component filename, SHA-256, actual original dimensions, crop/scale/position and seam-painting method, plus the final pre-output mosaic dimensions. If extending the validator for composed artwork, retain the exact size, no-upscale, 3% final crop, edge alpha, palette, HUD-safe and prop-slot checks. Treat this as source-only until the complete validator and manual visual review pass. No gameplay integration, merge or deployment.

Prompt set summary: independent premium anime Neon District side-scroll art in electric blue and violet, restrained magenta/gold; transparent skyline, middle architecture, near elevated tracks, wet street with RAMEN/station and service/plaza, sparse ground mist, dark stalled tram. No baked characters or HUD. Each image was separately generated with its layer and transition role.
