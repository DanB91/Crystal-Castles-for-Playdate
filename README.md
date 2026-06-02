# Crystal Castles

## What is this?

Port of the 1983 Atari arcade game Crystal Castles to Playdate written in Zig.  Reverse engineered from the original 6502 assembly and MAME implementation.

## Requirements

- Either macOS, Windows, or Linux.
- Zig compiler 0.16.0.  Newer version may work, but have not tested
- [Playdate SDK](https://play.date/dev/) 3.0 or later installed.

## Quick Start

1. Make sure the Playdate SDK is installed, Zig is installed and in your PATH, and all other requirements]are met.
1. Make sure the Playdate Simulator is closed.
1. Run `zig build  -Doptimize=ReleaseFast run`.
    1. If there any errors, double check `PLAYDATE_SDK_PATH` is correctly set.
1. Optionally, connect your Playdate to the comupter and upload to the device by going to `Device` -> `Upload Game to Device..` in the Playdate Simulator.
    1. It should load and run on the hardware as well!
1. To start the game, press `B` to insert a coin, and then press `A` to start. (Mashing `A` without inserting a coin won't do you any good.)
1. Only the first level is implemented.  Once you beat the first level, the game will crash.

## Controls

- `D-Pad` -> Move Bentley Bear
- `A`     ->  Start Game or Jump
- `B`     -> Insert Coin or Hold to Run

## Status

Currently this project is on hold and haven't worked on it in over 2 years at the time of this writing. Only the attract screen and the first level are implemented. Sound is not implemented.  This repo is also a bit of a mess.  Though, I feel the source code ported to a higher level language may be of interest to some people (which is the primary reason why I am releasing it now).  Will I come back to it in the future? Maybe...

## Contact

If you have any questions about how this port works, or Crystal Castle reverse-engineering in general, you can email me at [dan@boksos.com](mailto:dan@boksos.com).
