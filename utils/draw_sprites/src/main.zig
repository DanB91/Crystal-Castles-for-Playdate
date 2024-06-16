const std = @import("std");
const toolbox = @import("toolbox");

const high_bits = @embedFile("136022-106.8d");
const low_bits = @embedFile("136022-107.8b");
const PIXELS_PER_BYTE = 4;
const TILE_W = 8;
const TILE_H = 16;
const TILE_BYTE_W = TILE_W / PIXELS_PER_BYTE;
const TILE_BYTE_SIZE = TILE_H * TILE_BYTE_W;

const c = @cImport({
    @cInclude("stb_image_write.h");
});

//NOTE: data and red flag are inverted to calculate color value.
//      So if red flag 1, it's actually a 0 and vice versa.

//NOTE: color 7 is actually transparent
// Drawing color 0xFFFFFFFF for pixel data 0x0, Red flag: 0, Offset: 7

// Drawing color 0xFF009700 for pixel data 0xFB, Red flag: 1, Offset: 6
// Drawing color 0xFF684768 for pixel data 0x25, Red flag: 1, Offset: 5
// Drawing color 0xFFFFB820 for pixel data 0x32, Red flag: 0, Offset: 4
// Drawing color 0xFF47B820 for pixel data 0x72, Red flag: 1, Offset: 3
// Drawing color 0xFF684720 for pixel data 0x35, Red flag: 1, Offset: 2
// Drawing color 0xFFB89747 for pixel data 0xAB, Red flag: 0, Offset: 1
// Drawing color 0xFFFF0000 for pixel data 0x3F, Red flag: 0, Offset: 0

const STDOUT_COLORS = [_][]const u8{ "🟥", "🟠", "🟫", "🟩", "🟧", "🟪", "🌲", "⚫️" };
const COLORS = [8]u32{
    0xFF0000FF,
    0xFF4797B8,
    0xFF204768,
    0xFF20B847,
    0xFF20B8FF,
    0xFF684768,
    0xFF009700,
    0,
};
pub fn main() !void {
    // const TOTAL_TILES = 256;
    // const IMAGE_W = TOTAL_TILES * TILE_W;
    // const IMAGE_H = TILE_H;

    // var screen = [_]u32{0} ** (IMAGE_W * IMAGE_H);
    // for (0..TOTAL_TILES) |tile| {
    //     draw_tile(tile, tile * TILE_W, 0, IMAGE_W, &screen);
    // }
    // for (&screen) |*px| {
    //     px.* = COLORS[@intCast(px.*)];
    // }
    // _ = c.stbi_write_png("sprites-table-8-16.png", IMAGE_W, IMAGE_H, 4, &screen, IMAGE_W * 4);
    test_in_terminal();
}
fn test_in_terminal() void {
    const SCREEN_W = 16;
    const SCREEN_H = 32;
    //const motion_object = 0;
    for (0x1..0x2) |motion_object| {
        var screen = [_]u32{0} ** (SCREEN_H * SCREEN_W);
        var xpos: usize = 0;
        var ypos: usize = 0;
        const NUM_TILES = 4;
        const tile_offset = motion_object * NUM_TILES + 1;
        for (tile_offset..tile_offset + NUM_TILES, 0..) |tile, i| {
            draw_tile(tile, xpos, ypos, SCREEN_W, &screen);
            switch (i) {
                0 => {
                    xpos = 8;
                    ypos = 0;
                },
                1 => {
                    xpos = 0;
                    ypos = 16;
                },
                2 => {
                    xpos = 8;
                    ypos = 16;
                },
                3 => {},
                else => unreachable,
            }
        }
        for (0..SCREEN_H) |y| {
            for (0..SCREEN_W) |x| {
                const color = STDOUT_COLORS[@intCast(screen[y * SCREEN_W + x])];
                std.debug.print("{s}", .{color});
            }
            std.debug.print("\n", .{});
        }
    }
}

fn draw_tile(tile: usize, xpos: usize, ypos: usize, stride: usize, screen: []u32) void {
    const tile_byte_offset = tile * TILE_BYTE_SIZE;
    var x: usize = 0;
    var y: usize = 0;
    for (
        low_bits[tile_byte_offset .. tile_byte_offset + TILE_BYTE_SIZE],
        high_bits[tile_byte_offset .. tile_byte_offset + TILE_BYTE_SIZE],
    ) |l, h| {
        for (0..PIXELS_PER_BYTE) |p| {
            var color_index: u32 = 0;
            const pu3: u3 = @intCast(p);
            color_index |= ((l >> (3 - pu3)) & 1) << 0; // bit 0
            color_index |= ((l >> (7 - pu3)) & 1) << 1; // bit 1
            color_index |= ((h >> (3 - pu3)) & 1) << 2; // bit 2
            screen[(y + ypos) * stride + (x + xpos)] = color_index;
            x += 1;
            if (x >= 8) {
                x = 0;
                y += 1;
            }
        }
    }
}
