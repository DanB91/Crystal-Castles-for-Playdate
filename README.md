# Crystal Castles

## Overview

Port of the 1983 Atari arcade game Crystal Castles

## Requirements

- Either macOS, Windows, or Linux.
- Zig compiler 0.16.0.  Newer version may work, but have not tested
- [Playdate SDK](https://play.date/dev/) 3.0 or later installed.

## Build and Run the Game

1. Make sure the Playdate SDK is installed, Zig is installed and in your PATH, and all other requirements]are met.
1. Make sure the Playdate Simulator is closed.
1. Run `zig build run`.
    1. If there any errors, double check `PLAYDATE_SDK_PATH` is correctly set.
1. Optionally, connect your Playdate to the comupter and upload to the device by going to `Device` -> `Upload Game to Device..` in the Playdate Simulator.
    1. It should load and run on the hardware as well!
