const std = @import("std");
const toolbox = @import("toolbox");

const HIGH_BITS = @embedFile("136022-106.8d");
const LOW_BITS = @embedFile("136022-107.8b");
const PIXELS_PER_BYTE = 4;
const TILE_W = 8;
const TILE_H = 16;
const TILE_BYTE_W = TILE_W / PIXELS_PER_BYTE;
const TILE_BYTE_SIZE = TILE_H * TILE_BYTE_W;
const TOTAL_TILES = 256;

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
    const sprite_image_option = false;
    const generate_red_mask_option = true;
    if (sprite_image_option) {
        write_out_sprite_image();
    } else if (generate_red_mask_option) {
        generate_red_mask();
    } else {
        draw_motion_object_in_terminal(23, 2);
    }
}
fn generate_red_mask() void {
    var masks: [TOTAL_TILES][16]u8 = undefined;
    for (0..TOTAL_TILES, &masks) |tile, *mask| {
        const SCREEN_W = 8;
        const SCREEN_H = 16;
        var screen = [_]u32{0} ** (SCREEN_H * SCREEN_W);
        draw_tile(tile, 0, 0, SCREEN_W, &screen);

        for (0..SCREEN_H, mask) |y, *row| {
            var mask_row: u8 = 0;
            for (0..SCREEN_W) |x| {
                const color = screen[y * SCREEN_W + x];
                const RED_COLOR = 0;
                if (color == RED_COLOR) {
                    mask_row |= @as(u8, 0x80) >> @intCast(x);
                }
            }
            row.* = mask_row;
        }
    }
    toolbox.println("const RED_MASKS = [256][16]u8{{", .{});
    for (masks) |mask| {
        toolbox.print(".{{", .{});
        for (mask[0 .. mask.len - 1]) |row| {
            toolbox.print("0x{X}, ", .{row});
        }

        toolbox.print("0x{X}", .{mask[mask.len - 1]});
        toolbox.println("}},", .{});
    }
    toolbox.println("}};", .{});
}
fn write_out_sprite_image() void {
    const IMAGE_W = TOTAL_TILES * TILE_W;
    const IMAGE_H = TILE_H;

    var screen = [_]u32{0} ** (IMAGE_W * IMAGE_H);
    for (0..TOTAL_TILES) |tile| {
        draw_tile(tile, tile * TILE_W, 0, IMAGE_W, &screen);
    }
    for (&screen) |*px| {
        px.* = COLORS[@intCast(px.*)];
    }
    _ = c.stbi_write_png("sprites-table-8-16.png", IMAGE_W, IMAGE_H, 4, &screen, IMAGE_W * 4);
}

fn draw_motion_object_in_terminal(tile_start: usize, comptime num_tiles: usize) void {
    const SCREEN_W = 16;
    const SCREEN_H = if (num_tiles == 2) 16 else 32;
    var screen = [_]u32{0} ** (SCREEN_H * SCREEN_W);
    var xpos: usize = 0;
    var ypos: usize = 0;
    const tile_offset = tile_start;
    for (tile_offset..tile_offset + num_tiles, 0..) |tile, i| {
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
fn draw_tile_in_terminal(tile: usize) void {
    const SCREEN_W = 8;
    const SCREEN_H = 16;
    var screen = [_]u32{0} ** (SCREEN_H * SCREEN_W);
    draw_tile(tile, 0, 0, SCREEN_W, &screen);
    for (0..SCREEN_H) |y| {
        for (0..SCREEN_W) |x| {
            const color = STDOUT_COLORS[@intCast(screen[y * SCREEN_W + x])];
            std.debug.print("{s}", .{color});
        }
        std.debug.print("\n", .{});
    }
}

fn draw_tile(tile: usize, xpos: usize, ypos: usize, stride: usize, screen: []u32) void {
    const tile_byte_offset = tile * TILE_BYTE_SIZE;
    var x: usize = 0;
    var y: usize = 0;
    for (
        LOW_BITS[tile_byte_offset .. tile_byte_offset + TILE_BYTE_SIZE],
        HIGH_BITS[tile_byte_offset .. tile_byte_offset + TILE_BYTE_SIZE],
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
