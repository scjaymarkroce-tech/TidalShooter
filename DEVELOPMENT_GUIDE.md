# Tidal Shooter - Development Guide

## Engine
Godot 4.4.1

## Screen
Fullscreen Target

## Collision Layers
1. Layer 1 – Bushes / Map Obstacles
2. Layer 2 – Player
3. Layer 3 – Enemies (used by all enemy types)
4. Layer 4 – Bullets (used by all gun types)
5. Layer 5 – Items

---

## Game Flow
1. Main Menu
2. Enter game (Wave 1, 2, 3, ...)
3. After every 3rd wave: player chooses one upgrade from a menu
4. After upgrade, enter next waves (repeat)

---

## Upgrade Options (every 3 waves)
- Shotgun Upgrade
- Rifle Upgrade
- Special: Flame Thrower (10% chance)

### Special Weapon: Flame Thrower
- Can be obtained ONLY via upgrade menu (10% chance offered)
- When acquired, available for ONE full wave only, then removed
- 50 damage per tick, fires for 5–10 seconds (per activation)
- Use with [4] key while active

---

## Weapon System
- All weapons unlocked at Wave 1
- Only one gun can be used at any time; player switches using number keys
- **Weapon cooldowns:**
  - Pistol: 0.5s between shots
  - Shotgun: 1.2s between shots
  - Rifle: 1.2s between shots
- **Reload:**
  - Guns auto-reload on empty
  - Manual reload with [R] key

### Ammo System Clarification
- Each gun has a reserve magazine (bullet count shown in scaling table)
- When firing (left-click):
  - Pistol: 1 bullet fired per shot
  - Shotgun: Fires 5 bullets per shot, rest remain in reserve magazine (e.g., 10 bullets, 5 shot per fire = 2 fires/clip)
  - Rifle: 1 bullet fired per shot
- After magazine is empty, must reload (auto or [R])

---

## Weapon Scaling Table

| Level         | Pistol Damage | Mag Size | Reload | Shotgun Dmg | Shotgun Mag | Shotgun Reload | Rifle Dmg | Rifle Mag Size | Rifle Reload |
|--------------|--------------|----------|--------|-------------|-------------|----------------|-----------|----------------|--------------|
| **1**        | 10           | 12       | 3s     | 15          | 10          | 7s             | 25        | 3              | 7s           |
| **2**        | 10           | 12       | 3s     | 21          | 15          | 6s             | 40        | 4              | 6s           |
| **3**        | 10           | 12       | 3s     | 27          | 20          | 5s             | 55        | 5              | 5s           |
| **4**        | 10           | 12       | 3s     | 35          | 25          | 4s             | 70        | 5              | 4s           |
| **5+**       | 10           | 12       | 3s     | Prev*1.2    | capped      | capped         | Prev*1.2  | capped         | capped       |

- *Shotgun fires 5 bullets per click; reserve bullets left for next fire/reload
- Same for Rifle (single bullet per fire; mag size = how many shots before reload)

---

## Enemy Scaling Table

| Wave #    | Normal Enemy HP | Fast Enemy HP | Boss HP     | Enemy #        | Spawn Rate             |
|-----------|-----------------|---------------|-------------|----------------|------------------------|
| 1 – 3     | 20              | 15            | –           | 5              | 1 s                    |
| 4 – 6     | 25              | 28            | –           | 8              | 0.9 s                  |
| 5         | 30              | 20            | 100         | 5 + 1 Boss     | 0.8 s                  |
| 7+        | 30*1.2 per wave | 22*1.2/wave   | +50 hp/5w   | 15*1.2/wave    | 0.7*1.2/wave (min 0.25)|

- Max 15 enemies on screen at any time
- Boss spawns every 5 waves, starting wave 5 (+50 HP every 5 waves)

---

## Player
- 100 HP per try
- 3 tries for the full game (not per wave); when HP ≤ 0, lose 1 try and reset HP to 100
- When tries ≤ 0: Game Over

---

## Dodge Mechanic
- Input: Shift key
- Dash with invulnerability for 0.5s
- Moves player quickly in current direction
- Cooldown: 2 seconds (visual indicator preferred)

---

## Scoring Rules
- Normal Goblin: 10 pts
- Fast Goblin: 20 pts
- Boss Goblin: 70 pts
- Combo Multiplier: (1 + kills_in_10_seconds × 0.1), max 2x multiplier
- Combo resets on kill (timer resets with each kill)

---

## Controls
1. [1] – Pistol
2. [2] – Shotgun
3. [3] – Rifle
4. [4] – Flame Thrower (if available)
5. [Shift] – Dodge
6. [R] – Reload
7. [WASD] – Movement

---

## Other Notes
- After core mechanics: add audio, then visuals if time permits
- No player stat scaling or cosmetics
- Upgrade menu is infinite (every 3rd wave)
- Focus on functionality before polish/visuals

---

## Boss Goblin Behavior
- Visually distinct (bigger sprite, unique color)
- Unique behavior (can be tweaked/expanded if time)
- High damage, average speed (same as normal enemy)

---

## Implementation Priority

### Phase 1: Core Systems (8-10 hours)
1. Implement 3 weapon types with stats from scaling table
2. Gun upgrade system (track upgrade level, apply stat changes)
3. Flamethrower acquisition & activation
4. Implement reload (auto-reload on empty)
5. Test weapon balance

### Phase 2: Enemy System (6-8 hours)
1. Create 3 enemy types (Normal, Fast, Boss)
2. Apply stats from progression table
3. Enemy spawner follows wave/spawn rate schedule
4. Boss Goblin behaves differently (visual + mechanic)
5. Test difficulty curve

### Phase 3: Player Mechanics (5-6 hours)
1. Dodge mechanic (Shift key, 0.5s invulnerability, 2s cooldown)
2. Dodge visual feedback (critical!)
3. Player HP system (100 HP, 3 tries)
4. Knockback/hit feedback

### Phase 4: Progression & UI (4-5 hours)
1. Wave system with spawn rate/enemy count scaling
2. Upgrade menu every 3 waves
3. Score display + combo multiplier
4. HUD (current wave, HP, lives, score, combo)
5. Pause menu

### Phase 5: Audio (2-3 hours)
1. Gunshot SFX (per weapon type)
2. Enemy hit/death sounds
3. Upgrade menu music
4. Background gameplay music
5. Dodge whoosh sound

### Phase 6: Polish & Visuals (3-4 hours)
1. Dodge effects (trails, glow, screen effects)
2. Impact particles (bullets hitting enemies)
3. Enemy death effects
4. Weapon fire effects (muzzle flash)
5. UI animations

### Phase 7: Testing & Balance (3-4 hours)
1. Playtest waves 1-15+
2. Rebalance difficulty if needed
3. Fix bugs, optimize performance
4. Final polish

---

## STRICT SCOPE
Do NOT add features not in this document!