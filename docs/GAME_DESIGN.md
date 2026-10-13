# Game Design: Project Trailbeast

## 1. One-sentence pitch

Guide a living caravan across dangerous wilderness maps by scouting, hiding, trapping, distracting, and fighting while carrying the last Hearthseed toward a safe valley.

## 2. Player fantasy

The player is a Trail Warden responsible for a young Shellback: a huge, gentle travelling creature that carries a tiny settlement on its shell. The Warden is not an all-powerful warrior. Their strength is understanding the land and preparing for danger.

The intended feeling is:

- "I survived because I understood what was happening."
- "My choice changed how the encounter unfolded."
- "I want to try the next route with a different plan."

## 3. Story premise

A strange Long Dusk scattered the ancient Shellback migration and swallowed much of the wilderness. The player's Shellback carries a living Hearthseed that can awaken a safe valley, but it cannot survive indefinitely without food, shelter, and care.

The player travels toward Dawn Valley while rescuing scattered people, discovering what caused the migration to fail, and deciding which communities and creatures to help along the way.

The story is not about rescuing a girlfriend or killing every enemy. It is about keeping a vulnerable travelling home alive.

## 4. Core game loop

Each map lasts roughly four to seven minutes.

1. **Read the land** - inspect tracks, weather, terrain, and visible threats.
2. **Prepare** - select limited tools and caravan modules.
3. **Travel** - move the Shellback, send the Warden to scout, and gather supplies.
4. **Respond** - hide, distract, trap, flee, negotiate, or fight.
5. **Leave** - reach the exit and choose the next route or a temporary improvement.

A region contains approximately five maps and should last 25 to 35 minutes.

## 5. Mobile controls

The game uses landscape orientation and avoids a permanent virtual joystick.

- Tap terrain to send the Warden there.
- Tap the Shellback to stop or resume its movement.
- Drag a trap or lure from the tool bar onto valid ground.
- Tap a caravan module to activate it.
- Opening the tool bar slows time so the player can think.
- Important targets use large touch areas and clear feedback.

## 6. The Shellback

The Shellback is simultaneously the player's home, escort objective, inventory limit, and emotional centre.

It has:

- Health: physical damage.
- Calm: fear caused by noise, fire, or nearby monsters.
- Hunger: affects travel speed and recovery between maps.
- Module mounts: limited space for equipment.

If Calm breaks, the Shellback may panic and move without waiting for the player. This creates danger without every failure being direct health damage.

## 7. Modules

The full game may allow three visible mounts. The first prototype uses only two.

Module families:

- **Protection** - armour screen, smoke shelter, healing nest.
- **Control** - snare thrower, scent lure, noise maker.
- **Combat** - bolt launcher, sling turret, fire-pot thrower.
- **Utility** - food basket, scout perch, salvage rack.

There is no universally correct loadout. Three weapons provide firepower but sacrifice storage, concealment, and recovery.

## 8. Warden tools

Tools are placed or activated manually and use limited supplies.

- Snare: holds a small target temporarily.
- Bait: draws hungry wildlife toward a location.
- Smoke: blocks sight and reduces panic from visible threats.
- Bell/noise lure: redirects curious or aggressive enemies.
- Field dressing: restores a small amount of health outside immediate danger.

## 9. Creature behaviour

Creatures are not simple red targets. Each species has readable needs and reactions.

Initial examples:

- **Boar** - territorial; warns before charging; can be avoided or redirected.
- **Wolf pack** - investigates noise, surrounds isolated targets, fears sustained fire.
- **Raider scout** - observes before calling allies; may retreat if isolated.
- **Scavenger bird** - reveals corpses and dropped supplies but may attract predators.

Later systems can include scent, wind, rain, light, hunger, and relationships between species. The first prototype implements only the smallest behaviour needed to test whether indirect solutions are enjoyable.

## 10. Encounters and objectives

Maps should ask for more than survival.

- Cross the map with the Shellback intact.
- Rescue a stranded traveller.
- Recover food without waking a territorial animal.
- Protect a nesting creature from raiders.
- Choose between a safe long route and a dangerous resource-rich shortcut.
- Escape an enemy that cannot yet be defeated.

Every early encounter should support at least two reasonable solutions.

## 11. Progression and resets

Temporary regional progress:

- Food and ammunition.
- Improvised traps.
- Temporary armour patches.
- Local allies.
- Run-specific module improvements.

Permanent progress:

- Module and tool blueprints.
- Knowledge recorded in the creature journal.
- Rescued specialists.
- New starting choices.
- Story discoveries and routes.
- Cosmetic changes to the travelling settlement.

Temporary progress resets at a region boundary because harsh crossings consume supplies and improvised construction. A reset must make sense in the world and must not erase everything the player learned or earned.

## 12. Regions for the eventual game

These are direction, not immediate development scope.

1. **Whispering Grass** - boars, wolves, wind, tall grass, first raiders.
2. **Flooded Reeds** - water routes, scent masking, amphibious creatures.
3. **Ironwood** - dense cover, fire risk, organised raider camps.
4. **Ash Pass** - scarce food, unstable ground, creatures changed by the Long Dusk.
5. **Dawn Valley** - reunion, final route choices, and the Hearthseed decision.

## 13. Failure and fairness

- Threats telegraph dangerous actions.
- The player should understand why a plan failed.
- Early maps do not punish experimentation with long repetition.
- A failed map returns the player to the start of that map, not the start of the entire campaign.
- Optional harder modes may add region-level consequences later.

## 14. Art and sound direction

- Flat, readable 2D shapes with a small colour palette.
- The Shellback and creatures must have recognisable silhouettes.
- Code-drawn placeholder art first; original sprites only after the mechanic is fun.
- Short compressed sound effects and a small number of music layers.
- Avoid detailed realism, large frame-by-frame animation sets, and copied fantasy designs.

## 15. Monetisation boundary

Monetisation is deliberately deferred until the game is enjoyable.

The initial builds are offline and contain no ads, analytics SDKs, currencies bought with money, loot boxes, subscriptions, or account system. Later options may include a free demo with a one-time full-game unlock or a small premium release, but no decision is required now.

## 16. Deferred features

- Multiplayer or co-op.
- Large procedural world generation.
- Endless live-service content.
- Dozens of modules or creatures.
- Online accounts and cloud saves.
- Advertising and in-app purchases.
- Complex crafting.

## 17. Originality rules

- Do not reproduce another game's characters, names, user interface, map layouts, upgrade trees, story, or exact encounter sequences.
- References may teach design functions such as short sessions, temporary versus permanent progress, or readable counterplay.
- The living caravan, ecology interactions, Calm system, and mixed non-combat solutions must remain central.
- New features must strengthen the core decision: fight, hide, distract, trap, or move.

## 18. Moving Fortress Prototype Direction

The Moving Fortress prototype explores whether discrete route choices on an enlarged wilderness map combined with camp-configured modules and moving-vs-halting defense creates an engaging strategic loop:

1. **Topological Route Graph**: Moving across connected camps and resource nodes (Woodland, Ruined Watchpost, River Crossing, Final Pass, Exit Haven) replaces continuous single-lane scrolling.
2. **Discrete Movement**: The Shellback rests at camp and moves only along confirmed routes. Players can halt to defend in place or fight while advancing.
3. **Three Module Slots**: At camp workshops, players select exactly 3 modules from 4 choices (Bolt Launcher, Armour Screen, Storage Rack, Snare Rack).
4. **Encounter Variety**: Low-threat forage routes (Woodland with lone wolf) vs. high-threat salvage routes (Ruined Watchpost with raiders) test loadout versatility.
5. **Contextual Teaching**: Direct 5-step contextual cues replace multi-page manual overlays.

