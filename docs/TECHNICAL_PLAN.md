# Lightweight Technical Plan

## Platform and engine

- Godot 4.7.2 Standard.
- GDScript only.
- Android first, landscape orientation.
- GL Compatibility renderer.
- Logical viewport: 1280 x 720.
- ARM64 Android debug exports during development.
- No third-party addons or runtime SDKs in the first milestones.

## Performance targets

- 60 FPS on the connected Redmi Note 11S during the greybox.
- Maximum 25 active moving entities in early milestones.
- Debug memory target below 250 MB PSS; reduce if practical.
- APK target below approximately 40 MB while recognising Godot's fixed runtime cost.
- No continuous allocation-heavy effects.

## Architecture for Milestone 1

Suggested scenes:

- `scenes/main.tscn` - map, game flow, and HUD.
- `scenes/shellback.tscn` - travelling objective and health.
- `scenes/warden.tscn` - tap-to-move player helper.
- `scenes/wolf.tscn` - first readable threat.
- `scenes/trap.tscn` - snare or bait placement.
- `scenes/module.tscn` - bolt launcher.

Suggested scripts:

- Keep rules separate from drawing.
- Use small explicit state machines.
- Use analytical positions and distances instead of a complex physics simulation where possible.
- Avoid navigation meshes for the first horizontal test map.
- Clamp health and resource values.
- Guard freed or invalid targets.
- Deliver damage at visible contact or projectile impact.

## First behaviour model

Wolf states:

- IDLE - waits or patrols a small area.
- INVESTIGATE - moves toward bait.
- STALK - approaches the Shellback after detecting it.
- ATTACK - damages at contact-timed intervals.
- SNARED - cannot move for a limited time.
- DEAD - stops acting and cannot leave this state.

The state and the reason for transition should be visible through colour, icon, animation, or movement.

## Testing

Automated checks should cover:

- Scene loading.
- Health clamping.
- Wolf state transitions.
- Bait attraction.
- Snare duration and release.
- Projectile impact timing.
- Victory and defeat exclusivity.
- Restart safety.
- Freed-target safety.

Validation levels must remain separate:

1. Godot parser/import check.
2. Automated headless smoke tests.
3. Integrated headless scene run.
4. Manual desktop visual check.
5. Manual Android touch and performance check.

Passing one level must not be described as proof that another passed.

## Repository rules

- Do not copy copyrighted assets or recognisable game designs.
- Do not store APKs, AABs, keystores, credentials, `.godot`, or build outputs in Git.
- Do not stage or commit unless explicitly requested.
- Do not create a remote repository unless explicitly requested.
- Preserve unrelated user changes.

