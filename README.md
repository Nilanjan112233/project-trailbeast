# Project Trailbeast

Project Trailbeast is the working title for a lightweight, original Android strategy game. The title is temporary and is not intended to be the eventual Play Store name.

## The simple explanation

The player guides a giant travelling creature called a Shellback. A small group of survivors lives on its back and carries a living Hearthseed that may restore their homeland.

The Shellback functions as a moving fortress. At camps, the player equips exactly three modules from four choices (Bolt Launcher, Armour Screen, Storage Rack, Snare Rack). The player inspects a wilderness route graph (2560x1440 world units), selects connected routes, and escorts the fortress through travel encounters, deciding whether to fight while moving or halt and defend.

## Current status

- Current experimental prototype direction: **Moving Fortress Map Prototype** on branch `codex/moving-fortress-prototype`.
- Milestone 1 baseline preserved at commit `055dfb5` (`Build Trailbeast Android greybox`).
- Milestone 2A lane/boar/noise experiment cleanly archived at local branch `codex/milestone-2a-lane-experiment` (commit `5f5f7b6`).
- **Moving Fortress Systems Implemented**:
  - **Enlarged Wilderness Map (2560x1440)**: Procedural top-down code-drawn terrain with Northern Woodland Vale, Southern Ruined Watchpost, central River Crossing, Narrow Pass gorge, and Exit Haven.
  - **Bounded Camera Controller**: Touch-drag panning clamped to map boundaries, and a large thumb-friendly `RE-CENTER` button (`>= 52px`).
  - **Topological Route Graph**: Discrete connected nodes with rewards, threat ratings, and terrain effects. Re-visiting completed nodes or selecting disconnected destinations is prohibited.
  - **Shellback Moving Fortress**: Stationary at camps; moves only after confirmed route; follows curved waypoints; can be halted and resumed mid-travel; panics on attack.
  - **Modular Workshop**: Equips exactly 3 modules from 4 choices (Bolt Launcher, Armour Screen, Storage Rack, Snare Rack) exclusively at camps. All equipped modules are procedurally drawn on the Shellback.
  - **Combat & Encounters**: Woodland (lone wolf) vs. Watchpost (raider ambush) vs. Final Pass (combined assault). Enemies visibly telegraph attacks. Bolt projectiles apply damage at impact. Armour screen passively mitigates 40% incoming damage.
  - **Balanced Fortress Defense**: The Shellback has 250 HP, wolf bites deal 12 damage, raider strikes deal 9 damage, and the Bolt Launcher reloads in 3 seconds. All four legal loadouts have a verified route to victory.
  - **River Crossing Decision**: Choice to spend wood for repair (+60 HP) or keep the wood and face an extra Final Pass raider.
  - **Contextual Onboarding**: Replaced 6-page manual with 5 sequential contextual teaching prompts.
- **Verification Evidence**:
  - Deterministic headless test suite passing with **269/269 assertions** (exit code 0), including real threat, trap, projectile, hold, and complete-route simulations.
  - Integrated bounded scene runner simulating 180 frames completes cleanly (exit code 0).
  - Android Debug export generates a signed arm64-v8a package (`28,473,753 bytes` / 27.15 MiB) with the original Shellback/Hearthseed app icon.
- All Moving Fortress prototype changes remain unstaged and uncommitted for review.

## Documents

- `docs/GAME_DESIGN.md` - the complete game concept and rules.
- `docs/ROADMAP.md` - development roadmap and experimental milestones.
- `docs/TECHNICAL_PLAN.md` - lightweight Godot and Android constraints.
- `docs/MOVING_FORTRESS_PROTOTYPE_STATUS.md` - Moving Fortress prototype implementation details, parameters, test evidence, and playtest checklist.
- `docs/MILESTONE_1_STATUS.md` - Milestone 1 baseline status report.
- `docs/MILESTONE_2A_STATUS.md` - Archived Milestone 2A experiment status report.
