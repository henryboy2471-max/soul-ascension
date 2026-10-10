# Premium art checkpoint — status: BLOCKED on art tooling (no substitute art produced)

Owner direction: the procedural renderer (`tools/art25d/chargen.py`) and the procedural city art are **rejected as final art**. If high-quality assets cannot be produced, report the limitation instead of substituting procedural art.

## Limitation (verified this session)
- No local image-generation model or painting tool is available in this environment, and I cannot hand-paint at anime-illustration quality in code.
- The only generation tool reachable is the Higgsfield MCP (image models such as Soul 2.0, Soul Cast, Nano Banana Pro). Its account balance is **0 credits on the free plan**, and project rules say generating art with a paid service needs the owner's explicit approval. So nothing was generated.
- Therefore the checkpoint (hero, Black female NPC, city environment at gameplay size) has **not** been produced. The previous procedural frames remain on `demo/neon-district-2.5d` only as architecture/prototype, labelled rejected for final art.

## What is ready so the checkpoint can be done fast once art exists
- Working 2.5D engine on `demo/neon-district-2.5d`: four-direction movement, depth, collisions, occlusion, camera, dialogue, puzzle, interiors, mobile controls (tests 41/41, browser 12/12, 19 regression suites green).
- Sprite loader expects per character `front/side/back` strips (5 frames x 144x288) and a 512 px portrait; it can be pointed at higher-resolution assets (frame size is one constant).
- Existing tooling for sheets: `tools/slice_sheet.py`, `tools/build_spriteframes.gd`, `tools/import_*.sh`.

## Needed from the owner (pick one)
1. **Approve a paid generation budget** (e.g. Higgsfield credits) for the checkpoint only: 1 hero turnaround, 1 Black female NPC turnaround, 1 city environment. I would then: generate concept + turnaround sheets, remove backgrounds, slice into walk frames, wire them in at gameplay size, capture 1280x720 screenshots (front/side/back movement) and a before/after comparison, and stop for your approval.
2. **Supply art** from an illustrator/studio (turnaround sheets, walk-cycle frames, layered environment plates); I integrate and test.
3. **Another approved generator/tool** I can run here.

## Quality bar I will hold the checkpoint to (not "tests pass")
Anime proportions (~7 heads), detailed eyes, defined nose, natural Black hairstyles, proper hands, believable clothing layers; each character recognisably an individual; no stretched noses or overlapping limbs; walk/turn/idle fluid. Environment: varied architecture, strong perspective, readable neon signage, wet pavement/puddles/rain, street furniture and vehicles, foreground/background depth, dramatic lighting. Consistency risk to flag: AI image tools do not guarantee identical characters across views/frames; walk cycles may need manual cleanup or a rigged approach (layered parts + skeletal animation) rather than per-frame generation.
