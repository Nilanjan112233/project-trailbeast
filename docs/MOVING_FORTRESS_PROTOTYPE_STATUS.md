# Moving Fortress Prototype Status Report

## 1. Overview and Core Hypothesis

This experimental prototype tests the core question:
> **"Is choosing a route, configuring three modules, and defending a moving fortress engaging?"**

The prototype transitions Project Trailbeast from continuous lane walking to an enlarged wilderness map where the player makes discrete route choices, customizes a 3-module loadout at camps, and actively defends the moving fortress against wilderness threats.

---

## 2. Implemented Systems and Features

### A. Enlarged Wilderness Map (2560 x 1440 World Units)
- **Dimensions**: 2560 x 1440 world units rendered in the standard 1280 x 720 logical Android landscape viewport. The entire map is never visible simultaneously, creating genuine tactical fog and scouting value.
- **Visual Presentation**: Angled top-down elevated 2D view procedurally code-drawn using vector primitives (`MapVisual`):
  - **Northern Woodland Vale**: Pine groves, dark loam canopy, soft terrain.
  - **Southern Ruined Watchpost**: Ancient stone foundations, crumbling masonry arches, cracked flagstones.
  - **Central River Crossing**: Broad blue winding river with water ripple animations, ford shallows, and wooden pylons at (1460, 720).
  - **Eastern Final Pass**: Mountain canyon gorge cliffs funneling threats into a narrow chokepoint.
  - **Exit Haven**: Palisade wooden barricades and glowing sanctuary Hearthstone shrine at (2380, 720).
- **Camera Controller**:
  - Touch-drag and mouse-drag panning with smooth inverse translation.
  - Hard boundary clamping ensuring the viewport never pans beyond `[640, 360]` to `[1920, 1080]`.
  - Prominent touch-friendly **RE-CENTER** button (`>= 52px` min height) instantly re-aligning camera focus on the Shellback.
  - Clear selection highlight rings and pulsing indicators on active destinations.

### B. Route Graph Navigation
- **Topological Route Graph**:
  $$\text{Starting Camp} \longrightarrow \begin{cases} \text{Woodland Vale (Low Threat)} \\ \text{Ruined Watchpost (High Threat)} \end{cases} \longrightarrow \text{River Crossing} \longrightarrow \text{Final Pass} \longrightarrow \text{Exit Haven}$$
- **Inspection Flow**:
  - Tapping a map node opens the **Route Inspector Modal Card**.
  - Displays destination name, threat rating, resource rewards (Food, Wood, Salvage), terrain description, and completion state.
  - Only legally connected, unvisited nodes enable the **CONFIRM TRAVEL** action.
  - Re-visiting completed nodes and selecting disconnected nodes is strictly prohibited.

### C. Shellback as Moving Fortress
- **Non-Continuous Travel**: The Shellback rests at camp until the player explicitly confirms travel.
- **Waypoint Navigation**: Upon confirming travel, the Shellback traverses natural curved path waypoints toward the target node at 75 px/s, automatically stopping upon arrival.
- **Halt / Resume Control**:
  - The player can tap **HALT** at any time during travel to stop and fight approaching threats in place.
  - Tapping **RESUME** continues progress along the route.
  - If attacked, the Shellback undergoes brief panic (1.6x speed, alarmed visual eye and shell modulation) during which halting is disabled until calm returns.
- **Caravan Carapace Boundaries**: Shellback position strictly clamped within `[100, 2460]` x `[100, 1340]`.

### D. Three Modular Slots
At camps, players configure exactly **three** modules from four distinct choices:
1. **Bolt Launcher** (Active): Swiveling ballista turret firing heavy physical bolts every 3.0s for 30.0 damage at nearest alive threat. Damage is applied strictly on physical impact.
2. **Armour Screen** (Passive): Riveted bronze and iron flank plates reducing all incoming damage to the Shellback by 40% (`effective_damage = base_damage * 0.60`).
3. **Storage Rack** (Passive): Timber cargo crates and barrels increasing all resources gathered at completed nodes by +50% (`1.5x multiplier`). Provides no combat shielding.
4. **Snare Rack** (Active): Rear-mounted coiled ropes and steel bear traps granting 1 manual snare deployment per travel leg. Entangles approaching threats for 5.0 seconds.

- **Visible Shellback Mounting**: All equipped modules are procedurally drawn on the Shellback's carapace and decking (`ShellbackVisual`).
- **Camp-Only Rule**: Loadout modifications are allowed only while anchored at camp nodes (Starting Camp, River Crossing, Exit Haven). The loadout cannot be altered during travel.
- **Universal Viability across all 4 Legal 3-Module Combinations**:
  1. `[bolt_launcher, armour_screen, snare_rack]` (Balanced offensive/control)
  2. `[bolt_launcher, armour_screen, storage_rack]` (Armoured logistics with offense)
  3. `[bolt_launcher, storage_rack, snare_rack]` (Greedy trapper with offense)
  4. `[armour_screen, storage_rack, snare_rack]` (Pure defensive logistics via survival hold)
  While the Bolt Launcher provides the fastest offensive resolution, it is never secretly mandatory. Non-bolt defensive loadouts successfully complete encounters by holding position and surviving until attackers break off their assault.

### E. Encounters and Threats
- **Woodland Vale**: Lower threat level. Spawns 1 Wolf from northern pine woods. Yields Food (+15) and Wood (+10). Hold duration: 10.0s.
- **Ruined Watchpost**: Higher threat level. Spawns 2 Raiders from stone foundations. Yields Salvage (+25) and Wood (+10). Hold duration: 12.0s.
- **Raider Enemy** (`Raider`): Procedural scavenger bandit with spiked helmet, shield, and cleaver. Features explicit FSM (`IDLE`, `APPROACH`, `TELEGRAPH`, `ATTACK`, `SNARED`, `DEAD`). Visibly telegraphs attack with glowing raised weapon for 0.6s before dealing 9 damage on contact.
- **Wolf Enemy** (`Wolf`): Stalks the Shellback in 2D coordinates, attacks on contact, and can be distracted by bait or entrapped by snares.

### F. River Crossing Decision
Upon arrival at `River Crossing`, a compact decision panel appears:
- **REPAIR FORTRESS**: Spends 10 Wood to reinforce plating and patch the beast, restoring +60 HP.
- **HURRY FORWARD**: Preserves all collected wood, but incurs an extra raider ambush in the Final Pass.

### G. Final Pass, Completion Rules, and Timing Evidence
- **Combined Assault & Hold Point**: Combines surviving threat types (1 Wolf + 2 Raiders normal, plus 1 additional Raider if Hurry Forward was chosen) in the narrow canyon pass. Total hits required:
  - **Normal**: Exactly **6 bolt hits** (1 Wolf @ 60 HP = 2 hits; 2 Raiders @ 40 HP each = 4 hits; total 6 hits of 30 damage each).
  - **Hurried**: Exactly **8 bolt hits** (1 Wolf @ 60 HP = 2 hits; 3 Raiders @ 40 HP each = 6 hits; total 8 hits).
- **Dual Completion Rules (Offense vs Survival Hold)**:
  1. *Offensive Early Completion*: Defeating all attackers completes the encounter immediately.
  2. *Defensive Survival Hold*: For loadouts without the Bolt Launcher (or where players prioritize fortifying), surviving a clearly displayed perimeter hold duration completes the encounter. When the hold timer expires, enemies do not vanish silently; the encounter completes with explicit withdrawal ("Defense held! Attackers broke off assault and withdrew into the wilderness.").
  - Hold durations: Woodland 10.0s, Watchpost 12.0s, Final Pass 20.0s. Hurry adds an extra raider rather than also extending the timer; this keeps the choice difficult without applying two unrelated penalties.
  - Armour Screen (40% incoming damage mitigation) and Snare Rack (5.0s threat entrapment) provide decisive survival utility.
- **Deterministic Automated Timing Evidence** (real scene entities stepped at 60 Hz):
  - The Final Pass simulation instantiates the real Shellback, Wolf, Raiders, Snare, Bolt Launcher, and physical projectiles. Damage, cooldowns, movement, panic speed, death signals, hold completion, and withdrawal all run through gameplay code.
  - Hold entry occurred at **4.50-4.98s**. This is faster than the nominal 6.67s march because combat damage can trigger the Shellback's temporary panic-speed surge.
  - Normal offensive completion: **15.383s**, 6 physical Bolt shots, 217.6 HP remaining with the balanced loadout.
  - Hurried offensive completion: **21.417s**, 8 physical Bolt shots, 147.4 HP remaining with the balanced loadout.
  - Normal defensive completion: **25.000s**, attackers withdrew after the 20s hold, 62.8 HP remaining.
  - Hurried defensive completion: **25.000s**, attackers withdrew after the same 20s hold, 8.8 HP remaining. This is intentionally the narrowest successful isolated Final Pass result.
  - Complete cautious repaired runs measured **35.45-84.33s** across all four legal loadouts. The combat-focused Watchpost + Hurry run completed in **44.57s** with 136.6 HP remaining.
- **Separation of Automated Timing from Pending Human Android Playtesting**:
  - We do *not* claim that ordinary human play "strictly" lasts 30–60 seconds based on mathematical formulas alone.
  - Automated simulations provide repeatable baselines under immediate inputs; they do not prove human play duration, enjoyment, touch comfort, frame pacing, heat, or battery behavior.
  - Live human play on the Redmi Note 11S remains a separate required check.
- **Victory Condition**: Arriving at Exit Haven with the Shellback alive triggers the Victory screen, detailing:
  - Route taken (e.g. `Starting Camp → Woodland Vale → River Crossing → The Narrow Pass → Exit Haven`)
  - Remaining health pool
  - Resources gathered (with Storage Rack bonuses factored in)
  - Equipped modules
  - One display-only run reward ("Relic of the Hearthseed")
- **Defeat Condition**: Shellback HP reaching 0 triggers the Fortress Fallen screen with full restart option.

### H. Contextual Onboarding & Modal Shielding
- Replaced the legacy 6-page manual with 5 sequential contextual prompts:
  1. *PAN THE MAP*: Explains touch-drag panning and RE-CENTER.
  2. *INSPECT A ROUTE*: Guides tapping Woodland or Watchpost.
  3. *CONFIGURE LOADOUT*: Introduces workshop module selection at camp.
  4. *CONFIRM TRAVEL*: Directs player to start the journey.
  5. *TRAVEL & DEFEND*: Explains HALT/RESUME and module firing.
- Modal panels (Route Inspector, Loadout, River Decision, Onboarding, Game Over) strictly block ground interaction and camera panning while visible.

---

## 3. Tunable Parameters

| System | Parameter | Value | Purpose |
|---|---|---|---|
| **World** | `MAP_SIZE` | `2560 x 1440` px | Wilderness map area |
| **Viewport** | `VIEWPORT_SIZE` | `1280 x 720` px | Android landscape screen |
| **Camera** | `min_bounds` | `(640, 360)` px | Top-left camera clamp |
| **Camera** | `max_bounds` | `(1920, 1080)` px | Bottom-right camera clamp |
| **Shellback** | `travel_speed` | 75.0 px/s | Speed along route waypoints |
| **Shellback** | `max_health` | 250.0 HP | Moving-fortress durability |
| **Shellback** | `panic_speed_multiplier` | 1.6x | Speed boost during panic |
| **Shellback** | `panic_duration` | 3.0 s | Panic recovery time |
| **Armour** | Damage Reduction | 40% (0.60x) | Passive incoming damage reduction |
| **Storage** | Resource Bonus | 50% (1.50x) | Node resource multiplier |
| **Bolt** | `damage` | 30.0 | Single-target projectile hit damage |
| **Bolt** | `cooldown_time` | 3.0 s | Time between ballista shots |
| **Snare** | `snare_duration` | 5.0 s | Immobilization duration on threat |
| **Snare** | `snare_charges` | 1 per leg | Maximum snares deployable per encounter |
| **Raider** | `max_health` | 40.0 | Total raider health |
| **Raider** | `attack_damage` | 9.0 | Contact damage per strike |
| **Raider** | `telegraph_duration` | 0.6 s | Warning windup duration before attack |
| **Wolf** | `max_health` | 60.0 | Total wolf health |
| **Wolf** | `attack_damage` | 12.0 | Contact damage per bite |

---

## 4. Test Verification Evidence

### A. Headless Smoke Test Suite
- **Command**:
  ```bash
  Godot_v4.7.2-stable_win64_console.exe --headless --path "D:\PROJECTS\Game\Project-Trailbeast" --script "res://tests/test_milestone1.gd"
  ```
- **Exit Code**: `0`
- **Result**: `TEST RESULTS: 269 PASSED, 0 FAILED`
- **Coverage**:
  - 16 scene instantiation checks
  - 12 route graph connection and disconnection checks
  - 8 map completion and non-revisit checks
  - 4 camera boundary clamp and recenter checks
  - 6 Shellback travel lifecycle and halt/resume checks
  - 6 modular loadout rule checks (reject 2, reject 4, accept exactly 3)
  - 4 Armour Screen damage reduction assertions (full 20 vs mitigated 12)
  - 2 Storage Rack resource bonus checks (+50%)
  - 4 Bolt Launcher impact damage checks (no early damage, impact confirmed)
  - 3 Snare charge and entrapment checks
  - 3 Single-application resource reward checks
  - 3 River crossing decision checks (Repair vs Hurry)
  - 5 Victory and defeat mutual exclusivity checks
  - 4 Restart restoring clean state checks
  - 2 Freed-target safety checks
  - 11 Modal shielding and contextual onboarding checks
  - **Regression Coverage (100 checks)**:
    - 29 onboarding sequence checks proving all 5 steps trigger in strict order with tree pauses/resumes
    - 5 modal pause and resume safety checks with reset_ui unpause guarantee
    - 11 mid-travel route locking checks in Main and MapManager
    - 16 snare placement validation checks (rejection at camp, out-of-bounds, open modal, game over, charge preservation, and auto-cancellation)
    - 7 reward idempotency checks proving no duplicate rewards across MapManager and Main
    - 9 Final Pass hold point checks proving the pass cannot complete while living threats remain
    - 23 restart checks verifying all new state is wiped and SceneTree is strictly unpaused
  - **Startup Onboarding Integration (11 checks)**:
    - Instantiates real `main.tscn`, verifies initial state reset precedes onboarding, confirms `PAN_MAP` modal is displayed and SceneTree is paused.
    - Confirms modal dismissal resumes SceneTree.
    - Confirms a meaningful camera drag (> 30 px) dynamically triggers Step 2 (`INSPECT_ROUTE`) and re-pauses the tree.
  - **Loadout Combinations Viability (32 checks)**:
    - Runs all four legal 3-module combinations through both normal and hurried Final Pass variants:
      1. `[bolt_launcher, armour_screen, snare_rack]` (Offensive path)
      2. `[bolt_launcher, armour_screen, storage_rack]` (Offensive path)
      3. `[bolt_launcher, storage_rack, snare_rack]` (Offensive path)
      4. `[armour_screen, storage_rack, snare_rack]` (Defensive survival-hold path)
    - Verifies real Bolt impacts for offensive loadouts and real timed withdrawal for the pure defensive loadout.
  - **Final Pass Deterministic Timing Simulation (18 checks)**:
    - Normal variant: 3 threats, 6 physical Bolt shots, 15.383s offensive completion, or 25.000s survival completion.
    - Hurried variant: 4 threats, 8 physical Bolt shots, 21.417s offensive completion, or 25.000s survival completion.
  - **Complete Route Strategy Simulation (15 checks)**:
    - Runs every legal loadout from Starting Camp through Woodland, River repair, Final Pass, and Exit Haven using actual travel and combat entities.
    - Separately runs the balanced combat loadout through Watchpost plus the riskier Hurry choice.

### B. Integrated Bounded Headless Runner
- **Command**:
  ```bash
  Godot_v4.7.2-stable_win64_console.exe --headless --path "D:\PROJECTS\Game\Project-Trailbeast" --script "res://tests/test_integrated_run.gd"
  ```
- **Exit Code**: `0`
- **Simulation**: 180 continuous frames simulating route confirmation to Woodland at frame 30, halting at frame 90, and resuming at frame 120. Logged coordinates, camera position, threat counts, and resource balances without errors or memory warnings.

### C. Android Debug Export
- **Preset**: `Android Debug` (signed arm64-v8a package)
- **APK Path**: `build/android/project-trailbeast-debug.apk`
- **APK Size**: `28,473,753 bytes` (27.15 MiB)
- **Target OS / Build Tools**: Android SDK build-tools 30.0.2 / target SDK 34 / GL Compatibility renderer.

---

## 5. Five-Minute Manual Playtest Checklist

When loading the debug APK onto the Redmi Note 11S, verify:

1. [ ] **Opening & Camera Drag**: Can you smoothly drag your thumb across the terrain to scout the Woodland and Watchpost? Does the camera cleanly stop at map boundaries?
2. [ ] **Re-Center Comfort**: Tap **RE-CENTER** with your right thumb. Does the camera immediately snap back to center on the Shellback?
3. [ ] **Loadout Inspection**: While at Start Camp, tap **LOADOUT**. Does the workshop modal open? Can you toggle Bolt Launcher, Armour Screen, Storage Rack, and Snare Rack? Does the confirm button remain disabled unless exactly 3 modules are selected?
4. [ ] **Route Selection**: Tap the **Woodland Vale** node. Does the inspector show +15 Food, +10 Wood, and Low Threat?
5. [ ] **Confirmed Travel**: Tap **CONFIRM TRAVEL**. Does the Shellback begin trotting along the curved trail toward the woods?
6. [ ] **Halt & Defend Decision**: When the wolf appears from the pines, tap **HALT**. Does the Shellback halt immediately? Fire a bolt—does the projectile fly and strike the wolf?
7. [ ] **Snare Deployment**: If the Snare Rack is equipped, tap **PLACE SNARE** and tap the wolf's path. Does the wolf get trapped for 5 seconds?
8. [ ] **River Crossing Ford**: Upon arriving at the river, does the decision panel open? Can you choose to spend 10 wood to repair, or hurry forward?
9. [ ] **The Narrow Pass**: During the final pass, do raiders and wolves combine forces? Does the Shellback survive if halted and defended?
10. [ ] **Victory Summary & Restart**: Upon entering Exit Haven, does the Victory screen show your route, remaining HP, and resources? Does tapping **RESTART** return you to Start Camp with full health?
