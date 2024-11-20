
- Swarm erroneously spawns in attract mode
- Add memory consumption
- Some of the entity_life_modes at the start of EN.GP are not correct. The modes toward
    the end of the array should be .Dead and not .Alive
- We probablty want to write some tool to fastforward gamestates.
X Sprite data looks good so far. Though it looks like the bear is the first one drawn.  
    Confirm in move_player_to_destination that the bear is eventually drawn
X Finish crystal_castles.zig:1355
X Walk through entity init loop as is.  May be print out  some debug info
X Enemy is too fast
    X It seems the enemy should be entities E, F and 0x10 since that's fits EN.STA. But it seems the positions are not at these entity offsets?

X When the player turns left, the sprite doesn't change as it should
X Missing movement of enemy
X Score has trailing zeroes