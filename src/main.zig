const std = @import("std");
const toolbox = @import("toolbox");
const build_info = @import("build_info");
const pdapi = @import("playdate_api.zig");
const cc = @import("crystal_castles.zig");

pub const THIS_PLATFORM = toolbox.Platform.Playdate;
pub const panic = toolbox.panic_handler;

const PlatformState = struct {
    game_state: *cc.GameState,

    last_frame_time: toolbox.Duration,
    background_image: *pdapi.LCDBitmap,
    castle_bitmap: *pdapi.LCDBitmap,
    frame_arena: *toolbox.Arena,
    global_arena: *toolbox.Arena,
    frame_count: isize,
};

pub export fn eventHandler(playdate: *pdapi.PlaydateAPI, event: pdapi.PDSystemEvent, arg: u32) callconv(.C) c_int {
    _ = arg;
    switch (event) {
        .EventInit => {
            pdapi.set_playdate_api(playdate);
            toolbox.init_playdate_runtime(
                playdate.system.realloc,
                playdate.system.logToConsole,
                playdate.system.@"error",
                playdate.system.getElapsedTime,
                playdate.system.getCurrentTimeMilliseconds,
            );
            pdapi.set_refresh_rate(50);

            const background_image = pdapi.load_bitmap("images/background");
            const castle_bitmap = pdapi.new_bitmap_solid_color(
                cc.SCREEN_WIDTH,
                cc.SCREEN_HEIGHT,
                .ColorClear,
            );
            const font = pdapi.load_font("/System/Fonts/Roobert-10-Bold.pft");
            pdapi.set_font(font);

            const StaticVars = struct {
                var platform_state: PlatformState = undefined;
            };
            const frame_arena = toolbox.Arena.init(toolbox.kb(512));
            const global_arena = toolbox.Arena.init(toolbox.mb(2));
            StaticVars.platform_state = .{
                .background_image = background_image,
                .frame_arena = frame_arena,
                .global_arena = global_arena,
                .game_state = global_arena.push(cc.GameState),
                .last_frame_time = toolbox.now(),
                .castle_bitmap = castle_bitmap,
                .frame_count = 0,
            };

            cc.init(
                StaticVars.platform_state.game_state,
                StaticVars.platform_state.global_arena,
            );

            pdapi.set_update_callback(update_and_render, &StaticVars.platform_state);
        },
        else => {},
    }
    return 0;
}

var go: bool = false;
fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    const platform_state: *PlatformState = @ptrCast(@alignCast(userdata.?));
    const game_state = platform_state.game_state;
    defer {
        platform_state.frame_arena.reset();
        platform_state.frame_count +%= 1;
    }

    const now = toolbox.now();
    const dt = now.subtract(platform_state.last_frame_time);
    platform_state.last_frame_time = now;

    //TODO: debug code, delete
    // if (pdapi.is_button_pressed(pdapi.BUTTON_A)) {
    //     go = true;
    // }
    // if (go) {
    cc.update(dt, game_state);
    update_castle_bitmap(dt, platform_state);
    // }

    // if (pdapi.is_button_pressed(pdapi.BUTTON_A)) {
    //     update_castle_bitmap(dt, platform_state);
    // }
    const background_image = platform_state.background_image;

    pdapi.clear_screen(pdapi.LCDSolidColor.ColorWhite);

    //draw game
    {
        const game_offset_x =
            (pdapi.LCD_COLUMNS - cc.SCREEN_WIDTH) / 2;
        const game_offset_y =
            (pdapi.LCD_ROWS - cc.SCREEN_HEIGHT) / 2;
        pdapi.set_draw_offset(game_offset_x, game_offset_y);
        defer pdapi.set_draw_offset(0, 0);

        pdapi.set_clip_rect(
            0,
            0,
            cc.SCREEN_WIDTH,
            @intCast(game_state.background_clip_y),
        );
        defer pdapi.clear_clip_rect();
        pdapi.draw_bitmap(
            background_image,
            0,
            0,
            .BitmapUnflipped,
        );
        pdapi.draw_bitmap(platform_state.castle_bitmap, 0, 0, .BitmapUnflipped);
    }
    //draw hud
    {
        const build_number_str =
            toolbox.str8fmt("{}{s}", .{
            build_info.BUILD_NUMBER,
            if (toolbox.IS_DEBUG) "D" else "R",
        }, platform_state.frame_arena);
        const text_width = pdapi.get_text_width(build_number_str.bytes);
        const x = pdapi.LCD_COLUMNS - text_width - 1;
        const y = pdapi.LCD_ROWS - pdapi.get_font_height() - 1;
        _ = pdapi.draw_text(build_number_str.bytes, x, y);
    }
    //draw fps
    {
        pdapi.draw_fps(pdapi.LCD_COLUMNS - 20, 0);
    }

    return 1;
}

const ENABLE_CRANK_TO_DRAW = false;
pub fn update_castle_bitmap(
    dt: toolbox.Duration,
    platform_state: *PlatformState,
) void {
    const number_of_lines_to_draw: usize = b: {
        if (ENABLE_CRANK_TO_DRAW) {
            const crank_change = pdapi.get_crank_change();
            if (crank_change <= 0) {
                return;
            }
            const LINES_PER_DEGREE = 5;
            break :b @intFromFloat(LINES_PER_DEGREE * crank_change);
        } else {
            const dt_ms = dt.milliseconds();
            const LINES_PER_MS = 10;
            break :b @intCast(LINES_PER_MS * dt_ms);
        }
    };
    const castle_bitmap_data = pdapi.get_bitmap_data(platform_state.castle_bitmap);

    const game_state = platform_state.game_state;
    for (0..number_of_lines_to_draw) |_| {
        if (game_state.draw_command_queue.dequeue()) |command| {
            const StaticVars = struct {
                var line_number: isize = 0;
            };
            // toolbox.println("{}: Shape: {s}, Color: {s}, Seg: {}, X: 0x{X}, Y: 0x{X}", .{
            //     StaticVars.line_number,
            //     @tagName(command.shape),
            //     @tagName(command.color),
            //     command.number_of_segments,
            //     command.position[0],
            //     command.position[1] + cc.Y_COORDINATE_OFFSET,
            // });
            StaticVars.line_number += 1;
            switch (command.shape) {
                .Line1 => draw_line1(
                    command.number_of_segments,
                    command.position,
                    command.color,
                    castle_bitmap_data,
                ),
                .Line2 => draw_line2(
                    command.number_of_segments,
                    command.position,
                    command.color,
                    castle_bitmap_data,
                ),
                .Line3 => draw_line3(
                    command.number_of_segments,
                    command.position,
                    command.color,
                    castle_bitmap_data,
                ),
                .Pixel => {
                    draw_pixel(
                        command.position,
                        command.color == .White,
                        castle_bitmap_data,
                    );
                },
                .None => unreachable,
            }
        } else {
            break;
        }
    }
}

inline fn red_modulo(i: usize) bool {
    return i % 4 != 0;
}
inline fn gray_modulo(i: usize) bool {
    return i % 2 != 0;
}
inline fn dark_gray_modulo(i: usize) bool {
    // return i % 2 != 0;
    _ = i;
    return false;
}
fn draw_line1(
    number_of_segments: isize,
    position: cc.V2,
    color: cc.Color,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    var cursor = position;
    const number_of_pixels: usize = @intCast(number_of_segments + 1);

    //TODO bounds check
    for (0..number_of_pixels) |i| {
        const is_white_pixel = switch (color) {
            .White => true,
            .Black => false,
            .Gray => gray_modulo(i),
            .DarkGray => dark_gray_modulo(i),
            .Red => red_modulo(i),
        };
        draw_pixel(
            cursor,
            is_white_pixel,
            castle_bitmap_data,
        );
        cursor += .{ 1, -1 };
    }
}

fn draw_line2(
    number_of_segments: isize,
    position: cc.V2,
    color: cc.Color,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    var cursor = position;
    const number_of_pixels: usize = @intCast(number_of_segments + 1);

    //TODO: so LN.2 (draw_line2) and LN.F2 (draw_line2_fast) routines are very
    //slightly different in the line they draw.
    // Once we implement code that calls LN.2, we will need to enabled below.
    //var x_pixels_drawn: isize = if (fast_version ) 1 else 0;
    if (number_of_segments != cc.FAST_LINE_2_NUM_SEGMENTS) {
        @breakpoint();
    }

    var x_pixels_drawn: isize = 1;

    //TODO bounds check
    for (0..number_of_pixels) |i| {
        const is_white_pixel = switch (color) {
            .White => true,
            .Black => false,
            .Gray => gray_modulo(i),
            .DarkGray => dark_gray_modulo(i),
            .Red => red_modulo(i),
        };
        draw_pixel(
            cursor,
            is_white_pixel,
            castle_bitmap_data,
        );
        x_pixels_drawn += 1;
        cursor += if (@mod(x_pixels_drawn, 4) == 0) .{ -1, -1 } else .{ -1, 0 };
    }
}
fn draw_line3(
    number_of_segments: isize,
    position: cc.V2,
    color: cc.Color,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    var cursor = position;
    const number_of_pixels: usize = @intCast(number_of_segments + 1);

    //TODO bounds check
    for (0..number_of_pixels) |i| {
        const is_white_pixel = switch (color) {
            .White => true,
            .Black => false,
            .Gray => gray_modulo(i),
            .DarkGray => dark_gray_modulo(i),
            .Red => red_modulo(i),
        };
        draw_pixel(cursor, is_white_pixel, castle_bitmap_data);
        cursor -= .{ 0, 1 };
    }
}

inline fn draw_pixel(
    position: cc.V2,
    is_white: bool,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    toolbox.assert(bounds_check(position), "Drawing pixel out of bounds!", .{});
    const dy = position[1];
    const dx_byte = @divTrunc(position[0], 8);
    const dx_bit = @mod(position[0], 8);
    const bitmap_index: usize = @intCast(dy * castle_bitmap_data.row_bytes + dx_byte);
    if (is_white) {
        castle_bitmap_data.data[bitmap_index] |= @as(u8, 0x80) >> @intCast(dx_bit);
    } else {
        castle_bitmap_data.data[bitmap_index] &= ~(@as(u8, 0x80) >> @intCast(dx_bit));
    }
    castle_bitmap_data.mask.?[bitmap_index] |= @as(u8, 0x80) >> @intCast(dx_bit);
}

//TODO remove.  we should not be bounds checking per pixel
fn bounds_check(position: cc.V2) bool {
    return position[0] >= 0 and position[0] < cc.SCREEN_WIDTH and
        position[1] >= 0 and position[1] < cc.SCREEN_HEIGHT;
}
