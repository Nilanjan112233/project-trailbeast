# Prompt: Create Milestone 1 Greybox

Copy the prompt below into a coding task when ready.

---

Work only inside `D:\PROJECTS\Game\Project-Trailbeast`.

This is a new local Git repository for an original lightweight Android game. Do not modify, copy files from, or commit anything in `D:\PROJECTS\Game`. Do not create a GitHub repository or Git remote. Do not stage or commit files.

Read these files completely before making changes:

- `README.md`
- `docs/GAME_DESIGN.md`
- `docs/ROADMAP.md`
- `docs/TECHNICAL_PLAN.md`

Implement only **Milestone 1 - Five-minute greybox**. The goal is to test whether escorting a living caravan creature and handling one threat in multiple ways is understandable and enjoyable. This is not a request to build the full game.

## Engine and project configuration

- Use Godot 4.7.2 Standard and GDScript.
- Create a new Godot project in this repository.
- Use the GL Compatibility renderer.
- Use a 1280 x 720 logical landscape viewport with responsive `canvas_items` scaling.
- Use code-drawn placeholder visuals only. Do not download assets, fonts, audio, plugins, or packages.
- Keep the project Android-ready, but do not create release signing material.
- Use the working Android package name `com.nilan.trailbeastprototype`.

The Godot console executable currently available on this computer is:

`C:\Users\nilan\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`

## Required playable result

Create one side-view test map that can be completed in approximately five minutes or less.

### Shellback

- Draw an original, readable giant travelling creature using Godot 2D drawing primitives.
- It begins on the left and moves slowly toward an exit on the right.
- Give it health, a visible health bar, and `ALIVE`, `PANICKED`, and `DEAD` states, even if panic has only a minimal Milestone 1 use.
- Tapping the Shellback or a large HUD button toggles stop/resume.
- Reaching the exit while alive wins the map.
- Reaching zero health loses the map.

### Warden

- Draw a small original Warden figure with simple shapes. It must not be a reused stickman from the old project.
- Tapping valid ground moves the Warden horizontally to that location.
- Keep movement and interaction readable on a phone.
- The Warden cannot leave the map bounds.

### Wolf

- Add exactly one wolf threat with these explicit states: `IDLE`, `INVESTIGATE`, `STALK`, `ATTACK`, `SNARED`, and `DEAD`.
- Its intent must be visually readable through colour, icon, pose, or movement.
- If it reaches the Shellback, it attacks at a visible contact moment rather than reducing health early.
- The wolf must ignore invalid or freed targets safely.

### Two tools and one module

- **Bait:** place it on valid ground. The wolf should investigate it when appropriate. Bait expires after a limited time or use.
- **Snare:** place it on valid ground. A wolf entering it becomes `SNARED` temporarily. It must later recover unless killed.
- **Bolt launcher:** a Shellback-mounted module that the player activates manually. It fires a visible projectile and applies damage only on impact.
- Use clear cooldown indicators and large touch targets.

The player must be able to finish by killing the wolf with the launcher or by using bait and snare to delay/redirect it long enough to escape. Do not force one solution.

### Interface

- Show Shellback health, current state, stop/resume, bait, snare, bolt launcher, restart, and a concise status message.
- Disable actions when they are unavailable and show why through text or cooldown presentation.
- Provide mouse input equivalents so the greybox is testable in the editor.
- Avoid tiny text and buttons.

### Restart and safety

- Restart must remove old projectiles, bait, snares, wolf, Warden, and Shellback state cleanly.
- Victory and defeat must be mutually exclusive and announced only once.
- No late projectile or delayed callback may overwrite the final result.

## Architecture

- Separate gameplay state from procedural drawing.
- Use reusable scenes for Shellback, Warden, Wolf, trap/tool objects, and projectile/module objects.
- Prefer simple one-dimensional movement and distance checks. Do not introduce navigation meshes, rigid-body simulation, a plugin, or a large framework.
- Use typed GDScript where it improves safety.
- Keep constants and exported tuning values easy for a beginner to find.
- Add short comments only where the reason is not obvious.

## Automated verification

Create a headless smoke test under `tests/` that checks at minimum:

- Required scenes load and instantiate.
- Shellback health clamps and death is final.
- Wolf state transitions are legal.
- Bait attracts the wolf.
- Snare holds and releases the wolf.
- Bolt damage occurs on projectile impact rather than at firing time.
- Victory and defeat cannot both occur.
- Restart produces fresh valid entities and removes transient objects.
- Invalid/freed targets do not cause errors.

Run and report these separately:

1. Godot parser/import validation using `--headless --editor --quit`.
2. The headless smoke-test script.
3. An integrated headless scene run for a bounded number of frames.
4. `git diff --check`.
5. `git status --short`.

Do not claim that headless checks prove visual quality, touch usability, frame rate, Android behaviour, or enjoyment. Those require user testing.

## Documentation

Update `README.md` and add a concise status document describing:

- What was actually implemented.
- Controls and tunable values.
- Files created or modified.
- Checks run with exact exit codes.
- Checks still requiring visual and Android testing.
- No claims beyond available evidence.

## Strict scope exclusions

Do not add:

- Additional maps, enemies, tools, or modules.
- Inventory, crafting, shops, skill trees, or permanent progression.
- Save files.
- Multiplayer or networking.
- Ads, analytics, purchases, accounts, or online services.
- Final art, music, or downloaded assets.
- Procedural map generation.
- Story cutscenes or dialogue systems.

When complete, provide a concise implementation report and a manual visual checklist. Leave all changes unstaged and uncommitted for review.

---
