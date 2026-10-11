# Approved anime reference art — inventory (REFERENCE ONLY, none are game-ready assets)

All five are flat RGB images (no alpha). Provenance: ChatGPT-generated concept art approved by the owner, supplied via chat; method/prompts not recorded in the repo (record before any production use).

| File | Size | What it is | Use |
|---|---|---|---|
| 01_main_hero_turnaround_portrait.png | 1448x1086 | Main Hero sheet: front/side/back turnaround, big portrait, detail crops, palette, logo, sketch; text + panel borders baked in, grey backdrop | identity/costume reference |
| 02_cast_portrait_montage_2x2.png | 1254x1254 | 4 bust portraits: Black male with gold halo, Black female with gold-ringed braids + violet eyes, hooded purple-flame figure, older man. **Not labelled** — roles/names unknown | style/cast reference; owner must say who they are |
| 03_overview_mockup_hero_npc_environment_with_hud.png | 1536x1024 | Composite: wide city mockup with HUD + three bottom panels (hero turnaround, female NPC turnaround, environment) | layout/composition reference |
| 04_imani_black_female_npc_turnaround_portrait.png | 1448x1086 | Imani sheet: front/side/back, large portrait, 5 expression heads, detail crops, palette; text/borders baked in | identity/costume reference |
| 05_neon_district_gameplay_mockup_with_hud.png | 1672x941 | Neon District gameplay mockup (Tram Repair kiosk, Clinic 24, Skybridge 09, elevated tram, crowd, wet street) with HUD, minimap, joystick and prompt painted in | environment/lighting reference; **never a gameplay background** |

## Reference vs game-ready
Everything above is reference. Missing game-ready assets (see ART_INTEGRATION_CHECKLIST in `docs/demo25d/ART_READINESS_REPORT.md` and `PLAYABLE_VISUAL_CHECKPOINT_HANDOFF.md`):
1. Hero and Imani: transparent RGBA idle + >=5 walk frames in front/side/back, identical size and foot anchor, >=288x576; consistent hair/costume across views (the hero's back-view hair differs slightly from the front).
2. Transparent >=512x512 portraits for Hero and Imani (text/border-free); Imani expression set (5 heads shown) as separate transparent portraits if wanted.
3. NPC/background-character art: Tram Repair mechanic, crowd types, umbrella pedestrians, etc. — nothing exists as sprites; the 4 unlabelled faces in file 02 need identification.
4. Neon District layers: far skyline, mid buildings, street floor, foreground/occlusion, plus separate sprites for Tram Repair kiosk, Clinic 24 sign, lamp posts, vehicle, elevated tram, signage and interactive overlays — all painted without HUD. Wet-street reflection plates and a collision-readable ground plane.
5. Provenance/generation notes; an artist-corrected or rigged walk cycle.
