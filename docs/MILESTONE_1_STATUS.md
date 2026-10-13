# Milestone 1: Five-Minute Greybox Implementation Status

## 1. Overview and Implementation Summary

Milestone 1 implements an original, lightweight greybox escort prototype in Godot 4.7.2 Standard (GL Compatibility renderer, 1280x720 landscape canvas with safe letterboxing on wider displays) to evaluate the core design loop: escorting a living caravan creature (Shellback) while managing a predator threat (Wolf) using non-combat tools (Bait, Snare) and a caravan module (Bolt Launcher).

### Implemented Systems:

1. **Shellback Escort Objective (`scenes/shellback.tscn`, `scripts/shellback.gd`, `scripts/shellback_visual.gd`)**:
   - Original procedural visual: segmented mossy carapace, underbelly, quadruped pillar legs with procedural walk bob, caravan platform with packs, and a glowing Hearthseed brazier.
   - States: `ALIVE`, `PANICKED`, `DEAD`.
   - Health: 100 HP, clamped between 0 and 100. Death is irreversible and final.
   - Overhead dynamic health bar and status display.
   - Direct tap-to-toggle or HUD button toggle for Halt / Resume.
   - Panic state triggers upon predator attack (temporary speed boost, non-haltable until panic subsides).
   - Exit waypoint trigger (crossing x=1120 alive wins the run).

2. **Trail Warden Scout Helper (`scenes/warden.tscn`, `scripts/warden.gd`, `scripts/warden_visual.gd`)**:
   - Original procedural figure: hooded traveler/scout with cowl, leather tunic, boots, satchel, and walking staff with beacon charm (not a stickman).
   - Tap-to-move horizontal ground travel with facing direction and bounds clamping (x between 40 and 1240).

3. **Wolf Predator Threat (`scenes/wolf.tscn`, `scripts/wolf.gd`, `scripts/wolf_visual.gd`)**:
   - Explicit finite state machine: `IDLE`, `INVESTIGATE`, `STALK`, `ATTACK`, `SNARED`, `DEAD`.
   - High intent readability: distinct poses (patrol, low crouch sniff, stalk bristles, attack rearing lunge, snared struggle, fallen corpse) with visual intent badges and eye color cues.
   - Contact-timed damage delivery: attack damage (20 HP) occurs at a distinct contact strike moment (after 0.55s wind-up) with a visible crimson slash effect, rather than instantly upon entering range.
   - Safe target handling: guards against invalid or freed targets safely.
   - Scent attraction towards bait and susceptibility to snares.

4. **Tools and Caravan Module**:
   - **Bait (`scenes/bait.tscn`, `scripts/trap.gd`, `scripts/trap_visual.gd`)**: Placed on ground, emits aromatic scent rings, draws wolf into `INVESTIGATE` state, consumed after wolf reaches it or expires after 16s. Cooldown: 8s.
   - **Snare (`scenes/snare.tscn`, `scripts/trap.gd`, `scripts/trap_visual.gd`)**: Placed on ground, wire-loop spring trap. Wolf entering 40px radius is snared for 5.0s, completely halting movement until recovery. Cooldown: 8s.
   - **Bolt Launcher (`scenes/bolt_launcher.tscn`, `scripts/bolt_launcher.gd`, `scripts/bolt_launcher_visual.gd`, `scenes/module.tscn`)**: Shellback-mounted ballista module. Player activates via HUD. Fires visible heavy physical bolt (`scenes/projectile.tscn`). Cooldown: 4s.
   - **Bolt Projectile (`scenes/projectile.tscn`, `scripts/projectile.gd`, `scripts/projectile_visual.gd`)**: Travels toward the selected living predator at 460 px/s. Damage (30 HP) occurs **strictly upon physical impact**, not at firing time. Target-safe guidance accounts for the launcher and wolf being at different heights.

5. **Interface (HUD) & Onboarding Tutorial (`scenes/hud.tscn`, `scripts/hud.gd`)**:
   - Touch-friendly layout with large touch targets (all action and tutorial buttons have a minimum height of 52px).
   - Shellback health bar and numeric readout.
   - Shellback state badge (`● WALKING`, `❚❚ HALTED`, `⚠ PANICKED!`, `✖ DEAD`).
   - Dynamic status banner conveying ongoing encounter events.
   - Clear cooldown presentation for Bait, Snare, and Bolt Launcher with cooldown progress indicators.
   - Placement mode banner when targeting ground for tools.
   - **Six-Page Paused Modal Tutorial Overlay**:
     - Automatically appears when launched normally (bypassed in headless mode to keep automated test suites non-blocking).
     - Pauses the entire SceneTree simulation before the Shellback or wolf moves.
     - Darkens the background with a semi-transparent backdrop (`Color(0.04, 0.06, 0.09, 0.9)`).
     - Header displays `"PAUSED — HOW TO PLAY"` and page indicator (e.g. `"1 / 6"`).
     - Prevents touches and clicks from reaching world entities or regular HUD controls.
     - Responsive navigation: `[SKIP TUTORIAL]`, `[◀ BACK]`, and `[NEXT ▶]` (switches to `[START RUN]` on page 6).
     - Clamps navigation bounds: Back is disabled on page 1; forward navigation on page 6 closes the overlay and unpauses.
     - Does not automatically reopen upon pressing Restart in the same running session (tracked via `static var has_shown_initial_tutorial`).
     - Overlay pages:
       - **Page 1 — THE MISSION:** Escort the Shellback to the glowing eastern pass alive; win upon reaching the right side of the trail.
       - **Page 2 — CONTROL THE CARAVAN:** Shellback walks automatically; tap HALT to stop before danger and RESUME when clear; tap Shellback directly. Clarifies that the Warden is primarily a position marker in this greybox.
       - **Page 3 — DISTRACT WITH BAIT:** Documents the exact two-step Bait action (tap PLACE BAIT, then tap position on trail). Wolf smells nearby bait and walks toward it.
       - **Page 4 — SET A SNARE:** Documents the exact two-step Snare action (tap PLACE SNARE, then tap wolf's expected path). Wolf is trapped for 5 seconds upon crossing.
       - **Page 5 — FIRE THE BOLT:** Caravan launcher targets the living wolf. Physical impact required for damage; two hits defeat the wolf; launcher has reload cooldown.
       - **Page 6 — CHOOSE YOUR PLAN:** Outlines both tactical paths:
         - *Combat plan:* Halt caravan and defeat the wolf with two bolts.
         - *Evasion plan:* Lure the wolf away with bait, trap it with a snare, then resume the caravan.
   - **`? HELP` Button in Top HUD:**
     - Always visible in the top status bar.
     - Pressing HELP immediately pauses the game, opens the tutorial at page 1, and cancels any pending Bait or Snare placement mode.
     - Preserves existing battle state (actors, health, positions, cooldowns).
     - Closing the tutorial resumes gameplay from the exact same state.
   - Cooldown protection: While tutorial is open, cooldowns do not decrement.
   - Restart button always accessible.
   - Mutual exclusivity on Victory and Defeat with overlay banner and Play Again action.

6. **Environment (`scripts/environment_visual.gd`)**:
   - Dusk gradient sky, distant mountain ranges, midground rolling grassy hills, trail footpath, and an ancient standing waystone with beacon lantern at the exit boundary.

---

## 2. Controls, Strategies, and Tunable Values

### Controls:
- **Move Warden / Scout:** Tap/click open ground (Y between 70 and 620). Note: in this greybox, the Warden functions as a position marker and scout anchor.
- **Halt / Resume Shellback:** Tap directly on the Shellback or tap `[⏸ HALT]` / `[▶ RESUME]` in the bottom HUD.
- **Place Bait (Two-step):**
  1. Tap `[🥩 PLACE BAIT]` in the HUD.
  2. Tap destination position on the trail -> Bait is placed (starts 8s cooldown).
- **Place Snare (Two-step):**
  1. Tap `[🪤 PLACE SNARE]` in the HUD.
  2. Tap wolf's expected path on the trail -> Snare is armed (starts 8s cooldown).
- **Fire Bolt:** Tap `[🏹 FIRE BOLT]` -> fires heavy bolt from caravan launcher toward living wolf (starts 4s cooldown; damage occurs on physical impact).
- **Open Tutorial (`? HELP`):** Tap `[? HELP]` in top HUD -> immediately pauses gameplay, opens tutorial at page 1, and cancels active tool placement mode.
- **Tutorial Navigation:**
  - `[◀ BACK]`: Step back one page (disabled on page 1).
  - `[NEXT ▶]`: Advance one page.
  - `[SKIP TUTORIAL]`: Close overlay and unpause immediately.
  - `[START RUN]`: Close overlay and unpause from page 6.
- **Restart Run:** Tap `[🔄 RESTART]` in top HUD or on the game over screen.

### Available Strategies:
1. **Combat Plan:**
   - Tap HALT to stop the Shellback safely out of the wolf's attack range.
   - Fire a bolt from the caravan launcher.
   - Wait for the 4s launcher reload cooldown.
   - Fire a second bolt to defeat the wolf on impact.
   - Tap RESUME to escort the caravan safely to the eastern pass.
2. **Evasion Plan:**
   - Place Bait ahead or away from the caravan to lure the wolf into investigating.
   - Place a Snare along the wolf's path to immobilize it for 5 seconds.
   - Resume the Shellback while the wolf is preoccupied or snared.
   - Cross the eastern exit waypoint before the wolf can recover and engage.

### Tunable Parameters:

| Entity | Parameter | Default Value | Location | Description |
|---|---|---|---|---|
| Shellback | `max_health` | `100.0` | `scripts/shellback.gd` | Maximum and starting health |
| Shellback | `walk_speed` | `24.0 px/s` | `scripts/shellback.gd` | Normal travel speed |
| Shellback | `panic_speed_multiplier` | `1.6` | `scripts/shellback.gd` | Speed boost while panicked |
| Shellback | `panic_duration` | `3.5 s` | `scripts/shellback.gd` | Time before panic subsides |
| Warden | `move_speed` | `190.0 px/s` | `scripts/warden.gd` | Horizontal scout walk speed |
| Warden | `min_x` / `max_x` | `40.0` / `1240.0` | `scripts/warden.gd` | Horizontal movement boundary |
| Wolf | `max_health` | `60.0` | `scripts/wolf.gd` | Predator health (2 bolt hits to defeat) |
| Wolf | `patrol_speed` | `30.0 px/s` | `scripts/wolf.gd` | Idle wandering speed |
| Wolf | `investigate_speed` | `75.0 px/s` | `scripts/wolf.gd` | Speed when moving toward bait |
| Wolf | `stalk_speed` | `85.0 px/s` | `scripts/wolf.gd` | Speed when tracking caravan |
| Wolf | `attack_damage` | `20.0` | `scripts/wolf.gd` | Damage dealt per strike |
| Wolf | `attack_windup_time` | `0.55 s` | `scripts/wolf.gd` | Delay before contact strike moment |
| Wolf | `attack_cycle_time` | `1.50 s` | `scripts/wolf.gd` | Full attack cooldown cycle |
| Wolf | `scent_range` | `600.0 px` | `scripts/wolf.gd` | Detection range for Bait |
| Wolf | `detect_range` | `450.0 px` | `scripts/wolf.gd` | Detection range for Shellback |
| Trap (Bait) | `bait_lifetime` | `16.0 s` | `scripts/trap.gd` | Duration before bait spoils |
| Trap (Snare) | `snare_duration` | `5.0 s` | `scripts/trap.gd` | Duration wolf remains held |
| Trap (Snare) | `trigger_radius` | `40.0 px` | `scripts/trap.gd` | Proximity trigger distance |
| Projectile | `speed` | `460.0 px/s` | `scripts/projectile.gd` | Bolt flight velocity |
| Projectile | `damage` | `30.0` | `scripts/projectile.gd` | Physical impact damage |
| Projectile | `hit_radius` | `24.0 px` | `scripts/projectile.gd` | Physical collision radius |
| Launcher | `cooldown_time` | `4.0 s` | `scripts/bolt_launcher.gd` | Module reload cooldown |

---

## 3. Files Created or Modified

### Created Files:
- `project.godot`: Project configuration with 1280x720 viewport, GL Compatibility renderer, touch emulation, and landscape settings.
- `scenes/main.tscn`: Main gameplay test map assembling background, actors, and UI.
- `scenes/shellback.tscn`: Reusable Shellback entity scene with collision, mounts, and overhead health.
- `scenes/warden.tscn`: Reusable Warden scout entity scene.
- `scenes/wolf.tscn`: Reusable Wolf threat entity scene.
- `scenes/trap.tscn`: Generic ground tool scene.
- `scenes/bait.tscn`: Preconfigured Bait scene.
- `scenes/snare.tscn`: Preconfigured Snare scene.
- `scenes/projectile.tscn`: Heavy ballista bolt scene.
- `scenes/bolt_launcher.tscn`: Caravan-mounted bolt launcher module scene.
- `scenes/module.tscn`: Reusable module alias scene.
- `scenes/hud.tscn`: Touch-friendly HUD scene.
- `scripts/main.gd`: Game controller coordinating actors, tools, inputs, and win/loss flow.
- `scripts/shellback.gd`: Escort objective state, health clamping, and movement control.
- `scripts/shellback_visual.gd`: Code-drawn procedural Shellback visual node.
- `scripts/warden.gd`: Scout movement and map bounds logic.
- `scripts/warden_visual.gd`: Code-drawn procedural Warden visual node.
- `scripts/wolf.gd`: Predator state machine, bait scenting, contact attack, and target safety.
- `scripts/wolf_visual.gd`: Code-drawn procedural Wolf visual node with intent feedback.
- `scripts/trap.gd`: Ground trap logic for bait expiration and snare triggering.
- `scripts/trap_visual.gd`: Code-drawn procedural visuals for bait bowl and snare wire.
- `scripts/bolt_launcher.gd`: Module firing and cooldown management.
- `scripts/bolt_launcher_visual.gd`: Code-drawn procedural launcher turret with recoil.
- `scripts/projectile.gd`: Bolt flight, impact detection, and impact damage application.
- `scripts/projectile_visual.gd`: Code-drawn procedural bolt and impact flash sparks.
- `scripts/hud.gd`: Interface management, button feedback, and cooldown presentation.
- `scripts/environment_visual.gd`: Dusk backdrop, hills, trail, and exit waystone drawing.
- `scripts/world_health_bar.gd`: Overhead visual health bar for actors.
- `tests/test_milestone1.gd`: Automated headless smoke test suite checking all required behaviors.
- `tests/test_integrated_run.gd`: Headless integrated frame runner (180 frames).
- `docs/MILESTONE_1_STATUS.md`: Detailed status document.

### Modified Files:
- `README.md`: Updated project status and milestone description.

---

## 4. Verification Commands and Exit Codes

All checks were executed independently via the command line:

1. **Godot Parser and Import Validation:**
   ```powershell
   & "C:\Users\nilan\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --quit
   ```
   - **Exit Code:** `0`
   - **Result:** Project filesystem scanned, all 16 class names registered without errors or warnings.

2. **Automated Headless Smoke Tests:**
   ```powershell
   & "C:\Users\nilan\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_milestone1.gd
   ```
   - **Exit Code:** `0`
   - **Result:** 152/152 assertions passed (0 failed). Verified:
     - Core mechanics: Scene loading, Shellback health clamping and irreversible death, legal wolf finite state transitions, bait scent attraction and consumption, snare entrapment and 5s release, elevated projectile aim geometry with damage applied strictly on physical impact, victory/defeat mutual exclusivity, restart transient cleanup and entity restoration, and freed target safety.
     - Tutorial overlay: Required UI nodes present, touch target minimum heights >= 52px, exactly 6 pages configured with correct content, SceneTree pausing on tutorial open, unpausing on close and skip, page navigation clamping at bounds, final page transition to `START RUN`, HELP button immediately pausing and cancelling pending Bait/Snare placement modes, cooldown freezing during tutorial display, HUD reset closing tutorial and restoring unpaused state, and headless launch safety (not automatically stuck paused).
     - Teardown safety: Guaranteed restoration of `SceneTree.paused = false` in teardown across all test functions.

3. **Integrated Headless Scene Execution:**
   ```powershell
   & "C:\Users\nilan\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless scenes/main.tscn --quit-after=180
   ```
   - **Exit Code:** `0`
   - **Result:** 180 frames executed cleanly; the integrated runner completed without a reported runtime error. This short headless run does not prove long-session memory stability or visual correctness.

4. **Git Diff Check:**
   ```powershell
   git diff --check
   ```
   - **Exit Code:** `0`
   - **Result:** The command exited cleanly, but all project files were untracked, so it did not inspect their contents. A separate direct scan found and corrected trailing whitespace across all untracked GDScript and Markdown files.

5. **Git Status:**
   ```powershell
   git status --short
   ```
   - **Exit Code:** `0`
   - **Result:** All files created are unstaged and uncommitted for review.

6. **Real Android Device Gate:**
   - **Device:** Redmi Note 11S (`2201117SI`), Android 13 / API 33.
   - **Build:** arm64 debug APK, 27.04 MiB, installed as `com.nilan.projecttrailbeast`.
   - **Confirmed through ADB-driven touches and device screenshots:** landscape launch with safe 16:9 letterboxing; first-launch paused tutorial; all tutorial pages; Start Run; in-game Help and pause/resume; Halt/Resume; Bait and Snare placement; two successful bolt hits; wolf defeat; normal victory; Play Again reset; Android Home/background and return; and normal defeat flow.
   - **Runtime sampling:** the game remained foreground with a live process after reconnecting USB. Sampled logs contained no `FATAL EXCEPTION`, Android runtime fatal, Godot error, or GDScript error.
   - **Storage observations:** installed code was approximately 101.1 MiB and mutable app data approximately 304 KiB. Debug packaging overhead means this is not the expected Play Store download size.
   - **Resource observations:** sampled proportional memory varied with lifecycle state and is not evidence of a leak. A short battery reading showed 36.7-37.0 C while externally powered; this is not a thermal endurance test.
   - **Not established:** sustained FPS, long-session stability, physical thumb comfort, subjective readability at normal holding distance, reverse-landscape behavior, and Play Store release/AAB signing.

---

## 5. Scope Boundaries and Pending Manual Checks

### Evidence Boundary Note:
Automated headless tests provide evidence for the covered logic paths, state transitions, pause/unpause safety, and cooldown handling. They do **not** prove complete program correctness, absence of memory leaks, visual quality, touch comfort, sustained frame rate, or subjective player onboarding clarity. The Android checks above establish that the tested flows worked during this session, not that every device or long session will behave identically.

### Manual Android Checklist (Pending User Appraisal):
- [ ] **Tutorial Visual Polish:** Judge overlay contrast and font hierarchy at normal phone holding distance.
- [ ] **Tutorial Navigation Feel:** Confirm `[◀ BACK]`, `[NEXT ▶]`, `[SKIP TUTORIAL]`, and `[START RUN]` are comfortable with your own thumbs.
- [ ] **In-Game Help Feel:** Confirm opening and closing `[? HELP]` mid-skirmish feels natural rather than disruptive.
- [ ] **Visual Presentation:** Verify that Shellback silhouette, Warden figure, and Wolf intent poses look harmonious and readable at native resolution.
- [ ] **Wolf Intent Clarity:** Observe the transition from IDLE -> INVESTIGATE when bait is placed, and STALK -> ATTACK when near the Shellback. Ensure the strike flash telegraph is distinct.
- [ ] **Playstyle Feasibility:**
  - Route A (Combat Plan): Halt caravan, defeat wolf using 2 bolt hits, resume caravan.
  - Route B (Evasion Plan): Distract wolf with bait, pin with snare, and escort Shellback to exit without firing.
- [ ] **Touch Usability on Target Phone:** Play for 10-15 minutes and judge whether the button layout remains comfortable and avoids accidental taps.
- [ ] **Performance and Heat:** Observe smoothness, battery use, and heat during that longer session. Do not assume a constant 60 FPS from the short automated device pass.
