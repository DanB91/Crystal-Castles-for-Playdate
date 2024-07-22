const std = @import("std");
const toolbox = @import("toolbox");
const build_info = @import("build_info");
const pdapi = @import("playdate_api.zig");
const cc = @import("crystal_castles.zig");
const profiler = toolbox.profiler;
const fiber = toolbox.fiber;

pub const THIS_PLATFORM = toolbox.Platform.Playdate;
pub const ENABLE_PROFILER = !toolbox.IS_DEBUG;
pub const panic = toolbox.panic_handler;

const PlatformState = struct {
    game_state: *cc.GameState,

    last_frame_time: toolbox.Duration,
    background_image: *pdapi.LCDBitmap,
    motion_object_tiles: *pdapi.LCDBitmapTable,
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

            const background_image = pdapi.load_bitmap("assets/images/background");
            const motion_object_tiles = pdapi.load_bitmap_table("assets/images/motion_objects");
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
            const game_state = global_arena.push(cc.GameState);
            StaticVars.platform_state = .{
                .background_image = background_image,
                .motion_object_tiles = motion_object_tiles,
                .frame_arena = frame_arena,
                .global_arena = global_arena,
                .game_state = game_state,
                .last_frame_time = toolbox.now(),
                .castle_bitmap = castle_bitmap,
                .frame_count = 0,
            };

            cc.init(
                StaticVars.platform_state.game_state,
                StaticVars.platform_state.global_arena,
            );
            fiber.init(global_arena, 2, toolbox.kb(64));
            fiber.go(&cc.update, .{StaticVars.platform_state.game_state});

            pdapi.set_update_callback(update_and_render, &StaticVars.platform_state);
        },
        else => {},
    }
    return 0;
}

fn update_and_render(userdata: ?*anyopaque) callconv(.C) c_int {
    profiler.start_profiler();
    const platform_state: *PlatformState = @ptrCast(@alignCast(userdata.?));
    const game_state = platform_state.game_state;
    defer {
        platform_state.frame_arena.reset();
        platform_state.frame_count +%= 1;
    }

    const now = toolbox.now();
    const dt = now.subtract(platform_state.last_frame_time);
    platform_state.last_frame_time = now;

    {
        profiler.begin("cc.update");
        game_state.dt = dt;
        fiber.yield();
        profiler.end();
    }
    const command_count: usize = if (game_state.draw_command_queue.rcursor <=
        game_state.draw_command_queue.wcursor)
        game_state.draw_command_queue.wcursor -
            game_state.draw_command_queue.rcursor
    else
        (game_state.draw_command_queue.data.len -
            game_state.draw_command_queue.rcursor) +
            game_state.draw_command_queue.wcursor + 1;
    {
        profiler.begin("update_castle_bitmap");
        update_castle_bitmap(platform_state);
        profiler.end();
    }
    // }

    // if (pdapi.is_button_pressed(pdapi.BUTTON_A)) {
    //     update_castle_bitmap(dt, platform_state);
    // }
    const background_image = platform_state.background_image;

    pdapi.clear_screen(pdapi.LCDSolidColor.ColorWhite);

    //draw game
    {
        profiler.begin("draw game");
        defer profiler.end();

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

        //draw sprites, aka motion objects
        {
            for (game_state.motion_objects) |mo| {
                const tile = pdapi.get_table_bitmap(
                    platform_state.motion_object_tiles,
                    @intCast(mo.picture_number),
                ).?;
                const x: pdapi.Pixel = @intCast(mo.position[0] & 0xFF);
                const y: pdapi.Pixel = @intCast(256 - 16 - (mo.position[1] & 0xFF) - cc.Y_COORDINATE_OFFSET);

                pdapi.draw_bitmap(tile, x, y, .BitmapUnflipped);
                // pdapi.draw_rect(x, y, 8, 16, pdapi.solid_color_to_color(.ColorBlack));
            }
        }
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

    profiler.end_profiler();
    if (pdapi.is_button_down(pdapi.BUTTON_B)) {
        draw_debug_and_profiler_hud(platform_state, command_count);
    }
    //draw fps
    {
        pdapi.draw_fps(pdapi.LCD_COLUMNS - 20, 0);
    }

    return 1;
}

pub fn update_castle_bitmap(
    platform_state: *PlatformState,
) void {
    const castle_bitmap_data = pdapi.get_bitmap_data(platform_state.castle_bitmap);

    const game_state = platform_state.game_state;
    while (game_state.draw_command_queue.dequeue()) |command| {
        const StaticVars = struct {
            var line_number: isize = 0;
        };
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
            .Character => draw_character(
                command.character,
                command.position,
                command.color,
                castle_bitmap_data,
            ),
            .ScreenErase => screen_erase(
                command.position,
                command.number_of_segments,
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
    }
}
fn draw_debug_and_profiler_hud(
    platform_state: *PlatformState,
    command_count: usize,
) void {
    const F = struct {
        fn add_line(
            comptime fmt: []const u8,
            args: anytype,
            lines: *toolbox.DynamicArray(toolbox.String8),
            background_width: *i32,
            arena: *toolbox.Arena,
        ) void {
            const str = toolbox.str8fmt(fmt, args, arena);
            lines.append(str, arena);
            background_width.* = pdapi.get_text_width(str.bytes);
        }
    };
    const game_state = platform_state.game_state;
    var background_width: pdapi.Pixel = 0;

    //TODO draw profiler and other stats
    var lines = toolbox.DynamicArray(toolbox.String8){};
    const arena = platform_state.frame_arena;
    if (false) {
        F.add_line(
            "# draw commands: {}",
            .{command_count},
            &lines,
            &background_width,
            arena,
        );
    }
    lines.append(toolbox.str8lit(""), arena);

    //player position
    {
        F.add_line(
            "x: {X}, y: {X}",
            .{ game_state.entity_position[0][0], game_state.entity_position[0][1] },
            &lines,
            &background_width,
            arena,
        );
        F.add_line(
            "fine x: {X}, fine y: {X}",
            .{ game_state.entity_fine_position[0][0], game_state.entity_fine_position[0][1] },
            &lines,
            &background_width,
            arena,
        );
    }

    //TODO: this is too many lines.  need smaller font
    // _ = game_state;
    if (false) {
        for (game_state.motion_objects) |mo| {
            const x: pdapi.Pixel = @intCast(mo.position[0]);
            const y: pdapi.Pixel = @intCast(256 - 16 - (mo.position[1] & 0xFF) - cc.Y_COORDINATE_OFFSET);
            if (mo.picture_number != 0) {
                F.add_line(
                    "Sprite : Tile: {}, X: {}, Y: {}, flags: {}",
                    .{ mo.picture_number, x, y, mo.flags },
                    &lines,
                    &background_width,
                    arena,
                );
            }
        }
    }
    if (comptime ENABLE_PROFILER) {
        const stats = toolbox.profiler.compute_statistics_of_current_state(
            platform_state.frame_arena,
        );
        {
            F.add_line(
                "Frame Time: {}mcs",
                .{stats.total_elapsed.microseconds()},
                &lines,
                &background_width,
                arena,
            );
        }
        for (stats.section_statistics.items()) |stat| {
            const str = stat.str8(platform_state.frame_arena);
            F.add_line(
                "{}",
                .{str},
                &lines,
                &background_width,
                arena,
            );
        }
    }

    const background_height = pdapi.get_font_height() * @as(
        pdapi.Pixel,
        @intCast(lines.len),
    );
    pdapi.fill_rect(
        0,
        0,
        background_width,
        background_height,
        pdapi.solid_color_to_color(pdapi.LCDSolidColor.ColorWhite),
    );
    var y: pdapi.Pixel = 0;
    for (lines.items()) |line| {
        _ = pdapi.draw_text(line.bytes, 0, y);
        y += pdapi.get_font_height();
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
fn draw_character(
    char: isize,
    position: cc.V2,
    color: cc.Color,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    //	TRAI 000 HW.AY	; y auto dec
    // 	TRAI 0FF HW.YIN

    // 	TRAM AL.X XB
    // 	LDY AL.DIG
    // 	CPY #4A
    // 	IFMI
    // 	 TR16AI AL.55D AL.PTR
    // 	 TYA
    // 	 SUB #40
    // 	ELSE
    // 	 TR16AI AL.55L AL.PTR
    // 	 TYA
    // 	 SUB #4A
    // 	ENDIF

    var bitmap_index_start: usize = 0;
    var bitmap_set: []const u8 = undefined;
    switch (char) {
        '0'...'9' => {
            bitmap_index_start = @intCast((char - '0') * cc.CHARACTER_BITMAP_WIDTH);
            bitmap_set = &cc.NUMBER_BITMAPS;
        },
        'A'...'A' + cc.LETTER_BITMAPS.len => {
            bitmap_index_start = @intCast((char - 'A') * cc.CHARACTER_BITMAP_WIDTH);
            bitmap_set = &cc.LETTER_BITMAPS;
        },
        else => toolbox.panic("Trying to draw nvalid character: {X}", .{char}),
    }

    // 	JSR AL.5OT

    // AL.5OT:
    {
        var position_cursor = position;
        // 	STA TEMP1	;  mult by 5 so (A) points to sym
        // 	ASLS 2
        // 	ADD TEMP1
        // 	STA TEMP1

        // 	TRAI 5 AL.TMP
        // 	LDX AL.COL
        // 10$:
        var i: usize = 0;
        for (0..cc.CHARACTER_BITMAP_WIDTH) |x| {
            // 	LDY TEMP1
            // 	TRAM AL.Y YB
            position_cursor[1] = position[1];
            const bitmap_index = bitmap_index_start + x;
            // 	LDA @AL.PTR(Y)
            var character_row = bitmap_set[bitmap_index];
            // 	LDY #0F
            // 	.REPT 5
            for (0..cc.CHARACTER_BITMAP_HEIGHT) |_| {
                // 	ASL
                // 	IFCS
                if (character_row & 0x80 != 0) {
                    // 	STX VB
                    const is_white_pixel = switch (color) {
                        .White => true,
                        .Black => false,
                        .Gray => gray_modulo(i),
                        .DarkGray => dark_gray_modulo(i),
                        .Red => red_modulo(i),
                    };
                    draw_pixel(
                        position_cursor,
                        is_white_pixel,
                        castle_bitmap_data,
                    );
                    i += 1;
                    // 	ENDIF
                }
                //NOTE: this code just causes auto increment
                // 	IFCC
                // 	LDY VB
                //  	ENDIF

                // ;	DEC YB
                position_cursor -= .{ 0, 1 };
                // 	.ENDM

                character_row <<= 1;
            }

            // 	INC XB
            position_cursor += .{ 1, 0 };
            // 	INC TEMP1
            // 	DEC AL.TMP
            // 	BNE 10$
        }
    }
    // 8$:
    // 	TRAI 0FF HW.AY	; auto dec off
}

fn screen_erase(
    start_position: cc.V2,
    number_of_pixel_columns_to_erase: isize,
    castle_bitmap_data: pdapi.BitmapData,
) void {
    //  STA TEMP1
    var column_cursor = number_of_pixel_columns_to_erase;
    // 	LDA AL.X
    // 	STA XB
    // 	LDA AL.Y
    // 	STA YB
    // 	INC YB
    var position = start_position + cc.V2{ 0, 1 };

    // 	TRAI 000 HW.AY	; auto dec y
    // 	TRAI 0FF HW.YIN

    // 	LDA #00F
    // 	INC TEMP1
    // 10$:
    // 	DEC TEMP1
    // 	BEQ 20$
    while (column_cursor > 0) {
        // 	STA VB
        // 	.REPT 7
        for (0..8) |_| {
            // ;	DEC YB
            // 	STA VB
            // 	.ENDM

            //NOTE: screen erase is always black
            draw_pixel(
                position,
                false,
                castle_bitmap_data,
            );

            position[1] -= 1;
        }
        // 	INC XB
        position[0] += 1;
        // 	LDY AL.Y
        // 	STY YB
        // 	INC YB
        position[1] = start_position[1] + 1;

        column_cursor -= 1;
        // 	JMP 10$
    }
    // 20$:
    // 	TRAI 0FF HW.AY
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
