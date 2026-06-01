const std = @import("std");
const toolbox = @import("toolbox");
const pddefs = @import("playdate_api_definitions.zig");

pub const Pixel = i32;
pub const LCDPatternSlice = *const [16]u8;
pub const PlaydateAPI = pddefs.PlaydateAPI;
pub const PDSystemEvent = pddefs.PDSystemEvent;
pub const PDButtons = pddefs.PDButtons;
pub const PDCallbackFunction = pddefs.PDCallbackFunction;
pub const LCDBitmapDrawMode = pddefs.LCDBitmapDrawMode;
pub const LCDSolidColor = pddefs.LCDSolidColor;
pub const LCDPattern = pddefs.LCDPattern;
pub const LCDFont = pddefs.LCDFont;
pub const PDTextWrappingMode = pddefs.PDTextWrappingMode;
pub const PDTextAlignment = pddefs.PDTextAlignment;
pub const LCDColor = pddefs.LCDColor;
pub const LCDBitmapTable = pddefs.LCDBitmapTable;
pub const LCDBitmpFlip = pddefs.LCDBitmapFlip;
pub const LCDBitmapFlip = pddefs.LCDBitmapFlip;
pub const LCDBitmap = pddefs.LCDBitmap;
pub const PDMenuItemCallbackFunction = pddefs.PDMenuItemCallbackFunction;
pub const PDMenuItem = pddefs.PDMenuItem;
pub const SDFile = pddefs.SDFile;
pub const FileOptions = pddefs.FileOptions;
pub const FileStat = pddefs.FileStat;
pub const SoundChannel = pddefs.SoundChannel;
pub const FilePlayer = pddefs.FilePlayer;
pub const SoundSource = pddefs.SoundSource;
pub const SamplePlayer = pddefs.SamplePlayer;
pub const AudioSample = pddefs.AudioSample;
pub const MIDINote = pddefs.MIDINote;
pub const PDSynth = pddefs.PDSynth;
pub const SoundWaveform = pddefs.SoundWaveform;

pub const FILE_READ = pddefs.FILE_READ;
pub const LCD_COLUMNS = pddefs.LCD_COLUMNS;
pub const LCD_ROWS = pddefs.LCD_ROWS;

pub const BUTTON_LEFT = pddefs.BUTTON_LEFT;
pub const BUTTON_RIGHT = pddefs.BUTTON_RIGHT;
pub const BUTTON_UP = pddefs.BUTTON_UP;
pub const BUTTON_DOWN = pddefs.BUTTON_DOWN;
pub const BUTTON_A = pddefs.BUTTON_A;
pub const BUTTON_B = pddefs.BUTTON_B;

var pd: *pddefs.PlaydateAPI = undefined;
var current_font: *pddefs.LCDFont = undefined;

pub inline fn set_playdate_api(playdate: *pddefs.PlaydateAPI) void {
    pd = playdate;
}

pub inline fn is_button_pressed(button: pddefs.PDButtons) bool {
    var pressed: pddefs.PDButtons = 0;
    get_button_state(null, &pressed, null);

    return pressed & button != 0;
}

pub inline fn is_button_down(button: pddefs.PDButtons) bool {
    var down: pddefs.PDButtons = 0;
    get_button_state(&down, null, null);

    return down & button != 0;
}
pub inline fn is_chord_pressed(chord: pddefs.PDButtons) bool {
    var down: pddefs.PDButtons = 0;
    var pressed: pddefs.PDButtons = 0;
    get_button_state(&down, &pressed, null);

    if (chord & pressed == 0) {
        return false;
    }

    return ((down | pressed) & chord) == chord;
}

pub inline fn get_button_state(current: ?*pddefs.PDButtons, pushed: ?*pddefs.PDButtons, released: ?*pddefs.PDButtons) void {
    pd.system.getButtonState(current, pushed, released);
}

pub inline fn set_update_callback(callback: ?pddefs.PDCallbackFunction, userdata: ?*anyopaque) void {
    pd.system.setUpdateCallback(callback, userdata);
}

//Draw Color
pub inline fn solid_color_to_color(solid_color: pddefs.LCDSolidColor) pddefs.LCDColor {
    return @as(usize, @intCast(@intFromEnum(solid_color)));
}
pub inline fn pattern_to_color(pattern: LCDPatternSlice) pddefs.LCDColor {
    return @as(usize, @intCast(@intFromPtr(pattern.ptr)));
}
pub inline fn set_draw_mode(mode: pddefs.LCDBitmapDrawMode) void {
    pd.graphics.setDrawMode(mode);
}
/////Draw context
pub inline fn push_drawing_context(target: ?*pddefs.LCDBitmap) void {
    pd.graphics.pushContext(target);
}
pub inline fn pop_drawing_context() void {
    pd.graphics.popContext();
}

////Draw clipping
pub inline fn set_clip_rect(x: Pixel, y: Pixel, width: Pixel, height: Pixel) void {
    pd.graphics.setClipRect(x, y, width, height);
}
pub inline fn clear_clip_rect() void {
    pd.graphics.clearClipRect();
}

////Screen
pub inline fn clear_screen(color: pddefs.LCDSolidColor) void {
    pd.graphics.clear(@as(pddefs.LCDColor, @intCast(@intFromEnum(color))));
}
pub inline fn set_screen_clip_rect(x: Pixel, y: Pixel, width: Pixel, height: Pixel) void {
    pd.graphics.setScreenClipRect(x, y, width, height);
}

pub inline fn set_refresh_rate(comptime refresh_rate: f32) void {
    pd.display.setRefreshRate(refresh_rate);
}

pub inline fn set_draw_offset(x: Pixel, y: Pixel) void {
    pd.graphics.setDrawOffset(x, y);
}

pub inline fn get_frame_buffer() []u8 {
    return pd.graphics.getFrame()[0 .. pddefs.LCD_ROWS * pddefs.LCD_ROWSIZE];
}

pub inline fn mark_updated_rows(start: i32, end: i32) void {
    pd.graphics.markUpdatedRows(start, end);
}

////Fonts and text
pub inline fn load_font(path: [*c]const u8) *pddefs.LCDFont {
    var err: [*c]const u8 = undefined;
    const font_opt = pd.graphics.loadFont(path, &err);
    if (font_opt) |font| {
        return font;
    }
    toolbox.panic("Error loading font: {s}", .{err});
}
pub inline fn free_font(font: *pddefs.LCDFont) void {
    _ = font;
    //TODO: there doesn't seem to be a free font function
    //pd.graphics.freeFont(font);
}
pub inline fn set_font(font: *pddefs.LCDFont) void {
    current_font = font;
    pd.graphics.setFont(font);
}
pub inline fn get_font() *pddefs.LCDFont {
    return current_font;
}

pub inline fn draw_text(text: []const u8, x: Pixel, y: Pixel) Pixel {
    return pd.graphics.drawText(text.ptr, text.len, .UTF8Encoding, x, y);
}
pub inline fn draw_fmt(comptime fmt: []const u8, args: anytype, x: Pixel, y: Pixel) Pixel {
    var buffer = [_]u8{0} ** 128;
    const to_print = std.fmt.bufPrintZ(&buffer, fmt, args) catch |e| toolbox.panic("draw_fmt failed:  {}", .{e});
    return draw_text(to_print, x, y);
}
pub inline fn get_text_width(text: []const u8) Pixel {
    return pd.graphics.getTextWidth(current_font, text.ptr, text.len, .UTF8Encoding, 0);
}
pub inline fn get_fmt_width(comptime fmt: []const u8, args: anytype) Pixel {
    var buffer = [_]u8{0} ** 128;
    const to_count = std.fmt.bufPrintZ(&buffer, fmt, args) catch |e| toolbox.panic("draw_fmt failed:  {}", .{e});
    return pd.graphics.getTextWidth(current_font, to_count.ptr, to_count.len, .UTF8Encoding, 0);
}
pub inline fn get_font_height() Pixel {
    return pd.graphics.getFontHeight(current_font);
}

pub inline fn draw_fps(x: Pixel, y: Pixel) void {
    pd.system.drawFPS(x, y);
}

////Bitmap
pub inline fn load_bitmap_table(path: [*c]const u8) *pddefs.LCDBitmapTable {
    var err: [*c]const u8 = undefined;
    const bitmap_table_opt = pd.graphics.loadBitmapTable(path, &err);
    if (bitmap_table_opt) |bitmap_table| {
        return bitmap_table;
    }
    toolbox.panic("Error loading bitmap table: {s}", .{err});
}
pub inline fn free_bitmap_table(bitmap_table: *pddefs.LCDBitmapTable) void {
    pd.graphics.freeBitmapTable(bitmap_table);
}

pub inline fn load_bitmap(path: [*c]const u8) *pddefs.LCDBitmap {
    var err: [*c]const u8 = undefined;
    const bitmap_opt = pd.graphics.loadBitmap(path, &err);
    if (bitmap_opt) |bitmap| {
        return bitmap;
    }
    toolbox.panic("Error loading bitmap: {s}", .{err});
}
pub inline fn new_bitmap_solid_color(
    width: i32,
    height: i32,
    inital_color: pddefs.LCDSolidColor,
) *pddefs.LCDBitmap {
    const result = pd.graphics.newBitmap(
        width,
        height,
        solid_color_to_color(inital_color),
    );
    if (result) |bitmap| {
        return bitmap;
    }
    toolbox.panic("Error creating bitmap. Out of memory.", .{});
}
pub inline fn free_bitmap(bitmap: *pddefs.LCDBitmap) void {
    pd.graphics.freeBitmap(bitmap);
}

pub const BitmapData = struct {
    width: i32,
    height: i32,
    row_bytes: i32,
    mask: ?[]u8,
    data: []u8,
};

pub fn get_bitmap_data(bitmap: *pddefs.LCDBitmap) BitmapData {
    var width: i32 = 0;
    var height: i32 = 0;
    var row_bytes: i32 = 0;
    var mask_opt: [*c]u8 = null;
    var data_opt: [*c]u8 = null;

    pd.graphics.getBitmapData(
        bitmap,
        &width,
        &height,
        &row_bytes,
        &mask_opt,
        &data_opt,
    );

    const data_size = @as(usize, @intCast(row_bytes * height));
    return .{
        .width = width,
        .height = height,
        .row_bytes = row_bytes,
        .mask = if (mask_opt) |mask| mask[0..data_size] else null,
        .data = data_opt[0..data_size],
    };
}

pub inline fn get_table_bitmap(table: *pddefs.LCDBitmapTable, index: i32) ?*pddefs.LCDBitmap {
    const table_bitmap = pd.graphics.getTableBitmap(table, @as(c_int, @intCast(index)));
    return table_bitmap;
}
pub fn get_table_bitmap_size(table: *pddefs.LCDBitmapTable) i32 {
    var ret: i32 = 0;
    while (get_table_bitmap(table, ret)) |_| {
        ret += 1;
    }
    return ret;
}
pub inline fn tile_bitmap(bitmap: *pddefs.LCDBitmap, x: Pixel, y: Pixel, width: Pixel, height: Pixel, flip: pddefs.LCDBitmapFlip) void {
    pd.graphics.tileBitmap(bitmap, x, y, width, height, flip);
}
pub inline fn draw_bitmap(bitmap: *pddefs.LCDBitmap, x: Pixel, y: Pixel, flip: pddefs.LCDBitmapFlip) void {
    pd.graphics.drawBitmap(bitmap, x, y, flip);
}
pub inline fn draw_scaled_bitmap(bitmap: *pddefs.LCDBitmap, x: Pixel, y: Pixel, xscale: f32, yscale: f32) void {
    pd.graphics.drawScaledBitmap(bitmap, x, y, xscale, yscale);
}

//Shapes
pub inline fn draw_rect(x: Pixel, y: Pixel, width: Pixel, height: Pixel, color: pddefs.LCDColor) void {
    pd.graphics.drawRect(x, y, width, height, color);
}

pub inline fn fill_rect(x: Pixel, y: Pixel, width: Pixel, height: Pixel, color: pddefs.LCDColor) void {
    pd.graphics.fillRect(x, y, width, height, color);
}

pub inline fn draw_ellipse(x: Pixel, y: Pixel, width: Pixel, height: Pixel, lineWidth: Pixel, startAngle: f32, endAngle: f32, color: pddefs.LCDColor) void {
    pd.graphics.drawEllipse(x, y, width, height, lineWidth, startAngle, endAngle, color);
}
pub inline fn fill_ellipse(x: Pixel, y: Pixel, width: Pixel, height: Pixel, startAngle: f32, endAngle: f32, color: pddefs.LCDColor) void {
    pd.graphics.fillEllipse(x, y, width, height, startAngle, endAngle, color);
}

//Crank
pub inline fn get_crank_change() f32 {
    return pd.system.getCrankChange();
}
pub inline fn get_crank_angle() f32 {
    return pd.system.getCrankAngle();
}
pub inline fn is_crank_docked() bool {
    return pd.system.isCrankDocked() != 0;
}
pub inline fn set_crank_sounds_disabled(flag: bool) bool {
    return pd.system.setCrankSoundsDisabled(if (flag) 1 else 0) != 0; // returns previous setting
}

//Menu items
pub inline fn add_menu_item(
    title: [:0]const u8,
    callback: ?pddefs.PDMenuItemCallbackFunction,
    userdata: ?*anyopaque,
) *pddefs.PDMenuItem {
    return pd.system.addMenuItem(title.ptr, callback, userdata).?;
}
pub inline fn add_options_menu_item(
    title: [:0]const u8,
    callback: ?pddefs.PDMenuItemCallbackFunction,
    option_titles: [][*c]const u8,
    userdata: ?*anyopaque,
) *pddefs.PDMenuItem {
    return pd.system.addOptionsMenuItem(
        title.ptr,
        option_titles.ptr,
        @as(c_int, @intCast(option_titles.len)),
        callback,
        userdata,
    ).?;
}
pub inline fn get_menu_item_value(menu_item: *pddefs.PDMenuItem) i32 {
    return @as(i32, @intCast(pd.system.getMenuItemValue(menu_item)));
}
pub inline fn get_menu_item_value_bool(menu_item: *pddefs.PDMenuItem) bool {
    return get_menu_item_value(menu_item) != 0;
}
pub inline fn set_menu_item_value(menu_item: *pddefs.PDMenuItem, value: i32) void {
    pd.system.setMenuItemValue(menu_item, @as(c_int, @intCast(value)));
}
pub inline fn set_menu_item_value_bool(menu_item: *pddefs.PDMenuItem, value: bool) void {
    get_menu_item_value(menu_item, if (value) 1 else 0);
}
pub inline fn remove_menu_item(menu_item: *pddefs.PDMenuItem) void {
    pd.system.removeMenuItem(menu_item);
}

//File API
pub fn FileResult(comptime Value: type) type {
    return union(enum) {
        Ok: Value,
        Error: []const u8,
    };
}
pub inline fn open_file(path: [:0]const u8, mode: pddefs.FileOptions) FileResult(*pddefs.SDFile) {
    if (pd.file.open(path.ptr, mode)) |file| {
        return .{ .Ok = file };
    } else {
        return .{ .Error = std.mem.span(pd.file.geterr()) };
    }
}
pub inline fn close_file(file: *pddefs.SDFile) void {
    _ = pd.file.close(file);
}
pub inline fn flush_file(file: *pddefs.SDFile) void {
    _ = pd.file.flush(file);
}
pub fn read_file(file: *pddefs.SDFile, buffer: []u8) FileResult([]const u8) {
    const bytes_read = pd.file.read(file, buffer.ptr, @as(c_uint, @intCast(buffer.len)));
    if (bytes_read >= 0) {
        if (bytes_read <= buffer.len) {
            return .{ .Ok = buffer[0..@as(usize, @intCast(bytes_read))] };
        } else {
            return .{ .Error = "Read unexpected number of bytes" };
        }
    } else {
        return .{ .Error = std.mem.span(pd.file.geterr()) };
    }
}
pub fn write_file(file: *pddefs.SDFile, buffer: []const u8) FileResult(void) {
    var bytes_written: usize = 0;
    while (bytes_written < buffer.len) {
        const result = pd.file.write(file, buffer.ptr, @as(c_uint, @intCast(buffer.len)));
        if (result >= 0) {
            bytes_written += @as(usize, @intCast(result));
        } else {
            return .{ .Error = std.mem.span(pd.file.geterr()) };
        }
    }
    return .Ok;
}
pub inline fn mkdir(path: [:0]const u8) void {
    _ = pd.file.mkdir(path.ptr);
}
pub inline fn rename_file(from: [:0]const u8, to: [:0]const u8) bool {
    return pd.file.rename(from.ptr, to.ptr) == 0;
}

const ListFilesContext = struct {
    paths_buffer: [][]const u8,
    arena: *toolbox.Arena,
    number_of_paths: usize,
};
pub fn list_files(path: [:0]const u8, arena: *toolbox.Arena) [][]const u8 {
    const MAX_FILES = 256;
    var context = ListFilesContext{
        .paths_buffer = arena.push_slice([]const u8, MAX_FILES),
        .number_of_paths = 0,
        .arena = arena,
    };
    const result = pd.file.listfiles(path.ptr, list_files_callback, &context, 1);
    if (result != 0) {
        toolbox.panic("List files failed: {s}", .{pd.file.geterr()});
    }
    return context.paths_buffer[0..context.number_of_paths];
}
fn list_files_callback(path: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
    const context = @as(*ListFilesContext, @ptrCast(@alignCast(userdata)));
    const path_slice = std.mem.span(path);

    const result_path = context.arena.push_slice(u8, path_slice.len);
    for (result_path, 0..) |*c, i| c.* = path[i];

    context.paths_buffer[context.number_of_paths] = result_path;
    context.number_of_paths += 1;
}

//Time API
pub const Seconds = f32;
pub inline fn now_in_seconds() Seconds {
    return pd.system.getElapsedTime();
}
pub inline fn reset_system_clock() void {
    pd.system.resetElapsedTime();
}

//Sound API
pub inline fn get_default_sound_channel() *pddefs.SoundChannel {
    return pd.sound.getDefaultChannel().?;
}
pub inline fn add_sound_source(
    channel: *pddefs.SoundChannel,
    sound_source: *pddefs.SoundSource,
) !void {
    if (pd.sound.channel.addSource(channel, sound_source) == 0) {
        return error.CouldNotAddSoundSource;
    }
}
pub inline fn new_sound_file_player() *pddefs.FilePlayer {
    return pd.sound.fileplayer.newPlayer().?;
}
pub inline fn free_sound_file_player(player: *pddefs.FilePlayer) void {
    pd.sound.fileplayer.freePlayer(player);
}
pub inline fn load_into_sound_file_player(player: *pddefs.FilePlayer, path: []const u8) !void {
    if (pd.sound.fileplayer.loadIntoPlayer(player, path.ptr) == 0) {
        return error.SoundFileNotFound;
    }
}
pub inline fn play_sound_file_player(player: *pddefs.FilePlayer, number_of_times_to_play: u32) void {
    const play_result = pd.sound.fileplayer.play(player, @as(c_int, @intCast(number_of_times_to_play)));
    toolbox.assert(play_result != 0, "Failed to play file player", .{});
}
pub inline fn new_synth() *pddefs.PDSynth {
    return pd.sound.synth.newSynth().?;
}
pub inline fn free_synth(synth: *pddefs.PDSynth) void {
    pd.sound.synth.freeSynth(synth);
}
pub inline fn play_synth_note(
    synth: *pddefs.PDSynth,
    freq: f32,
    vel: f32,
    len: f32,
    when: u32,
) void {
    pd.sound.synth.playNote(synth, freq, vel, len, when);
}
pub inline fn play_synth_midi_note(
    synth: *pddefs.PDSynth,
    note: pddefs.MIDINote,
    vel: f32,
    len: f32,
    when: u32,
) void {
    pd.sound.synth.playMIDINote(synth, note, vel, len, when);
}
pub inline fn set_synth_waveform(synth: *pddefs.PDSynth, wave: pddefs.SoundWaveform) void {
    pd.sound.synth.setWaveform(synth, wave);
}
