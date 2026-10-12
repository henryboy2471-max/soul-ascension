# SOUL ASCENSION development workflow (owner-established)

## Roles
- **ChatGPT**: writes the official stories and development plans for all 10 episodes of Season 1. Plans are the source of truth for story, characters, locations, objectives, revelations, encounters, rewards and cliffhangers.
- **Owner**: approves each episode plan before implementation starts and approves visuals/merges.
- **Claude**: implements an approved plan in Godot - gameplay, exploration, missions, NPC interactions, cinematics, anime visuals, tests. Claude does NOT invent or replace storylines. If a plan is ambiguous or technically impractical, Claude asks or proposes a technical adjustment in `IMPLEMENTATION.md` and waits; it never silently rewrites story.
- While Claude implements episode N, ChatGPT prepares episode N+1.

## Rules
1. Season 1 has exactly 10 episodes (1-1 ... 1-10). No additions without owner approval.
2. Implementation of an episode starts only after BOTH: the official plan exists in the repo (or is given in chat) AND the owner says it is approved. Until then: no code, data or art for that episode.
3. Premium anime adventure direction: exploration, movement, NPC interaction, story missions, cinematics first; combat as one part.
4. Approved work is never overwritten: each episode lives on its own branch; completed/approved milestones are frozen (frozen branch or tag); changes to Episodes 1-2 happen on separate polish branches and merge only after the full regression and owner approval.
5. Never merge into `main`, never publish/deploy, without explicit owner approval.
6. A test is reported as passed only if it actually ran; untested and blocked items are listed separately.

## Repository layout and branches
| Purpose | Convention |
|---|---|
| Official story plan (ChatGPT) | `docs/episodes/episode-NN/STORY_PLAN.md` (+ optional `ASSETS_AND_BEATS.md`) added by the owner/ChatGPT; Claude does not edit these files |
| Approval record | `docs/episodes/episode-NN/APPROVAL.md`: date, approved commit of the plan, any owner conditions (written by Claude from the owner's message, quoting it) |
| Claude implementation notes | `docs/episodes/episode-NN/IMPLEMENTATION.md`: mapping plan -> code/data, technical adjustments requested, test results, known gaps |
| Implementation branch | `episode-N/<slug>` created from the current release-candidate branch (Episode 2 used `episode-2/under-the-violet-rain`); milestones M1 data, M2 exploration, M3 battle/boss, M4 ending as before, each approved before the next |
| Freeze | after approval, branch `episode-N/<slug>-frozen` (the remote refuses tags) |
| Polish / fixes | `dev/<topic>` or `art/<topic>` branches; merged into the release candidate only after the full regression and owner approval |
| Release candidate | `episode-2/under-the-violet-rain` today (to be renamed/continued by the owner's choice); `main` untouched until the owner approves |

## Per-episode checklist (Claude)
1. Read the approved plan; list ambiguities and technical constraints in `IMPLEMENTATION.md`; ask before assuming.
2. M1: mission data (`MissionDefs`) + pinned tests; Episode 1-2 golden traces must stay identical.
3. M2: exploration/zones/NPCs/objectives/cutscenes from the plan; focused tests; browser check at 1280x720, 844x390, 667x375 (`tools/qa/`).
4. M3: encounters/boss; art through the approved visual direction (samples approved first); texture variants per `docs/WEB_TEXTURE_COMPARISON.md`.
5. M4: ending, rewards once, Codex, next-episode card matching the plan's cliffhanger.
6. Full regression + browser matrix; Android items listed as blocked until an SDK/device exists.
7. Owner review of visuals; merge only on approval.

## Current state
- Episodes 1-2 implemented and approved (release candidate branch).
- Episode 3: waiting for the official ChatGPT plan and owner approval. Claude's earlier drafts (`docs/EPISODE3_STORY_PROPOSAL.md`, `docs/SEASON1_PLAN.md`) are non-canonical reference only.
- In the meantime Claude continues Episode 1-2 testing and visual polish on `dev/*` branches using existing approved assets; the Lantern Quarter and Mira expression samples (`art/lantern-quarter-mira-samples`) await owner approval and are not integrated.
