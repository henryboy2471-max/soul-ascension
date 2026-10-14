# Request to ChatGPT: painted tram track / support (new authored art needed)

Status: REQUEST ONLY. Nothing here is production artwork. Henry has not approved the corrected composition. No procedural scenery may stand in for this art, and the hover must not be relabelled intentional.

## Problem (measured, not guessed)
`prop_tram_stalled` is a contract prop at logical (635, 340), 700x156. Its wheels touch down at logical **y 494** (plate_street row 291; the lowest opaque prop row is 231 of 234). The street art has no rail or support at that height: the nearest ground is where the platform pillars and benches stand, at logical **y ~600** (row ~450, measured by eye from the composite, +-10 px), so the tram floats about 106 logical px (about 159 delivered px) above it. A tram cannot be moved without changing the contract, so the track has to be painted under the wheels.

## Region to author (delivered px, plate_street coordinates; 1 logical px = 1.5)
| item | value |
|---|---|
| insert rectangle | x 862-2092 (width 1230), rows 280-470 (height 190) = logical x 575-1395, y 487-613 |
| tram span inside it | x 952-2002 (logical 635-1335); 60 logical px of track continue past each tram end |
| rail top surface (wheel contact) | **row 291** = insert row 11, as a straight horizontal line |
| wheel contact patches (x) | 1049-1086, 1155-1184 (left bogie); 1771-1801, 1869-1906 (right bogie) |
| ground line the supports must reach (platform pillar bases) | row ~450 = insert row 170 |

## What to paint
A side-view elevated tram guideway: continuous rail head and track bed along the full 1230 px, a solid beam or girder under it, and piers or supports running down to the ground line (row ~450). It must look physically load-bearing, with the rail exactly at row 291 so the wheels sit on it. It must run off both ends into transparent or fade into the existing station (left) and service corridor (right) so no hard cut shows.
Style: premium anime 2D Neon District, electric blue and violet storm mood, restrained magenta and gold (a few small gold lights only). Dark and calm: mean luminance <= 0.30, low detail, no bright neon tubes. Wet-metal sheen is fine.
Not allowed: any tram, characters, text, logos, HUD, gameplay markers, or green #00FF00.

## Delivery
- RGBA PNG, transparent above the rail head and wherever no structure exists, unscaled native generation, **at least 1230 px wide** (a wider panel with the track in a horizontal band and the rest transparent is fine; it will be cropped and only downscaled, never enlarged). Use the template guides to align, but deliver WITHOUT the guide lines drawn in.
- Provide a `<name>.provenance.json` (tool, prompt summary, original dimensions, sha256) like the other source panels.
- I will composite it into plate_street at (862, 280) (the 190 px insert replaces rows 280-470 only where the new art is opaque), re-run the validator (palette, HUD, prop slots) and the camera and seam checks, and show new composites. Nothing is integrated until Henry approves.

## Files
- `tram_track_region_GUIDE_ONLY.png`: the street plate with the tram and the region marked
- `tram_track_insert_TEMPLATE_GUIDES_ONLY_1230x190.png`: transparent canvas of the exact insert size with guide lines

## Option B (owner decision, needs approval)
Instead of new art, lower the tram contract position by about 106 logical px (y 340 -> ~446) so its wheels meet the ground line. Its wheels would then sit at y ~600, below the walking lane (515-585), and the tram would cover the station pillars, so it is not made here and would need a fresh composition review.
