pub const fiber = @import("fiber.zig");
pub const profiler = @import("profiler.zig");

const print_mod = @import("print.zig");
pub const print = print_mod.print;
pub const println = print_mod.println;
pub const panic = print_mod.panic;
pub const tprint = print_mod.tprint;
pub const printerr = print_mod.printerr;
pub const println_str8 = print_mod.println_str8;

const assert_mod = @import("assert.zig");
pub const assert = assert_mod.assert;
pub const asserteq = assert_mod.asserteq;
pub const static_assert = assert_mod.static_assert;
pub const expect = assert_mod.expect;
pub const expecteq = assert_mod.expecteq;

const type_utils = @import("type_utils.zig");
pub const is_iterable = type_utils.is_iterable;
pub const is_single_pointer = type_utils.is_single_pointer;
pub const is_string_type = type_utils.is_string_type;
pub const ChildType = type_utils.ChildType;
pub const to_const_bytes = type_utils.to_const_bytes;
pub const format_struct_default = type_utils.format_struct_default;
pub const format_struct_number = type_utils.format_struct_number;

const time = @import("time.zig");
pub const Duration = time.Duration;
pub const now = time.now;
pub const MAX_DURATION = time.MAX_DURATION;

const memory = @import("memory.zig");
pub const Arena = memory.Arena;
pub const PoolAllocator = memory.PoolAllocator;
pub const get_scratch_arena = memory.get_scratch_arena;
pub const reset_scratch_arena = memory.reset_scratch_arena;
pub const z = memory.z;
pub const PAGE_SIZE = memory.PAGE_SIZE;
pub const os_allocate_memory = memory.os_allocate_memory;
pub const os_free_memory = memory.os_free_memory;

const byte_math = @import("byte_math.zig");
pub const mb = byte_math.mb;
pub const kb = byte_math.kb;
pub const gb = byte_math.gb;
pub const next_power_of_2 = byte_math.next_power_of_2;
pub const is_power_of_2 = byte_math.is_power_of_2;
pub const align_up = byte_math.align_up;
pub const is_aligned_to = byte_math.is_aligned_to;
pub const clamp = byte_math.clamp;

const linked_list = @import("linked_list.zig");
pub const RandomRemovalLinkedList = linked_list.RandomRemovalLinkedList;

const linked_list_pool = @import("linked_list_pool.zig");
pub const LinkedListPool = linked_list_pool.LinkedListPool;

const hash_map = @import("hash_map.zig");
pub const HashMap = hash_map.HashMap;
pub const INITIAL_HASH_MAP_CAPACITY = hash_map.INITIAL_HASH_MAP_CAPACITY;

const string = @import("string.zig");
pub const String8 = string.String8;
pub const StringBuilder = string.StringBuilder;
pub const str8 = string.str8;
pub const str8fmt = string.str8fmt;
pub const str8fmtbuf = string.str8fmtbuf;
pub const str8lit = string.str8lit;
pub const Rune = string.Rune;

const stack = @import("stack.zig");
pub const FixedStack = stack.FixedStack;

const fixed_list = @import("fixed_list.zig");

const ring_queue = @import("ring_queue.zig");
pub const make_ring_queue = ring_queue.make_ring_queue;
pub const make_concurrent_ring_queue = ring_queue.make_concurrent_ring_queue;
pub const make_not_magic_ring_queue = ring_queue.make_not_magic_ring_queue;
pub const make_magic_ring_queue = ring_queue.make_magic_ring_queue;
pub const RingQueue = ring_queue.RingQueue;
pub const ConcurrentRingQueue = ring_queue.ConcurrentRingQueue;

const random = @import("random.zig");
pub const init_random = random.init_random;
pub const randomf_range = random.randomf_range;
pub const random32 = random.random32;
pub const RandomState = random.RandomState;

const dynamic_array = @import("dynamic_array.zig");
pub const DynamicArray = dynamic_array.DynamicArray;
pub const make_dynamic_array = dynamic_array.make_dynamic_array;
pub const DYNAMIC_ARRAY_INITIAL_CAPACITY = dynamic_array.DYNAMIC_ARRAY_INITIAL_CAPACITY;

const os_utils = @import("os_utils.zig");
const atomic = @import("atomic.zig");
const bit_flags = @import("bit_flags.zig");
const panic_mod = @import("panic.zig");
pub const panic_handler = panic_mod.panic_handler;

const builtin = @import("builtin");
const build_flags = @import("build_flags");
const root = @import("root");
const std = @import("std");

pub const Platform = enum {
    MacOS,
    Linux,
    Windows,
    Playdate,
    BoksOS,
    Wozmon64,
    Emscripten,
    UEFI,
};

pub const Hardware = enum {
    AMD64,
    ARM64,
    WASM32,
    Playdate,
};

pub const THIS_PLATFORM: Platform = if (@hasDecl(root, "THIS_PLATFORM"))
    root.THIS_PLATFORM
else switch (builtin.os.tag) {
    .macos => .MacOS,
    .linux => .Linux,
    .windows => .Windows,
    .uefi => .UEFI,
    .emscripten => .Emscripten,
    else => @compileError("Platform not yet supported"),
};

pub const THIS_HARDWARE: Hardware = switch (builtin.cpu.arch) {
    .x86_64 => .AMD64,
    .aarch64 => .ARM64,
    .wasm32 => .WASM32,
    .thumb => if (THIS_PLATFORM == .Playdate)
        .Playdate
    else
        @compileError("Hardware not yet supported"),
    else => @compileError("Hardware not yet supported"),
};

pub const IS_DEBUG = builtin.mode == .Debug;

////BoksOS runtime functions
pub var boksos_kernel_heap: *std.mem.Allocator = undefined;
pub fn init_boksos_runtime(kernel_heap: *std.mem.Allocator) void {
    boksos_kernel_heap = kernel_heap;
}

////Playdate runtime functions
pub var playdate_realloc: *const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque = undefined;
pub var playdate_log_to_console: *const fn ([*c]const u8, ...) callconv(.c) void = undefined;
pub var playdate_error: *const fn ([*c]const u8, ...) callconv(.c) void = undefined;
pub var playdate_get_seconds: *const fn () callconv(.c) f32 = undefined;
pub var playdate_get_milliseconds: *const fn () callconv(.c) u32 = undefined;

pub fn init_playdate_runtime(
    _playdate_realloc: *const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque,
    _playdate_log_to_console: *const fn ([*c]const u8, ...) callconv(.c) void,
    _playdate_error: *const fn ([*c]const u8, ...) callconv(.c) void,
    _playdate_get_seconds: *const fn () callconv(.c) f32,
    _playdate_get_milliseconds: *const fn () callconv(.c) u32,
) void {
    if (comptime THIS_PLATFORM != .Playdate) {
        @compileError("Only call this for the Playdate!");
    }
    playdate_realloc = _playdate_realloc;
    playdate_log_to_console = _playdate_log_to_console;
    playdate_error = _playdate_error;
    playdate_get_seconds = _playdate_get_seconds;
    playdate_get_milliseconds = _playdate_get_milliseconds;
}

//C bridge functions
export fn c_assert(cond: bool) void {
    if (!cond) {
        unreachable;
    }
}
