# Development Roadmap

## Rule for every milestone

Build the smallest version, run it on the connected Android phone, and ask whether the decisions are enjoyable before adding content.

## Milestone 0 - Planning and clean repository

Status: complete.

- Separate repository.
- Game concept and scope documented.
- Lightweight and originality constraints documented.
- No game code yet.

## Milestone 1 - Five-minute greybox

Goal: determine whether escorting the Shellback and solving one threat with more than one method is enjoyable.

Build only:

- One landscape test map.
- Code-drawn Shellback moving left to right.
- Stop/resume control.
- Code-drawn Warden who moves to tapped ground positions.
- One wolf with simple readable states.
- Two tools: snare and bait.
- One Shellback module: bolt launcher.
- Win by reaching the exit.
- Lose if the Shellback reaches zero health.
- Restart button.
- Touch-friendly HUD.
- Headless tests for core state changes.

Do not add story screens, inventory, saving, multiple maps, weather, crafting, upgrades, or final art.

Success questions:

- Can a new player understand the goal within one minute?
- Can the wolf be handled by fighting or by bait-and-trap?
- Does stopping and scouting feel useful rather than slow?
- Are touch targets comfortable on the Redmi Note 11S?

## Milestone 2 - Small ecosystem

Only begin if Milestone 1 is understandable and at least mildly fun.

- Add boar and raider scout.
- Add noise as a shared readable system.
- Add smoke tool and one defensive module.
- Add rescue objective.
- Ensure enemies can react to one another.
- Add an encounter tutorial through play, not a long text page.

## Milestone 3 - Three-map region

- Three handcrafted maps with route selection.
- Temporary food, ammunition, and one run upgrade.
- One permanent blueprint reward.
- Region result screen.
- Basic save file.

## Prototype Branch - Moving Fortress (codex/moving-fortress-prototype)

Status: Active experimental prototype.

Goal: Test whether route choice, 3-module configuration, and defending a moving fortress is engaging before full region production.

- Enlarged 2560x1440 procedural wilderness map with top-down elevated view.
- Camera touch-drag panning, boundary clamping, and large RE-CENTER control.
- Route graph with discrete nodes (Woodland Vale, Ruined Watchpost, River Crossing, Final Pass, Exit Haven).
- Three module slots from four choices (Bolt Launcher, Armour Screen, Storage Rack, Snare Rack) configured only at camps.
- Halt and resume caravan defense during encounters.
- River crossing decision (Repair vs Hurry).
- Contextual teaching replacing 6-page overlay.
- Complete deterministic headless test suite (269 assertions passing), including every loadout under normal and hurried Final Pass conditions plus complete-route simulations.

## Milestone 4 - Identity and presentation

- Replace greybox art with an original small visual set.
- Add sound feedback, minimal music, accessibility options, and clearer onboarding.
- Establish final character and creature designs.
- Choose a store-safe final name after a trademark and store search.

## Milestone 5 - External testing

- Test on several Android devices.
- Measure release APK/AAB, installed size, memory, loading, heat, and battery use.
- Recruit external closed testers only when the first region is stable.
- Collect observations, not only star ratings.

## Milestone 6 - Commercial decision

Only after retention and enjoyment are demonstrated:

- Decide between premium, free demo plus full unlock, or another fair model.
- Add only the minimum required store and privacy integrations.
- Prepare production signing, store assets, privacy policy, and Play Console testing.

## Stop conditions

Pause expansion if:

- The optimal solution is always maximum firepower.
- Scouting feels like waiting rather than decision-making.
- Players cannot understand creature intent.
- New content is being added to hide an uninteresting core loop.
- Android performance or interface readability deteriorates.

