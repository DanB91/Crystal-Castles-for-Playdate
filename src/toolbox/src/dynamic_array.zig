const std = @import("std");
const toolbox = @import("toolbox.zig");

pub const DYNAMIC_ARRAY_INITIAL_CAPACITY = 32;
pub fn DynamicArray(comptime T: type) type {
    return struct {
        ptr: [*]T = undefined,
        len: usize = 0,
        cap: usize = 0,

        pub const Child = T;

        const Self = @This();

        pub inline fn items(self: *const Self) []T {
            return self.ptr[0..self.len];
        }

        pub fn append(self: *Self, value: T, arena: *toolbox.Arena) void {
            if (self.cap <= self.len) {
                self.expand(@max(
                    self.cap * 2,
                    DYNAMIC_ARRAY_INITIAL_CAPACITY,
                ), arena);
            }
            self.ptr[self.len] = value;
            self.len += 1;
        }
        pub fn expand(self: *Self, new_capacity: usize, arena: *toolbox.Arena) void {
            if (self.cap >= new_capacity) {
                return;
            }

            //TODO: optimize if dynamic array was last allocation on arena
            // {
            //     const ptr_to_test = arena.data[arena.pos - current_cap * @sizeOf(u8)..].ptr;
            //     if (ptr_to_test == da.ptr) {}
            // }
            const new_buffer = arena.push_slice(T, new_capacity);
            @memcpy(new_buffer[0..self.len], self.ptr[0..self.len]);
            self.cap = new_capacity;
            self.ptr = new_buffer.ptr;
        }

        pub fn clone(self: *Self, arena: *toolbox.Arena) Self {
            const result = Self{};
            if (self.cap == 0) {
                return result;
            }
            result.expand(self.cap, arena);
            const src = self.items();
            @memcpy(result.ptr[0..src.len], src);
            result.len = src.len;

            return result;
        }

        pub inline fn clear(self: *Self) void {
            self.len = 0;
        }

        pub const sort = switch (@typeInfo(T)) {
            .Int, .Float => sort_number,
            .Struct => sort_struct,
            else => @compileError("Unsupported type " ++ @typeName(T) ++ " for DynamicArray"),
        };

        pub const sort_reverse = switch (@typeInfo(T)) {
            .Int, .Float => sort_number_reverse,
            .Struct => sort_struct_reverse,
            else => @compileError("Unsupported type " ++ @typeName(T) ++ " for DynamicArray"),
        };

        fn sort_number(self: *Self) void {
            std.sort.block(T, self.items(), self, struct {
                fn less_than(context: *Self, a: T, b: T) bool {
                    _ = context;
                    return a < b;
                }
            }.less_than);
        }

        fn sort_struct(self: *Self, comptime field_name: []const u8) void {
            std.sort.block(T, self.items(), self, struct {
                fn less_than(context: *Self, a: T, b: T) bool {
                    _ = context;
                    return @field(a, field_name) < @field(b, field_name);
                }
            }.less_than);
        }

        fn sort_number_reverse(self: *Self) void {
            std.sort.block(T, self.items(), self, struct {
                fn less_than(context: *Self, a: T, b: T) bool {
                    _ = context;
                    return a > b;
                }
            }.less_than);
        }

        fn sort_struct_reverse(self: *Self, comptime field_name: []const u8) void {
            std.sort.block(T, self.items(), self, struct {
                fn less_than(context: *Self, a: T, b: T) bool {
                    _ = context;
                    return @field(a, field_name) > @field(b, field_name);
                }
            }.less_than);
        }
    };
}
