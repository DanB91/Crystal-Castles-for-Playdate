- Change DrawCommand to tagged union
- Fix assert firing when VALIDATE_AGAINST_ARCADE is true
    - Looks like the crystal ball is moving a tiny bit when it shouldn't, but seems to not affect visuals
    - Maybe we can put this on the back burner now...
- Add memory consumption
- Some of the entity_life_modes at the start of EN.GP are not correct. The modes toward
    the end of the array should be .Dead and not .Alive
- We probablty want to write some tool to fastforward gamestates.
X Get enemies to pick up gems
X Swarm erroneously spawns in attract mode
X Sprite data looks good so far. Though it looks like the bear is the first one drawn.  
    Confirm in move_player_to_destination that the bear is eventually drawn
X Finish crystal_castles.zig:1355
X Walk through entity init loop as is.  May be print out  some debug info
X Enemy is too fast
    X It seems the enemy should be entities E, F and 0x10 since that's fits EN.STA. But it seems the positions are not at these entity offsets?

X When the player turns left, the sprite doesn't change as it should
X Missing movement of enemy
X Score has trailing zeroes
X init_attract_mode_state() (GM.AT0) is not complete.  Complete it make sure its called correctly on game initializatin
X Fix long delay between death and scoreboard