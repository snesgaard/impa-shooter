# Features
- [x] Tile physics
- [x] Hitbox overlap detection
- [x] Redo moveset using coroutines and global data structure
- [ ] Overlap resolver for entities
- [ ] Hitbox allocation and processing
- [ ] Mobolee reimplemented using coroutines and global data structure
- [ ] Stamina damage and recovery system

# Weapon Ideas
## Rifle
The rifle is a long range weapon which fires projectiles in a straight, fast,
horizontal trajectory. It has limited ammunition (like 3 or 4) and when these
has been exhauted a reload must be performed. However if the reload button is
pressed shortly after firing the rifle, a round will be reloaded. In addition
a slight damage buff will be granted for a short duration. This can be chained
with the buff becoming increasingly better. It could for example stack 3 times
and at the highest level grant enemy penetration.
The timer should be louse so that the ispressed defition can stretch from a
non-combo frame to a combo frame

## Sling
The sling launches a projectile in a ballistic arc. When the projectile connects
with an enemy or the terrain it will explode, doing AOE damage. When initiating
the firing sequence, there will be a brief window in which the player may hit
the reload button to add an additional swing. This will confer a damage bonus
and increase the affected area. This effect may be chained, each added swing
having a smaller timing window (as the swing speed is increased).
